const mangayomiSources = [
  {
    "name": "Autoembed",
    "lang": "all",
    "baseUrl": "https://watch.autoembed.cc",
    "apiUrl": "https://tom.autoembed.cc",
    "iconUrl":
      "https://www.google.com/s2/favicons?sz=64&domain=https://autoembed.cc/",
    "typeSource": "multi",
    "isManga": false,
    "itemType": 1,
    "version": "1.2.7",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/all/autoembed.js"
  }
];

class DefaultExtension extends MProvider {
  decodeBase64 = function (f) {
    var g = {},
      b = 65,
      d = 0,
      a,
      c = 0,
      h,
      e = "",
      k = String.fromCharCode,
      l = f.length;
    for (a = ""; 91 > b; ) a += k(b++);
    a += a.toLowerCase() + "0123456789+/";
    for (b = 0; 64 > b; b++) g[a.charAt(b)] = b;
    for (a = 0; a < l; a++)
      for (b = g[f.charAt(a)], d = (d << 6) + b, c += 6; 8 <= c; )
        ((h = (d >>> (c -= 8)) & 255) || a < l - 2) && (e += k(h));
    return e;
  };
  getHeaders(url) {
    return {
      Referer: url,
      Origin: url,
    };
  }

  getPreference(key) {
    const preferences = new SharedPreferences();
    return preferences.get(key);
  }

  async tmdbRequest(slug) {
    var api = `https://94c8cb9f702d-tmdb-addon.baby-beamup.club/${slug}`;
    var response = await new Client().get(api);
    var body = JSON.parse(response.body);
    return body;
  }

  async getSearchItems(body) {
    var items = [];
    var results = body.metas;
    for (let i in results) {
      var result = results[i];
      var id = result.id;
      var media_type = result.type;
      items.push({
        name: result.name,
        imageUrl: result.poster,
        link: `${media_type}||${id}`,
        description: result.description,
        genre: result.genre,
      });
    }
    return items;
  }
  async getSearchInfo(slug) {
    var body = await this.tmdbRequest(`catalog/movie/${slug}`);
    var popMovie = await this.getSearchItems(body);

    body = await this.tmdbRequest(`catalog/series/${slug}`);
    var popSeries = await this.getSearchItems(body);

    var fullList = [];

    var priority = this.getPreference("pref_content_priority");
    if (priority === "series") {
      fullList = [...popSeries, ...popMovie];
    } else {
      fullList = [...popMovie, ...popSeries];
    }
    var hasNextPage = slug.indexOf("search=") > -1 ? false : true;
    return {
      list: fullList,
      hasNextPage,
    };
  }

  async getPopular(page) {
    var skip = (page - 1) * 20;
    return await this.getSearchInfo(`tmdb.popular/skip=${skip}.json`);
  }
  get supportsLatest() {
    throw new Error("supportsLatest not implemented");
  }
  async getLatestUpdates(page) {
    var trend_window = this.getPreference("pref_latest_time_window");
    var skip = (page - 1) * 20;
    return await this.getSearchInfo(
      `tmdb.trending/genre=${trend_window}&skip=${skip}.json`
    );
  }
  async search(query, page, filters) {
    return await this.getSearchInfo(`tmdb.popular/search=${query}.json`);
  }
  async getDetail(url) {
    var baseUrl = this.source.baseUrl;
    var linkSlug = `${baseUrl}/title/`;

    if (url.includes(linkSlug)) {
      url = url.replace(linkSlug, "");
      var id = url.replace("t", "");
      if (url.includes("t")) {
        url = `series||tmdb:${id}`;
      } else {
        url = `movie||tmdb:${id}`;
      }
    }

    var parts = url.split("||");
    var media_type = parts[0];
    var id = parts[1];
    var body = await this.tmdbRequest(`meta/${media_type}/${id}.json`);
    var result = body.meta;

    var tmdb_id = id.substring(5);
    media_type = media_type == "series" ? "tv" : media_type;

    var dateNow = Date.now().valueOf();
    var release = result.released
      ? new Date(result.released).valueOf()
      : dateNow;
    var chaps = [];

    var item = {
      name: result.name,
      imageUrl: result.poster,
      link: `${linkSlug}${linkCode}`,
      description: result.description,
      genre: result.genre,
    };

    var link = `${media_type}||${tmdb_id}`;

    if (media_type == "tv") {
      var videos = result.videos;
      for (var i in videos) {
        var video = videos[i];
        var seasonNum = video.season;

        if (!seasonNum) continue;

        release = video.released ? new Date(video.released).valueOf() : dateNow;

        if (release < dateNow) {
          var episodeNum = video.episode;
          var name = `S${seasonNum}:E${episodeNum} - ${video.name}`;
          var eplink = `${link}||${seasonNum}||${episodeNum}`;

          chaps.push({
            name: name,
            url: eplink,
            dateUpload: release.toString(),
          });
        }
      }
    } else {
      if (release < dateNow) {
        chaps.push({
          name: "Movie",
          url: link,
          dateUpload: release.toString(),
        });
      }
    }

    item.chapters = chaps;
    chaps.reverse();
    return item;
  }

  // Extracts the streams url for different resolutions from a hls stream.
  async extractStreams(url, lang = "", hdr = {}, host = "") {
    var streams = [
      {
        url: url,
        originalUrl: url,
        quality: `${lang} Auto`,
        headers: hdr,
      },
    ];

    var pref = this.getPreference("autoembed_split_stream_quality");
    if (!pref) return streams;

    const response = await new Client().get(url, hdr);
    const body = response.body;
    const lines = body.split("\n");

    for (let i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("#EXT-X-STREAM-INF:")) {
        var resolution = lines[i].match(/RESOLUTION=(\d+x\d+)/)[1];
        resolution = `${lang} ${resolution}`;
        var m3u8Url = lines[i + 1].trim();
        m3u8Url = m3u8Url.replace("./", `${url}/`);
        if (host.length > 0) {
          m3u8Url = `${host}${m3u8Url}`;
        }
        streams.push({
          url: m3u8Url,
          originalUrl: m3u8Url,
          quality: resolution,
          headers: hdr,
        });
      }
    }
    return streams;
  }

  // For some streams, we can form stream url using a default template.
  async splitStreams(url, lang = "", hdr = {}) {
    var streams = [
      {
        url: url,
        originalUrl: url,
        quality: `${lang} - Auto`,
        headers: hdr,
      },
    ];

    var pref = this.getPreference("autoembed_split_stream_quality");
    if (!pref) return streams;

    var quality = ["360", "480", "720", "1080"];
    for (var q of quality) {
      var link = url;
      if (q != "auto") {
        link = link.replace("index.m3u8", `${q}/index.m3u8`);
        q = `${q}p`;
      }
      streams.push({
        url: link,
        originalUrl: link,
        quality: `${lang} - ${q}`,
        headers: hdr,
      });
    }
    return streams;
  }

  // Sorts streams based on user preference.
  async sortStreams(streams) {
    var sortedStreams = [];

    var copyStreams = streams.slice();
    var pref = this.getPreference("pref_video_resolution");
    for (var i in streams) {
      var stream = streams[i];
      if (stream.quality.indexOf(pref) > -1) {
        sortedStreams.push(stream);
        var index = copyStreams.indexOf(stream);
        if (index > -1) {
          copyStreams.splice(index, 1);
        }
        break;
      }
    }
    return [...sortedStreams, ...copyStreams];
  }

  // Gets subtitles based on TMDB id.
  async getSubtitleList(id, s, e) {
    var subPref = parseInt(
      this.getPreference("autoembed_pref_subtitle_source")
    );

    var api = `https://sub.wyzie.ru/search?id=${id}`;
    var hdr = {};

    if (subPref === 2) {
      api = `https://sources.hexa.watch/subs/${id}`;
      hdr = { "Origin": "https://api.hexa.watch" };
      if (s != "0") api = `${api}/${s}/${e}`;
    } else {
      if (s != "0") api = `${api}&season=${s}&episode=${e}`;
    }
    var response = await new Client().get(api, hdr);
    var body = JSON.parse(response.body);

    var subs = [];
    for (var sub of body) {
      subs.push({
        file: sub.url,
        label: sub.display,
      });
    }

    return subs;
  }

  // For anime episode video list
  async getVideoList(url) {
    var streamAPI = parseInt(this.getPreference("autoembed_stream_source_3"));
    var nativeSubs = this.getPreference("autoembed_pref_navtive_subtitle");

    var parts = url.split("||");
    var media_type = parts[0];
    var id = parts[1];

    var s = "0";
    var e = "0";
    if (media_type == "tv") {
      s = parts[2];
      e = parts[3];
    }

    var tmdb = id;
    var streams = [];
    var subtitles = [];
    switch (streamAPI) {
      case 2: {
        if (media_type == "tv") {
          id = `${id}/${s}/${e}`;
        }
        var api = `https://play2.123embed.net/server/3?path=/${media_type}/${id}`;
        var response = await new Client().get(api);

        if (response.statusCode != 200) {
          throw new Error(
            "play2.123embed.net unavailable\nPlease choose a different server"
          );
        }

        var body = JSON.parse(response.body);
        var link = body.playlist[0].file;
        streams.push({
          url: link,
          originalUrl: link,
          quality: "auto",
          headers: { "Origin": "https://play2.123embed.net" },
        });
        break;
      }
      case 3: {
        if (media_type == "tv") {
          id = `${id}&s=${s}&e=${e}`;
        }
        var api = `https://autoembed.cc/embed/player.php?id=${id}`;

        var response = await new Client().get(api);

        if (response.statusCode != 200) {
          throw new Error(
            "autoembed.cc unavailable\nPlease choose a different server"
          );
        }
        var body = response.body;
        var sKey = '"file": ';
        var eKey = "]});";
        var start = body.indexOf(sKey);
        if (start < 0) {
          throw new Error(
            "autoembed.cc videos unavailable\nPlease choose a different server"
          );
        }
        start += sKey.length;

        var end = body.substring(start).indexOf(eKey) + start - 1;
        var strms = JSON.parse(body.substring(start, end) + "]");
        for (var strm of strms) {
          var link = strm.file;
          var lang = strm.title;
          var streamSplit = await this.splitStreams(link, lang);
          streams = [...streams, ...streamSplit];
        }

        break;
      }
      case 4: {
        if (media_type == "tv") {
          id = `${id}&season=${s}&episode=${e}`;
        }
        var api = `https://flicky.host/player/desi.php?id=${id}`;
        var response = await new Client().get(api, {
          "Referer": "https://flicky.host/",
          "sec-fetch-dest": "iframe",
        });

        if (response.statusCode != 200) {
          throw new Error(
            "flicky.host unavailable\nPlease choose a different server"
          );
        }
        var body = response.body;
        var sKey = "streams = ";
        var eKey = "];";
        var start = body.indexOf(sKey);
        if (start < 0) {
          throw new Error(
            "flicky.host videos unavailable\nPlease choose a different server"
          );
        }
        start += sKey.length;

        var end = body.substring(start).indexOf(eKey) + start + 1;
        var strms = JSON.parse(body.substring(start, end));

        for (var strm of strms) {
          var link = strm.url;
          var lang = strm.language;
          var streamSplit = await this.splitStreams(link, lang);
          streams = [...streams, ...streamSplit];
        }

        break;
      }
      case 5: {
        if (media_type == "tv") {
          id = `${id}/${s}/${e}`;
        }
        var api = `https://vidapi.click/api/video/${media_type}/${id}`;
        var response = await new Client().get(api);

        if (response.statusCode != 200) {
          throw new Error(
            "vidapi.click unavailable\nPlease choose a different server"
          );
        }

        var body = JSON.parse(response.body);
        var link = body.sources[0].file;
        if (nativeSubs) subtitles = body.tracks;
        streams = await this.extractStreams(link);
        break;
      }
      case 6: {
        if (media_type == "tv") {
          id = `${id}/${s}/${e}`;
        }
        var api = `https://sources.hexa.watch/plsdontscrapemeuwu/${id}`;
        var hdr = { "Origin": "https://api.hexa.watch" };
        var response = await new Client().get(api, hdr);

        if (response.statusCode != 200) {
          throw new Error(
            "hexa.watch unavailable\nPlease choose a different server"
          );
        }

        var body = JSON.parse(response.body);
        var strms = body.streams;
        for (var strm of strms) {
          var streamLink = strm.url;
          if (streamLink.length > 0) {
            streams.push({
              url: strm.url,
              originalUrl: strm.url,
              quality: `${strm.label} - Auto`,
              headers: strm.headers,
            });
          }
        }
        break;
      }
      case 7: {
        if (media_type == "tv") {
          id = `${id}/${s}/${e}`;
        }
        var api = `https://vidsrc.su/embed/${media_type}/${id}`;
        var response = await new Client().get(api);

        if (response.statusCode != 200) {
          throw new Error(
            "vidsrc.su unavailable\nPlease choose a different server"
          );
        }
        var body = response.body;
        var sKey = "fixedServers = ";
        var eKey = "];";
        var start = body.indexOf(sKey);
        if (start < 0) {
          throw new Error(
            "vidsrc.su videos unavailable\nPlease choose a different server"
          );
        }
        start += sKey.length;

        var end = body.substring(start).indexOf(eKey) + start + 1;
        var strms = body.substring(start, end);

        // Split the data into lines
        var lines = strms.split("\n");

        // Regex to match URLs in quotes that start with https://
        var regex = /url:\s*'(https:\/\/[^']+)'/;
        var availableStreams = [];

        // Process each line
        lines.forEach((line) => {
          var match = line.match(regex);
          if (match && match[1]) {
            // Extract the label from the line
            var labelMatch = line.match(/label:\s*'([^']+)'/);
            var label = labelMatch ? labelMatch[1] : "Unknown";
            // Add to our results
            availableStreams.push({
              url: match[1],
              label: label,
            });
          }
        });

        for (var stream of availableStreams) {
          var streamSplit = await this.extractStreams(stream.url, stream.label);
          streams = [...streams, ...streamSplit];
        }

        if (nativeSubs) {
          // subtitles
          sKey = "const subtitles = ";
          eKey = "];";
          start = body.indexOf(sKey);
          if (start < 0) {
            break; // no need for native subtitle if not found.
          }
          start += sKey.length;

          end = body.substring(start).indexOf(eKey) + start + 1;
          var natSubs = JSON.parse(body.substring(start, end));
          natSubs.forEach((sub) => {
            subtitles.push({
              file: sub.url,
              label: sub.display,
            });
          });
        }
        break;
      }
      case 8: {
        function reverse(str) {
          return str.split("").reverse().join("");
        }

        if (media_type == "tv") {
          id = `${id}/${s}/${e}`;
        }
        var baseUrl = "https://embed.su";
        var embedUrl = `${baseUrl}/embed/${media_type}/${id}`;
        var response = await new Client().get(
          embedUrl,
          this.getHeaders(baseUrl)
        );

        var body = response.body;
        var sKey = "JSON.parse(atob(`";
        var start = body.indexOf(sKey) + sKey.length;
        var end = body.substring(start).indexOf("`") + start;
        var configHash = body.substring(start, end);

        var config = JSON.parse(this.decodeBase64(configHash));
        var encodedHash = this.decodeBase64(config.hash);
        var decodeHash = reverse(
          encodedHash
            .split(".")
            .map((item) => reverse(item))
            .join("")
        );
        encodedHash = JSON.parse(this.decodeBase64(decodeHash));
        var serverHash = encodedHash[0].hash;

        var api = `${baseUrl}/api/e/${serverHash}`;
        response = await new Client().get(api, this.getHeaders(baseUrl));
        var jsonRes = JSON.parse(response.body);

        streams = await this.extractStreams(
          jsonRes.source,
          "",
          this.getHeaders(baseUrl),
          baseUrl
        );
        if (nativeSubs) subtitles = jsonRes.subtitles;
        break;
      }
      default: {
        if (media_type == "tv") {
          id = `${id}/${s}/${e}`;
        }
        var api = `${this.source.apiUrl}/api/getVideoSource?type=${media_type}&id=${id}`;
        var response = await new Client().get(
          api,
          this.getHeaders(this.source.apiUrl)
        );

        if (response.statusCode != 200) {
          throw new Error(
            "tom.autoembed.cc unavailable\nPlease choose a different server"
          );
        }

        var body = JSON.parse(response.body);
        var link = body.videoSource;
        if (nativeSubs) subtitles = body.subtitles;
        streams = await this.extractStreams(link);
        break;
      }
    }
    if (streams.length < 1) {
      throw new Error(
        "No streams unavailable\nPlease choose a different server"
      );
    }

    var apiSubs = await this.getSubtitleList(tmdb, s, e);
    streams[0].subtitles = [...subtitles, ...apiSubs];

    return await this.sortStreams(streams);
  }

  // For manga chapter pages
  async getPageList() {
    throw new Error("getPageList not implemented");
  }
  getFilterList() {
    throw new Error("getFilterList not implemented");
  }

  getSourcePreferences() {
    return [
      {
        key: "pref_latest_time_window",
        listPreference: {
          title: "Preferred latest trend time window",
          summary: "",
          valueIndex: 0,
          entries: ["Day", "Week"],
          entryValues: ["day", "week"],
        },
      },
      {
        key: "pref_video_resolution",
        listPreference: {
          title: "Preferred video resolution",
          summary: "",
          valueIndex: 0,
          entries: ["Auto", "1080p", "720p", "360p"],
          entryValues: ["auto", "1080", "720", "360"],
        },
      },
      {
        key: "pref_content_priority",
        listPreference: {
          title: "Preferred content priority",
          summary: "Choose which type of content to show first",
          valueIndex: 0,
          entries: ["Movies", "Series"],
          entryValues: ["movies", "series"],
        },
      },
      {
        key: "autoembed_split_stream_quality",
        "switchPreferenceCompat": {
          "title": "Split stream into different quality streams",
          "summary": "Split stream Auto into 360p/720p/1080p",
          "value": true,
        },
      },
      {
        key: "autoembed_stream_source_3",
        listPreference: {
          title: "Preferred stream source",
          summary: "",
          valueIndex: 0,
          entries: [
            "tom.autoembed.cc",
            "123embed.net",
            "autoembed.cc - Indian languages",
            "flicky.host - Indian languages",
            "vidapi.click",
            "hexa.watch",
            "vidsrc.su",
            "embed.su",
          ],
          entryValues: ["1", "2", "3", "4", "5", "6", "7", "8"],
        },
      },
      {
        key: "autoembed_pref_navtive_subtitle",
        "switchPreferenceCompat": {
          "title": "Use native subtitles as well",
          "summary":
            "Use subtitles provided by the source along with subtitle API",
          "value": true,
        },
      },
      {
        key: "autoembed_pref_subtitle_source",
        listPreference: {
          title: "Preferred subtitle source",
          summary: "",
          valueIndex: 0,
          entries: ["sub.wyzie.ru", "hexa.watch"],
          entryValues: ["1", "2"],
        },
      },
    ];
  }
}

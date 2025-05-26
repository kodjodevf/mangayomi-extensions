const mangayomiSources = [
  {
    "name": "AnimeZ",
    "lang": "en",
    "baseUrl": "https://animez.org",
    "apiUrl": "",
    "iconUrl":
      "https://www.google.com/s2/favicons?sz=256&domain=https://animez.org/",
    "typeSource": "multi",
    "itemType": 1,
    "version": "1.0.2",
    "pkgPath": "anime/src/en/animez.js"
  }
];

class DefaultExtension extends MProvider {
  constructor() {
    super();
    this.client = new Client();
  }

  getHeaders(url) {
    return {
      "Referer": this.source.baseUrl,
    };
  }

  getPreference(key) {
    return new SharedPreferences().get(key);
  }

  async request(slug) {
    var url = this.source.baseUrl + slug;
    var res = await this.client.get(url, this.getHeaders());
    return new Document(res.body);
  }
  async page(slug) {
    var body = await this.request(slug);
    var list = [];
    var hasNextPage = false;

    var animes = body.select("li.TPostMv");
    animes.forEach((anime) => {
      var link = anime.selectFirst("a").getHref;
      var name = anime.selectFirst("h2.Title").text;
      var imageUrl =
        this.source.baseUrl + "/" + anime.selectFirst("img").getSrc;

      list.push({ name, link, imageUrl });
    });

    var paginations = body.select(".pagination > li");
    hasNextPage =
      paginations[paginations.length - 1].text == "Last" ? true : false;

    return { list, hasNextPage };
  }

  sortByPref(key) {
    var sort = parseInt(this.getPreference(key));
    var sortBy = "hot";
    switch (sort) {
      case 1: {
        sortBy = "lastest-chap";
        break;
      }
      case 2: {
        sortBy = "hot";
        break;
      }
      case 3: {
        sortBy = "lastest-manga";
        break;
      }
      case 4: {
        sortBy = "top-manga";
        break;
      }
      case 5: {
        sortBy = "top-month";
        break;
      }
      case 6: {
        sortBy = "top-week";
        break;
      }
      case 7: {
        sortBy = "top-day";
        break;
      }
      case 8: {
        sortBy = "follow";
        break;
      }
      case 9: {
        sortBy = "comment";
        break;
      }
      case 10: {
        sortBy = "num-chap";
        break;
      }
    }
    return sortBy;
  }

  async getPopular(page) {
    var sortBy = this.sortByPref("animez_pref_popular_section");
    var slug = `/?act=search&f[status]=all&f[sortby]=${sortBy}&&pageNum=${page}`;
    return await this.page(slug);
  }
  get supportsLatest() {
    throw new Error("supportsLatest not implemented");
  }
  async getLatestUpdates(page) {
    var sortBy = this.sortByPref("animez_pref_latest_section");
    var slug = `/?act=search&f[status]=all&f[sortby]=${sortBy}&&pageNum=${page}`;
    return await this.page(slug);
  }
  async search(query, page, filters) {
    var slug = `/?act=search&f[status]=all&f[keyword]=${query}&&pageNum=${page}`;
    return await this.page(slug);
  }
  async getDetail(url) {
    var baseUrl = this.source.baseUrl;
    if (url.includes(baseUrl)) url = url.replace(baseUrl, "");
    var link = +url;
    var body = await this.request(url);
    var name = body.selectFirst("#title-detail-manga").text;
    var animeId = body.selectFirst("#title-detail-manga").attr("data-manga");
    var genre = [];
    body
      .select("li.AAIco-adjust")[3]
      .select("a")
      .forEach((g) => genre.push(g.text));
    var description = body.selectFirst("#summary_shortened").text;

    var chapters = [];
    var chapLen = 0;
    var pageNum = 1;
    var hasNextPage = true;
    while (hasNextPage) {
      var pageSlug = `?act=ajax&code=load_list_chapter&manga_id=${animeId}&page_num=${pageNum}&chap_id=0&keyword=`;
      var pageBody = await this.request(pageSlug);
      var parsedBody = JSON.parse(pageBody.html);
      var nav = parsedBody.nav;
      if (nav == null) {
        // if "nav" doesnt exists there is no next page
        hasNextPage = false;
      } else {
        var navLi = new Document(nav).select(".page-link.next").length;
        if (navLi > 0) {
          // if "nav" exists and has li.next then there is next page
          pageNum++;
        } else {
          // if "nav" exists and doesn't have li.next then there is no next page
          hasNextPage = false;
        }
      }

      var list_chap = new Document(parsedBody.list_chap).select(
        "li.wp-manga-chapter"
      );

      list_chap.forEach((chapter) => {
        var a = chapter.selectFirst("a");
        var title = a.text;
        var epLink = a.getHref;
        var scanlator = "Sub";
        if (title.indexOf("Dub") > 0) {
          title = title.replace("-Dub", "");
          scanlator = "Dub";
        }
        title = title.indexOf("Movie") > -1 ? title : `Episode ${title}`;
        var epData = {
          name: title,
          url: epLink,
          scanlator,
        };
        if (chapLen > 0) {
          var pos = chapLen - 1;
          var lastEntry = chapters[pos];
          if (lastEntry.name == epData.name) {
            // if last entries name is same then append url and scanlator to last entry
            chapters.pop(); // remove the last entry
            epData.url = `${epData.url}||${lastEntry.url}`;
            epData.scanlator = `${lastEntry.scanlator}, ${epData.scanlator}`;
            chapLen = pos; // since the last entry is removed the chapLen will decrease
          }
        }

        chapters.push(epData);
        chapLen++;
      });
    }

    return {
      link,
      description,
      chapters,
      genre,
    };
  }

  // Sorts streams based on user preference.
  sortStreams(streams) {
    var sortedStreams = [];

    var copyStreams = streams.slice();
    var pref = this.getPreference("animez_pref_stream_audio");
    for (var stream of streams) {
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

  // For anime episode video list
  async getVideoList(url) {
    var linkSlugs = url.split("||");
    var streams = [];
    for (var slug of linkSlugs) {
      var body = await this.request(slug);
      var iframeSrc = body.selectFirst("iframe").getSrc;
      var streamLink = iframeSrc.replace("/embed/", "/anime/");
      var audio = slug.indexOf("dub-") > -1 ? "Dub" : "Sub";

      streams.push({
        url: streamLink,
        originalUrl: streamLink,
        quality: audio,
      });
    }

    return sortStreams(streams);
  }

  getSourcePreferences() {
    return [
      {
        key: "animez_pref_popular_section",
        listPreference: {
          title: "Preferred popular content",
          summary: "",
          valueIndex: 1,
          entries: [
            "Latest update",
            "Hot",
            "New releases",
            "Top all",
            "Top month",
            "Top week",
            "Top day",
            "Top follow",
            "Top comments",
            "Number of episodes",
          ],
          entryValues: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"],
        },
      },
      {
        key: "animez_pref_latest_section",
        listPreference: {
          title: "Preferred latest content",
          summary: "",
          valueIndex: 0,
          entries: [
            "Latest update",
            "Hot",
            "New releases",
            "Top all",
            "Top month",
            "Top week",
            "Top day",
            "Top follow",
            "Top comments",
            "Number of episodes",
          ],
          entryValues: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"],
        },
      },
      {
        key: "animez_pref_stream_audio",
        listPreference: {
          title: "Preferred stream audio",
          summary: "",
          valueIndex: 0,
          entries: ["Sub", "Dub"],
          entryValues: ["Sub", "Dub"],
        },
      },
    ];
  }
}

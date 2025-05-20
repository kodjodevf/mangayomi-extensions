const mangayomiSources = [
  {
    "name": "Soaper",
    "id": 764093578,
    "lang": "all",
    "baseUrl": "https://soaper.cc",
    "apiUrl": "",
    "iconUrl":
      "https://www.google.com/s2/favicons?sz=128&domain=https://soaper.cc/",
    "typeSource": "multi",
    "version": "1.0.5",
    "itemType": 1,
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/all/soaper.js"
  }
];

// Authors: - Swakshan, kodjodevf

class DefaultExtension extends MProvider {
  getHeaders(url) {
    return {
      Referer: url,
      Origin: url,
    };
  }

  getPreference(key) {
    return new SharedPreferences().get(key);
  }

  getBasueUrl() {
    return this.getPreference("soaper_override_base_url");
  }

  async request(slug) {
    const baseUrl = this.getBasueUrl();
    var url = `${baseUrl}/${slug}`;
    var res = await new Client().get(url, this.getHeaders(baseUrl));
    var doc = new Document(res.body);
    return doc;
  }

  async requestJSON(slug, data) {
    const baseUrl = this.getBasueUrl();
    var url = `${baseUrl}/${slug}`;
    var res = await new Client().post(url, this.getHeaders(baseUrl), data);
    return JSON.parse(res.body);
  }

  async formatList(slug, page) {
    const baseUrl = this.getPreference("soaper_override_base_url");
    slug = parseInt(page) > 1 ? `${slug}?page=${page}` : slug;
    var doc = await this.request(slug);
    var list = [];
    var movies = doc.select(".thumbnail.text-center");

    for (var movie of movies) {
      var linkSection = movie.selectFirst("div.img-group > a");
      var link = linkSection.getHref.substring(1);
      var poster = linkSection.selectFirst("img").getSrc;
      var imageUrl = `${baseUrl}${poster}`;
      var name = movie.selectFirst("h5").selectFirst("a").text;

      list.push({ name, imageUrl, link });
    }

    var hasNextPage = false;
    if (slug.indexOf("search.html?") == -1) {
      var pagination = doc.select("ul.pagination > li");
      var last_page_num = parseInt(pagination[pagination.length - 2].text);
      hasNextPage = page < last_page_num ? true : false;
    }
    return { list, hasNextPage };
  }

  async filterList(year = "all", genre = "all", sort = "new", page = 1) {
    year = year == "all" ? "" : `/year/${year}`;
    genre = genre == "all" ? "" : `/cat/${genre}`;
    sort = sort == "new" ? "" : `/sort/${sort}`;

    var slug = `${sort}${year}${genre}`;
    var movieList = await this.formatList(`movielist${slug}`, page);
    var seriesList = await this.formatList(`tvlist${slug}`, page);

    var list = [];
    var priority = this.getPreference("soaper_content_priority");
    if (priority === "series") {
      list = [...seriesList.list, ...movieList.list];
    } else {
      list = [...movieList.list, ...seriesList.list];
    }

    var hasNextPage = seriesList.hasNextPage || movieList.hasNextPage;

    return { list, hasNextPage };
  }

  async getPopular(page) {
    return await this.filterList("all", "all", "hot", page);
  }
  get supportsLatest() {
    throw new Error("supportsLatest not implemented");
  }
  async getLatestUpdates(page) {
    return await this.filterList("all", "all", "new", page);
  }

  async search(query, page, filters) {
    var seriesList = [];
    var movieList = [];
    var list = [];

    var res = await this.formatList(`search.html?keyword=${query}`, 1);
    var movies = res["list"];

    for (var movie of movies) {
      var link = movie.link;
      if (link.indexOf("tv_") != -1) {
        seriesList.push(movie);
      } else {
        movieList.push(movie);
      }
    }

    var priority = this.getPreference("soaper_content_priority");
    if (priority === "series") {
      list = [...seriesList, ...movieList];
    } else {
      list = [...movieList, ...seriesList];
    }

    return { list, hasNextPage: false };
  }

  async getDetail(url) {
    const baseUrl = this.getPreference("soaper_override_base_url");
    var slug = url.replace(`${baseUrl}/`,'')
    var doc = await this.request(slug);
    var name = doc
      .selectFirst(".col-sm-12.col-lg-12.text-center")
      .selectFirst("h4")
      .text.trim();
    var poster = doc
      .selectFirst(".thumbnail.text-center")
      .selectFirst("img").getSrc;
    var imageUrl = `${baseUrl}${poster}`;

    var description = doc.selectFirst("p#wrap").text.trim();
    var link = `${baseUrl}/${slug}`;

    var chapters = [];
    if (slug.indexOf("tv_") != -1) {
      var seasonList = doc.select(".alert.alert-info-ex.col-sm-12");
      var seasonCount = seasonList.length;
      for (var season of seasonList) {
        var eps = season.select(".col-sm-12.col-md-6.col-lg-4.myp1");
        for (var ep of eps) {
          var epLinkSection = ep.selectFirst("a");
          var epLink = epLinkSection.getHref.substring(1);
          var epName = epLinkSection.text;

          chapters.push({
            name: `S${seasonCount}E${epName}`,
            url: epLink,
          });
        }
        seasonCount--;
      }
    } else {
      chapters.push({
        name: "Movie",
        url: slug,
      });
    }

    return { name, imageUrl, description, link, chapters };
  }
  // For anime episode video list
  async getVideoList(url) {
    var body = await this.request(url);
    var baseUrl = this.getBasueUrl();
    var streams = [];

    // Traditional servers
    var eId = body.selectFirst("#hId").attr("value");
    var hIsW = body.selectFirst("#hIsW").attr("value");
    var apiType = url[0].toUpperCase();

    var servers = [0, 1];
    for (var serverNum of servers) {
      var serverName = body.selectFirst(`#server_button_${serverNum}`).text;
      if (serverName.length < 1) continue;
      var data = {
        pass: eId,
        param: "",
        extra: "1",
        e2: hIsW,
        server: "" + serverNum,
      };
      var res = await this.requestJSON(
        `home/index/Get${apiType}InfoAjax`,
        data
      );

      var streamUrl = baseUrl + res.val;
      var subs = [];
      var vidSubs = res.subs;
      if (vidSubs != null && vidSubs.length > 0) {
        for (var sub of vidSubs) {
          subs.push({
            file: baseUrl + sub.path,
            label: sub.name,
          });
        }
      }
      streams.push({
        url: streamUrl,
        originalUrl: streamUrl,
        quality: serverName,
        subtitles: subs,
      });
    }

    // Download servers
    var modal_footer = body.select(".modal-footer > a");
    if (modal_footer.length > 0) {
      modal_footer.reverse();
      for (var item of modal_footer) {
        var dSlug = item.getHref;
        var dBody = await this.request(dSlug);

        var res = dBody.selectFirst("#res").attr("value");
        var mb = dBody.selectFirst("#mb").attr("value");
        var streamLink = dBody.selectFirst("#link").attr("value");

        streams.push({
          url: streamLink,
          originalUrl: streamLink,
          quality: `Download Server: ${res} [${mb}]`,
        });
      }
    }
    return streams;
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
        key: "soaper_override_base_url",
        editTextPreference: {
          title: "Override base url",
          summary: "Default: https://soaper.cc",
          value: "https://soaper.cc",
          dialogTitle: "Override base url",
          dialogMessage: "",
        },
      },
      {
        key: "soaper_content_priority",
        listPreference: {
          title: "Preferred content priority",
          summary: "Choose which type of content to show first",
          valueIndex: 0,
          entries: ["Movies", "Series"],
          entryValues: ["movies", "series"],
        },
      },
    ];
  }
}

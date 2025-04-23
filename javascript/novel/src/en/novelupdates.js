const mangayomiSources = [{
  "name": "Novel Updates",
  "lang": "en",
  "baseUrl": "https://www.novelupdates.com",
  "apiUrl": "",
  "iconUrl":
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/en.novelupdates.png",
  "typeSource": "single",
  "itemType": 2,
  "version": "0.0.3",
  "dateFormat": "",
  "dateFormatLocale": "",
  "pkgPath": "novel/src/en/novelupdates.js",
  "isNsfw": false,
  "hasCloudflare": true,
  "notes": "This extension requires you to login to view the chapters!"
}];

class DefaultExtension extends MProvider {
  headers = {
    Referer: this.source.baseUrl,
    Origin: this.source.baseUrl,
    Connection: "keep-alive",
    Accept: "*/*",
    "Accept-Language": "*",
    "Sec-Fetch-Mode": "cors",
    "Accept-Encoding": "gzip, deflate",
    "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
  };

  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  mangaListFromPage(res) {
    const doc = new Document(res.body);
    const mangaElements = doc.select("div.search_main_box_nu");
    const list = [];
    for (const element of mangaElements) {
      const name = element.selectFirst(".search_title > a").text;
      const imageUrl = element.selectFirst("img").getSrc;
      const link = element.selectFirst(".search_title > a").getHref;
      list.push({ name, imageUrl, link });
    }
    const hasNextPage =
      doc.selectFirst("div.digg_pagination > a.next_page").text == " →";
    return { list: list, hasNextPage };
  }

  toStatus(status) {
    if (status.includes("Ongoing")) return 0;
    else if (status.includes("Completed")) return 1;
    else if (status.includes("Hiatus")) return 2;
    else if (status.includes("Dropped")) return 3;
    else return 5;
  }

  async getPopular(page) {
    const res = await new Client().get(
      `${this.source.baseUrl}/series-ranking/?rank=popmonth&pg=${page}`,
      this.headers
    );
    return this.mangaListFromPage(res);
  }

  async getLatestUpdates(page) {
    const res = await new Client().get(
      `${this.source.baseUrl}/series-finder/?sf=1&sh=&sort=sdate&order=desc&pg=${page}`,
      this.headers
    );
    return this.mangaListFromPage(res);
  }

  async search(query, page, filters) {
    let url = `${this.source.baseUrl}/series-finder/?sf=1&sh=${query}&pg=${page}`;

    if (!filters || filters.length == 0) {
      const res = await new Client().get(url, this.headers);
      return this.mangaListFromPage(res);
    }

    if (filters[0].state.filter(f => f.state == true).length > 0) {
      const values = filters[0].state.filter(f => f.state == true).map(f => f.value).join(",");
      url += `&nt=${values}`;
    }

    if (filters[1].state.filter(f => f.state == true).length > 0) {
      const values = filters[1].state.filter(f => f.state == true).map(f => f.value).join(",");
      url += `&org=${values}`;
    }

    if (filters[2].state.filter(f => f.state == 1 || f.state == 2).length > 0) {
      const including = filters[2].state.filter(f => f.state == 1).map(f => f.value).join(",");
      const excluding = filters[2].state.filter(f => f.state == 2).map(f => f.value).join(",");
      if (including.length > 0) url += `&gi=${including}`;
      if (excluding.length > 0) url += `&ge=${excluding}`;
    }

    if (filters[3].state.filter(f => f.state == true).length > 0) {
      const values = filters[3].state.filter(f => f.state == true).map(f => f.value).join(",");
      url += `&ss=${values}`;
    }

    url += `&sort=${filters[4].values[filters[4].state].value}`;
    url += `&order=${filters[5].values[filters[5].state].value}`;

    const res = await new Client().get(url, this.headers);
    return this.mangaListFromPage(res);
  }

  async getDetail(url) {
    const client = new Client();
    const res = await client.get(url, this.headers);
    const doc = new Document(res.body);
    const imageUrl = doc.selectFirst(".wpb_wrapper img")?.getSrc;
    const type = doc.selectFirst("#showtype")?.text.trim();
    const description =
      doc.selectFirst("#editdescription")?.text.trim() + `\n\nType: ${type}`;
    const author = doc
      .select("#authtag")
      .map((el) => el.text.trim())
      .join(", ");
    const artist = doc
      .select("#artiststag")
      .map((el) => el.text.trim())
      .join(", ");
    const status = this.toStatus(doc.selectFirst("#editstatus")?.text.trim());
    const genre = doc.select("#seriesgenre > a").map((el) => el.text.trim());

    const novelId = doc.selectFirst("input#mypostid")?.attr("value");

    const link = `https://www.novelupdates.com/wp-admin/admin-ajax.php`;
    const headers = {
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      ...this.headers,
    };

    const chapters = [];
    const chapterRes = await client.post(link, headers, {
      action: "nd_getchapters",
      mygrr: "0",
      mypostid: novelId,
    });
    const chapterDoc = new Document(chapterRes.body);

    const nameReplacements = {
      v: "Volume ",
      c: " Chapter ",
      part: "Part ",
      ss: "SS",
    };

    const chapterElements = chapterDoc.select("li.sp_li_chp");
    for (const el of chapterElements) {
      let chapterName = el.selectFirst("span").text;
      for (const name in nameReplacements) {
        chapterName = chapterName.replace(name, nameReplacements[name]);
      }
      chapterName = chapterName.replace(/\b\w/g, (l) => l.toUpperCase()).trim();
      const chapterUrl = `https:${el.select("a")[1].getHref}`;
      const dateUpload = String(Date.now());
      chapters.push({
        name: chapterName,
        url: chapterUrl,
        dateUpload: dateUpload,
        scanlator: null,
      });
    }

    chapters.reverse();

    return {
      imageUrl,
      description,
      genre,
      author,
      artist,
      status,
      chapters,
    };
  }

  async getHtmlContent(url) {
    const client = await new Client();
    const res = await client.get(url, {
      Priority: "u=0, i",
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
    });
    return await this.cleanHtmlContent(res.body);
  }

  async cleanHtmlContent(html) {
    const client = await new Client();
    const doc = new Document(html);
    const domain = html;

    if (domain.includes("anotivereads")) {
      const title =
        doc.selectFirst("#comic-nav-name")?.text.trim() ||
        "";
      const content = doc.selectFirst("#spliced-comic")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("asuratls")) {
      const title =
        doc.selectFirst(".post-body > div > b")?.text.trim() ||
        "";
      const content = doc.selectFirst(".post-body")?.innerHtml?.replace(title, "");
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("daoist")) {
      const title =
        doc.selectFirst(".chapter__title")?.text.trim() ||
        "";
      const content = doc.selectFirst(".chapter__content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("darkstartranslations")) {
      const title =
        doc.selectFirst("ol.breadcrumb > li")?.text.trim() ||
        "";
      const content = doc.selectFirst(".text-left")?.innerHtml?.replace("<br>", "<br><br>");
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("fictionread")) {
      const title =
        doc.selectFirst(".title-image > span")?.text.trim() ||
        "";
      const content = doc.selectFirst(".content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("helscans")) {
      const title =
        doc.selectFirst(".entry-title-main")?.text.trim() ||
        "";
      const content = doc.selectFirst("#readerarea.rdminimal")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("hiraethtranslation")) {
      const title =
        doc.selectFirst("li.active")?.text.trim() ||
        "";
      const content = doc.selectFirst(".text-left")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("hostednovel")) {
      const title =
        doc.selectFirst("#chapter-title")?.text.trim() ||
        "";
      const content = doc.selectFirst("#chapter-content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("inoveltranslation")) {
      const content = doc.selectFirst(".styles_content__JHK8G")?.innerHtml;
      return `${content}`;
    }

    if (domain.includes("isotls")) {
      const title =
        doc.selectFirst("head > title")?.text.trim() ||
        "";
      const content = doc.selectFirst("main > article")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("mirilu")) {
      const title =
        doc.selectFirst(".entry-content > p > strong")?.text.trim() ||
        "";
      const content = doc.selectFirst(".entry-content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("novelplex")) {
      const title =
        doc.selectFirst(".halChap--jud")?.text.trim() ||
        "";
      const content = doc.selectFirst(".halChap--kontenInner")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("novelworldtranslations")) {
      const title =
        doc.selectFirst(".entry-title")?.text.trim() ||
        "";
      const content = doc.selectFirst(".entry-content")?.innerHtml?.replace(/&nbsp;/g, '')?.replace(/\n/g, '<br>');
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("readingpia")) {
      const content = doc.selectFirst(".chapter-body")?.innerHtml;
      return `${content}`;
    }

    if (domain.includes("sacredtexttranslations")) {
      const title =
        doc.selectFirst(".entry-title")?.text.trim() ||
        "";
      const content = doc.selectFirst(".entry-content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("scribblehub")) {
      const title =
        doc.selectFirst(".chapter-title")?.text.trim() ||
        "";
      const content = doc.selectFirst(".chp_raw")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("tinytranslation")) {
      const title =
        doc.selectFirst(".title-content")?.text.trim() ||
        "";
      const content = doc.selectFirst(".content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("tumblr")) {
      const content = doc.selectFirst(".post")?.innerHtml;
      return `${content}`;
    }

    if (domain.includes("wattpad")) {
      const title =
        doc.selectFirst(".h2")?.text.trim() ||
        "";
      const content = doc.selectFirst(".part-content > pre")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("webnovel")) {
      const title =
        doc.selectFirst(".cha-tit > .pr > .dib")?.text.trim() ||
        "";
      const content = doc.selectFirst(".cha-words")?.innerHtml || doc.selectFirst("._content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("wetriedtls")) {
      const content = doc.selectFirst("script:contains(\"p dir=\")")?.innerHtml || doc.selectFirst("script:contains(\"u003c\")")?.innerHtml;
      if (content) {
        const jsonString_wetried = content.slice(
          content.indexOf('.push(') + '.push('.length,
          content.lastIndexOf(')'),
        );
        return `${JSON.parse(jsonString_wetried)[1]}`;
      }
      return "<p>Failed to parse JSON content!</p>";
    }

    if (domain.includes("wuxiaworld")) {
      const title =
        doc.selectFirst("h4 > span")?.text.trim() ||
        "";
      const content = doc.selectFirst(".chapter-content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("zetrotranslation")) {
      const title =
        doc.selectFirst(".text-left h2")?.text.trim() ||
        doc.selectFirst(".active")?.text.trim() ||
        "";
      const content = doc.selectFirst(".text-left")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("webnovel")) {
      const title =
        doc.selectFirst("#page > .chapter_content > .cha-tit > div > div")?.text.trim() ||
        "";
      const content = doc.selectFirst("#page > .chapter_content > .cha-content > .cha-words")?.innerHtml.replaceAll(/<i\s*.*?>.*?<\/i>/gm, "");
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    if (domain.includes("re-library")) {
      const redirectUrl = doc.selectFirst(".entry-content > div > div > p > a").getHref;
      const redirectRes = await client.get(redirectUrl, {
        Priority: "u=0, i",
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
      });
      const redirectDoc = new Document(redirectRes.body);
      const title =
        redirectDoc.selectFirst(".entry-header > .entry-title")?.text.trim() ||
        "";
      const content = redirectDoc.selectFirst(".entry-content")?.innerHtml.replaceAll(/<i\s*.*?>.*?<\/i>/gm, "");
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    const blogspotElements = [
      doc.selectFirst("meta[name=\"google-adsense-platform-domain\"]").attr("content"),
      doc.selectFirst("meta[name=\"generator\"]").attr("content"),
    ];
    const isBlogspot = blogspotElements.some(e => {
      return e?.toLowerCase().includes("blogspot") || e?.toLowerCase().includes("blogger")
    });

    if (isBlogspot) {
      const title =
        doc.selectFirst("h3.post-title")?.text.trim() ||
        doc.selectFirst("h3.entry-title")?.text.trim() ||
        "";
      const content =
        doc.selectFirst("div.post-body")?.innerHtml ||
        doc.selectFirst("div.entry-content")?.innerHtml ||
        doc.selectFirst("div.content-post")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    const wordpressElements = [
      doc.selectFirst("#dcl_comments-js-extra")?.innerHtml,
      doc.selectFirst("meta[name=\"generator\"]")?.attr("content"),
      doc.selectFirst(".powered-by")?.text,
      doc.selectFirst("footer")?.text,
    ];
    let isWordpress = wordpressElements.some(e => {
      return e?.toLowerCase().includes("wordpress") || e?.toLowerCase().includes("site kit by google")
    });

    let title =
      doc.selectFirst(".entry-title")?.text.trim() ||
      doc.selectFirst(".entry-title-main")?.text.trim() ||
      doc.selectFirst(".chapter__title")?.text.trim() ||
      doc.selectFirst(".sp-title")?.text.trim() ||
      doc.selectFirst(".title-content")?.text.trim() ||
      doc.selectFirst(".wp-block-post-title")?.text.trim() ||
      doc.selectFirst(".title_story")?.text.trim() ||
      doc.selectFirst(".active")?.text.trim() ||
      doc.selectFirst("head title")?.text.trim() ||
      doc.selectFirst("h1.leading-none ~ h2")?.text.trim() ||
      "";
    const subtitle =
      doc.selectFirst(".cat-series")?.text.trim() ||
      doc.selectFirst("h1.leading-none ~ span")?.text.trim() ||
      "";
    if (subtitle && subtitle != "") {
      title = subtitle;
    }
    const content =
      doc.selectFirst(".rdminimal")?.innerHtml ||
      doc.selectFirst(".entry-content")?.innerHtml ||
      doc.selectFirst(".chapter__content")?.innerHtml ||
      doc.selectFirst(".prevent-select")?.innerHtml ||
      doc.selectFirst(".text_story")?.innerHtml ||
      doc.selectFirst(".contenta")?.innerHtml ||
      doc.selectFirst(".single_post")?.innerHtml ||
      doc.selectFirst(".post-entry")?.innerHtml ||
      doc.selectFirst(".main-content")?.innerHtml ||
      doc.selectFirst(".post-content")?.innerHtml ||
      doc.selectFirst(".content")?.innerHtml ||
      doc.selectFirst(".page-body")?.innerHtml ||
      doc.selectFirst(".td-page-content")?.innerHtml ||
      doc.selectFirst(".reader-content")?.innerHtml ||
      doc.selectFirst("#content")?.innerHtml ||
      doc.selectFirst("#the-content")?.innerHtml ||
      doc.selectFirst("article.post")?.innerHtml;

    if (isWordpress || domain.includes("etherreads") || domain.includes("soafp")) {
      return `<h2>${title}</h2><hr><br>${content}`;
    }

    return `<p>Domain not supported yet. Content might not load properly!</p>
            <br><h2>${title}</h2><hr><br>${content}`;
  }

  getFilterList() {
    return [
      {
        type_name: "GroupFilter",
        name: "Novel Type",
        state: [
          {
            type_name: "CheckBox",
            name: "Web Novel",
            value: "2444",
          },
          {
            type_name: "CheckBox",
            name: "Light Novel",
            value: "2443",
          },
          {
            type_name: "CheckBox",
            name: "Published Novel",
            value: "26874",
          },
        ],
      },
      {
        type_name: "GroupFilter",
        name: "Original Language",
        state: [
          {
            type_name: "CheckBox",
            name: "Chinese",
            value: "495",
          },
          {
            type_name: "CheckBox",
            name: "Filipino",
            value: "9181",
          },
          {
            type_name: "CheckBox",
            name: "Indonesian",
            value: "9179",
          },
          {
            type_name: "CheckBox",
            name: "Japanese",
            value: "496",
          },
          {
            type_name: "CheckBox",
            name: "Khmer",
            value: "18657",
          },
          {
            type_name: "CheckBox",
            name: "Korean",
            value: "497",
          },
          {
            type_name: "CheckBox",
            name: "Malaysian",
            value: "9183",
          },
          {
            type_name: "CheckBox",
            name: "Thai",
            value: "9954",
          },
          {
            type_name: "CheckBox",
            name: "Vietnamese",
            value: "9177",
          },
        ],
      },
      {
        type_name: "GroupFilter",
        name: "Genre",
        state: [
          {
            type_name: "TriState",
            name: "Action",
            value: "8",
          },
          {
            type_name: "TriState",
            name: "Adventure",
            value: "13",
          },
          {
            type_name: "TriState",
            name: "Comedy",
            value: "17",
          },
          {
            type_name: "TriState",
            name: "Drama",
            value: "9",
          },
          {
            type_name: "TriState",
            name: "Ecchi",
            value: "292",
          },
          {
            type_name: "TriState",
            name: "Fantasy",
            value: "5",
          },
          {
            type_name: "TriState",
            name: "Gender Bender",
            value: "168",
          },
          {
            type_name: "TriState",
            name: "Harem",
            value: "3",
          },
          {
            type_name: "TriState",
            name: "Horror",
            value: "343",
          },
          {
            type_name: "TriState",
            name: "Josei",
            value: "324",
          },
          {
            type_name: "TriState",
            name: "Martial Arts",
            value: "14",
          },
          {
            type_name: "TriState",
            name: "Mature",
            value: "4",
          },
          {
            type_name: "TriState",
            name: "Mecha",
            value: "10",
          },
          {
            type_name: "TriState",
            name: "Mystery",
            value: "245",
          },
          {
            type_name: "TriState",
            name: "Psychological",
            value: "486",
          },
          {
            type_name: "TriState",
            name: "Romance",
            value: "15",
          },
          {
            type_name: "TriState",
            name: "School",
            value: "6",
          },
          {
            type_name: "TriState",
            name: "Sci-Fi",
            value: "11",
          },
          {
            type_name: "TriState",
            name: "Seinen",
            value: "18",
          },
          {
            type_name: "TriState",
            name: "Shoujo",
            value: "157",
          },
          {
            type_name: "TriState",
            name: "Shoujo Ai",
            value: "851",
          },
          {
            type_name: "TriState",
            name: "Shounen",
            value: "12",
          },
          {
            type_name: "TriState",
            name: "Shounen Ai",
            value: "1692",
          },
          {
            type_name: "TriState",
            name: "Slice of Life",
            value: "7",
          },
          {
            type_name: "TriState",
            name: "Smut",
            value: "281",
          },
          {
            type_name: "TriState",
            name: "Sports",
            value: "1357",
          },
          {
            type_name: "TriState",
            name: "Supernatural",
            value: "16",
          },
          {
            type_name: "TriState",
            name: "Tragedy",
            value: "132",
          },
          {
            type_name: "TriState",
            name: "Wuxia",
            value: "479",
          },
          {
            type_name: "TriState",
            name: "Xianxia",
            value: "480",
          },
          {
            type_name: "TriState",
            name: "Xuanhuan",
            value: "3954",
          },
          {
            type_name: "TriState",
            name: "Yaoi",
            value: "560",
          },
          {
            type_name: "TriState",
            name: "Yuri",
            value: "922",
          },
        ],
      },
      {
        type_name: "GroupFilter",
        name: "Status",
        state: [
          {
            type_name: "CheckBox",
            name: "All",
            value: "",
          },
          {
            type_name: "CheckBox",
            name: "Completed",
            value: "2",
          },
          {
            type_name: "CheckBox",
            name: "Ongoing",
            value: "3",
          },
          {
            type_name: "CheckBox",
            name: "Hiatus",
            value: "4",
          },
        ],
      },
      {
        type_name: "SelectFilter",
        type: "sort",
        name: "Sort",
        state: 0,
        values: [
          {
            type_name: "SelectOption",
            name: "Last Updated",
            value: "sdate",
          },
          {
            type_name: "SelectOption",
            name: "Rating",
            value: "srate",
          },
          {
            type_name: "SelectOption",
            name: "Rank",
            value: "srank",
          },
          {
            type_name: "SelectOption",
            name: "Reviews",
            value: "sreview",
          },
          {
            type_name: "SelectOption",
            name: "Chapters",
            value: "srel",
          },
          {
            type_name: "SelectOption",
            name: "Title",
            value: "abc",
          },
          {
            type_name: "SelectOption",
            name: "Readers",
            value: "sread",
          },
          {
            type_name: "SelectOption",
            name: "Frequency",
            value: "sfrel",
          },
        ],
      },
      {
        type_name: "SelectFilter",
        name: "Order",
        state: 0,
        values: [
          {
            type_name: "SelectOption",
            name: "Descending",
            value: "desc",
          },
          {
            type_name: "SelectOption",
            name: "Ascending",
            value: "asc",
          },
        ],
      }
    ];
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }
}

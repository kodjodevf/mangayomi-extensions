const mangayomiSources = [
  {
    name: "Novel Updates",
    lang: "en",
    baseUrl: "https://www.novelupdates.com",
    apiUrl: "",
    iconUrl:
      "https://raw.githubusercontent.com/Schnitzel5/mangayomi-extensions/main/javascript/icon/en.novelupdates.png",
    typeSource: "single",
    itemType: 2,
    version: "0.0.1",
    dateFormat: "",
    dateFormatLocale: "",
    pkgPath: "novel/src/en/novelupdates.js",
    appMinVerReq: "0.3.75",
    isNsfw: false,
    hasCloudflare: true,
  },
];

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
  parseDate(date) {
    const months = {
      january: "01",
      february: "02",
      march: "03",
      april: "04",
      may: "05",
      june: "06",
      july: "07",
      august: "08",
      september: "09",
      october: "10",
      november: "11",
      december: "12",
    };
    date = date
      .toLowerCase()
      .replace(/(st|nd|rd|th)/g, "")
      .split(" ");
    if (!(date[0] in months)) {
      return String(new Date().valueOf());
    }
    date[0] = months[date[0]];
    const formattedDate = `${date[2]}-${date[0]}-${date[1].padStart(2, "0")}`; // Format YYYY-MM-DD
    return String(new Date(formattedDate).valueOf());
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
    const res = await new Client().get(
      `${this.source.baseUrl}/series-finder/?sf=1&sh=${query}&sort=sdate&order=desc&pg=${page}`,
      this.headers
    );
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
    const status = this.toStatus(doc.selectFirst("#editstatus").text.trim());
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
    const doc = new Document(res.body);
    if (res.body.includes("blogspot")) {
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
    return "<p>Domain not supported yet</p>";
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }
}

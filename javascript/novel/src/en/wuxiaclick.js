const mangayomiSources = [{
  "name": "WuxiaClick",
  "lang": "en",
  "baseUrl": "https://wuxia.click",
  "apiUrl": "",
  "iconUrl":
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/en.wuxiaclick.png",
  "typeSource": "single",
  "itemType": 2,
  "version": "0.0.1",
  "dateFormat": "",
  "dateFormatLocale": "",
  "pkgPath": "novel/src/en/wuxiaclick.js",
  "appMinVerReq": "0.4.0",
  "isNsfw": false,
  "hasCloudflare": false
}];

class DefaultExtension extends MProvider {
  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  mangaListFromPage(res) {
    const doc = new Document(res.body);
    const mangaElements = doc.select("div.mantine-grid-root > div.mantine-grid-col > div");
    const list = [];
    for (const element of mangaElements) {
      const name = element.selectFirst("a > div > div > div.mantine-Text-root")?.text.trim();
      const link = this.source.baseUrl + element.selectFirst("a").getHref;
      const imageUrl = element.selectFirst("img").getSrc;
      list.push({ name, imageUrl, link });
    }
    const pagination = doc.select("button.mantine-y4zem1 > svg > path").map((el) => el.attr("d"));
    const hasNextPage = pagination.length > 1 ? pagination[1].startsWith("M8") : false;
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
      `${this.source.baseUrl}/advance_search?order=-weekly_views&page=${page}`,
    );
    return this.mangaListFromPage(res);
  }

  async getLatestUpdates(page) {
    const res = await new Client().get(
      `${this.source.baseUrl}/advance_search?order=-created_at&page=${page}`,
    );
    return this.mangaListFromPage(res);
  }

  async search(query, page, filters) {
    let url = `${this.source.baseUrl}/advance_search?order=&page=${page}&search=${encodeURI(query)}`;
    const res = await new Client().get(url);
    return this.mangaListFromPage(res);
  }

  async getDetail(url) {
    const client = new Client();
    const res = await client.get(url);
    const doc = new Document(res.body);
    const imageUrl = doc.selectFirst("figure > div > img")?.getSrc;
    const description = doc.select("div.mantine-Spoiler-root > div > div > div.mantine-Text-root")?.text.trim();
    const author = doc.selectFirst("div.mantine-lqk3v2 > div")?.text.trim();
    const status = this.toStatus(doc.selectFirst("div.mantine-1uxmzbt > div.mantine-1huvzos")?.text.trim());
    const genre = doc.select("div.mantine-bl3g33 > div > a > div > div > span").map((el) => el.text.trim());

    const chapterElements = doc.select("div.mantine-1x5ubwi > div");
    for (const el of chapterElements) {
      let chapterName = el.selectFirst("div.mantine-Group-root > div > a > div > h4")?.text.trim();
      if (!chapterName) {
        continue;
      }
      const chapterUrl = this.source.baseUrl + el.selectFirst("div.mantine-Group-root > div > a").getHref;
      let dateUpload;
      try {
        dateUpload = this.parseDate(el.selectFirst("div > a > div > div > div.mantine-Text-root")?.text.trim());
      } catch (_) {
        dateUpload = null;
      }
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
    const res = await client.get(url);
    const doc = new Document(res.body);
    const title =
        doc.selectFirst("div.mantine-Center-root > h1.mantine-Title-root")?.text.trim() ||
        "";
    const content = doc.select("div.mantine-Container-root > div.mantine-Paper-root > div")[2]?.innerHtml;
    return `<h2>${title}</h2><hr><br>${content}`;
  }

  getFilterList() {
    return [];
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }

  parseDate(date) {
      const months = {
        "January": "01", "February": "02", "March": "03", "April": "04", "May": "05", "June": "06", 
        "July": "07", "August": "08", "September": "09", "October": "10", "November": "11", "December": "12"
      };
      date = date.toLowerCase().replace(",", "").split(" ");

      if (!(date[0] in months)) {
          return String(new Date().valueOf())
      }
      
      date[0] = months[date[0]];
      date = [date[2], date[0], date[1]];
      date = date.join("-");
      return String(new Date(date).valueOf());
  }
}

const mangayomiSources = [
  {
    "name": "Anna's Archive",
    "lang": "en",
    "baseUrl": "https://annas-archive.org",
    "apiUrl": "",
    "iconUrl":
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.annasarchive.png",
    "typeSource": "single",
    "itemType": 2,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "novel/src/all/annasarchive.js",
    "isNsfw": false,
    "hasCloudflare": true,
    "notes": "EPUBs need to be downloaded to view chapters!"
  }
];

class DefaultExtension extends MProvider {
  headers = {
    "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36"
  };

  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  mangaListFromPage(res) {
    const doc = new Document(res.body.replaceAll(RegExp("<!--|-->"), ""));
    const mangaElements = doc.select("a");
    const list = [];
    for (const element of mangaElements) {
      const name = element.selectFirst("h3").text;
      const imageUrl = element.selectFirst("img").getSrc;
      const link = element.getHref;
      list.push({ name, imageUrl, link });
    }
    const hasNextPage = true;
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
      `${this.source.baseUrl}/search?index=&page=${page}&q=&display=&ext=epub&src=lgli&sort=`,
      this.headers
    );
    return this.mangaListFromPage(res);
  }

  async getLatestUpdates(page) {
    const res = await new Client().get(
      `${this.source.baseUrl}/search?index=&page=${page}&q=&display=&ext=epub&src=lgli&sort=newest`,
      this.headers
    );
    return this.mangaListFromPage(res);
  }

  async search(query, page, filters) {
    //const lang = this.source.lang != "all" ? `&lang=${this.source.lang}` : "";
    let url = `${this.source.baseUrl}/series-finder/?sf=1&sh=${query}&pg=${page}`;

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

    const chapters = [];
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

    return `<p>Domain not supported yet. Content might not load properly!</p>`;
  }

  getFilterList() {
    return [];
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }
}

const mangayomiSources = [
  {
    "name": "Annas Archive",
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
    "notes": "EPUBs need to be downloaded to view chapters! Downloads from Libgen might be slow!",
  },
];

class DefaultExtension extends MProvider {
  headers = {
    Priority: "u=0, i",
    "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
  };

  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  mangaListFromPage(res) {
    const doc = new Document(res.body.replaceAll(/<!--|-->/g, ""));
    const mangaElements = doc.select("a");
    const list = [];
    for (const element of mangaElements) {
      const name = element.selectFirst("h3")?.text.replaceAll("🔍", "").trim();
      const imageUrl = element.selectFirst("img").getSrc;
      const link = element.getHref;
      if (link.includes("/md5/")) {
        list.push({ name, imageUrl, link });
      }
    }
    const hasNextPage = true;
    return { list: list, hasNextPage };
  }

  async getPopular(page) {
    let url = `${this.source.baseUrl}/search?index=&page=${page}&q=&display=&ext=epub&src=lgli&sort=`;
    if (this.source.lang != "all") {
      url += `&lang=${this.source.lang}`;
    }
    const res = await new Client().get(url, this.headers);
    return this.mangaListFromPage(res);
  }

  async getLatestUpdates(page) {
    let url = `${this.source.baseUrl}/search?index=&page=${page}&q=&display=&ext=epub&src=lgli&sort=newest`;
    if (this.source.lang != "all") {
      url += `&lang=${this.source.lang}`;
    }
    const res = await new Client().get(url, this.headers);
    return this.mangaListFromPage(res);
  }

  async search(query, page, filters) {
    let url = `${this.source.baseUrl}/search?index=&page=${page}&q=${query}&display=&ext=epub&src=lgli&sort=`;
    if (this.source.lang != "all") {
      url += `&lang=${this.source.lang}`;
    }
    const res = await new Client().get(url, this.headers);
    return this.mangaListFromPage(res);
  }

  async getDetail(url) {
    const client = new Client();
    const res = await client.get(this.source.baseUrl + url, this.headers);
    const doc = new Document(res.body);
    const main = doc.selectFirst('main[class="main"]');

    const name = doc.selectFirst('div.text-3xl.font-bold')?.text.trim();
    const description = doc
      .selectFirst('div[class="mb-1"]')
      ?.text.trim()
      .replace("description", "");
    const author = doc.selectFirst('div[class="italic"]')?.text.replaceAll("🔍", "").trim();
    const status = 1;
    const genre = [];

    const mirrorLink = main
      .selectFirst('ul[class="list-inside mb-4 ml-1 js-show-external hidden"]')
      .select("li > a")
      .find((el) => el.getHref?.includes("libgen.is")).getHref;

    const bookLink = await this._getMirrorLink(client, mirrorLink);

    if (!bookLink) {
      return {
        description,
        genre,
        author,
        status,
        chapters: [],
      };
    }

    const book = await parseEpub(name, bookLink, {
      Connection: "Keep-Alive",
      ...this.headers,
    });

    const chapters = [];
    for (const chapterTitle of book.chapters) {
      chapters.push({
        name: chapterTitle,
        url: mirrorLink + ";;;" + chapterTitle,
        dateUpload: String(Date.now()),
        scanlator: null,
      });
    }

    return {
      description,
      genre,
      author,
      status,
      chapters,
    };
  }

  async _getMirrorLink(client, mirrorLink) {
    const res = await client.get(mirrorLink, {
      Origin: this.source.baseUrl,
      ...this.headers,
    });
    const doc = new Document(res.body);
    const links = doc.select(
      "a"
    );
    const libgenRs = links.find((el) => el.getHref?.includes("books.ms"))?.getHref;
    const libgenLi = links.find((el) => el.getHref?.includes("libgen.li"))?.getHref;
    if (libgenRs && (await client.head(libgenRs, this.headers)).statusCode === 200) {
      const response = await client.get(libgenRs, this.headers);
      const document = new Document(response.body);
      return document.selectFirst('div#download > h2 > a')?.getHref;
    } else if (libgenLi && (await client.head(libgenLi, this.headers)).statusCode === 200) {
      const response = await client.get(libgenLi, this.headers);
      const document = new Document(response.body);
      return "https://libgen.li/" + document.selectFirst('tbody > tr > td > a')?.getHref;
    }
    return null;
  }

  async getHtmlContent(chapterName, url) {
    const urls = url.split(";;;");
    const client = await new Client();
    const bookLink = await this._getMirrorLink(client, urls[0]);

    return await parseEpubChapter(chapterName, bookLink, {
      Connection: "Keep-Alive",
      ...this.headers,
    }, urls[1]);
  }

  async cleanHtmlContent(html) {
    return html;
  }

  getFilterList() {
    return [];
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }
}

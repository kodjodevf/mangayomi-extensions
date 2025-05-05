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
    "notes": "EPUBs need to be downloaded to view chapters!",
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
      const name = element.selectFirst("h3").text;
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
    const lang = this.source.lang != "all" ? `&lang=${this.source.lang}` : "";
    let url = `${this.source.baseUrl}/search?index=&page=${page}&q=&display=&ext=epub&src=zlib&sort=`;
    if (lang !== "") {
      url += `&lang=${lang}`;
    }
    const res = await new Client().get(url, this.headers);
    return this.mangaListFromPage(res);
  }

  async getLatestUpdates(page) {
    const lang = this.source.lang != "all" ? `&lang=${this.source.lang}` : "";
    let url = `${this.source.baseUrl}/search?index=&page=${page}&q=&display=&ext=epub&src=zlib&sort=newest`;
    if (lang !== "") {
      url += `&lang=${lang}`;
    }
    const res = await new Client().get(url, this.headers);
    return this.mangaListFromPage(res);
  }

  async search(query, page, filters) {
    const lang = this.source.lang != "all" ? `&lang=${this.source.lang}` : "";
    let url = `${this.source.baseUrl}/search?index=&page=${page}&q=${query}&display=&ext=epub&src=zlib&sort=`;
    if (lang !== "") {
      url += `&lang=${lang}`;
    }

    const res = await new Client().get(url, this.headers);
    return this.mangaListFromPage(res);
  }

  async getDetail(url) {
    const client = new Client();
    const res = await client.get(this.source.baseUrl + url, this.headers);
    const doc = new Document(res.body);
    const main = doc.selectFirst('main[class="main"]');

    const description = doc
      .selectFirst('div[class="mb-1"]')
      ?.text.trim()
      .replace("description", "");
    const author = doc.selectFirst('div[class="italic"]')?.text.trim();
    const status = 1;
    const genre = [];
    console.log(description);

    const mirrorLink = main
      .selectFirst('ul[class="list-inside mb-4 ml-1 js-show-external hidden"]')
      .select("li > a")
      .find((el) => el.getHref?.includes("z-lib.fm")).getHref;

    const bookLink = await this._getMirrorLink(client, mirrorLink);

    const bytes = await client.getBytes("https://z-lib.fm" + bookLink, {
      Connection: "Keep-Alive",
      ...this.headers,
    });

    const book = await parseEpub(this.Utf8ArrayToStr(bytes));

    const chapters = [];
    for (const chapterTitle in book.chapters) {
      chapters.push({
        name: chapterTitle,
        url: mirrorLink + ";;;" + chapterTitle,
        dateUpload: Date.now(),
        scanlator: null,
      });
    }
    chapters.reverse();

    return {
      description,
      genre,
      author,
      artist,
      status,
      chapters,
    };
  }

  // http://www.onicos.com/staff/iz/amuse/javascript/expert/utf.txt
  /* utf.js - UTF-8 <=> UTF-16 convertion
   *
   * Copyright (C) 1999 Masanao Izumo <iz@onicos.co.jp>
   * Version: 1.0
   * LastModified: Dec 25 1999
   * This library is free.  You can redistribute it and/or modify it.
   */
  Utf8ArrayToStr(array) {
    var out, i, len, c;
    var char2, char3;

    out = "";
    len = array.length;
    i = 0;
    while (i < len) {
      c = array[i++];
      switch (c >> 4) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
          // 0xxxxxxx
          out += String.fromCharCode(c);
          break;
        case 12:
        case 13:
          // 110x xxxx   10xx xxxx
          char2 = array[i++];
          out += String.fromCharCode(((c & 0x1f) << 6) | (char2 & 0x3f));
          break;
        case 14:
          // 1110 xxxx  10xx xxxx  10xx xxxx
          char2 = array[i++];
          char3 = array[i++];
          out += String.fromCharCode(
            ((c & 0x0f) << 12) | ((char2 & 0x3f) << 6) | ((char3 & 0x3f) << 0)
          );
          break;
      }
    }

    return out;
  }

  async _getMirrorLink(client, mirrorLink) {
    const res = await client.get(mirrorLink, {
      Origin: this.source.baseUrl,
      ...this.headers,
    });
    const doc = new Document(res.body);
    return doc.selectFirst(
      "div.book-details-button > div.btn-group > a.addDownloadedBook"
    ).getHref;
    /*const res = await client.get(mirrorLink, {
      "Host": "annas-archive.org",
      "Origin": this.source.baseUrl,
      "Sec-Fetch-Dest": "document",
      "Sec-Fetch-Mode": "navigate",
      "Sec-Fetch-Site": "none",
      ...this.headers
    });
    const doc = new Document(res.body);
    const links = doc.select('ul[class="mb-4"] > li > a').map((el) => el.getHref).filter((el) => el);
    for (var url in links) {
      try {
        const response = await client.head(url, this.headers);
        if (response.statusCode == 200) {
          return url;
        }
      } catch (e) {}
    }
    return null;*/
  }

  async getHtmlContent(url) {
    const urls = url.split(";;;");
    const client = await new Client();
    const bookLink = await this._getMirrorLink(client, urls[0]);

    const bytes = await client.getBytes("https://z-lib.fm" + bookLink, {
      Connection: "Keep-Alive",
      ...this.headers,
    });

    return await parseEpubChapter(this.Utf8ArrayToStr(bytes), urls[1]);
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

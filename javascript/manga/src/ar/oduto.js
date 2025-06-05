// prettier-ignore
const mangayomiSources = [{
   "name": "Oduto - Boruto",
    "lang": "ar",
    "baseUrl":  "https://nb19u.blogspot.com",
    "apiUrl": "",
    "iconUrl": "https://blogger.googleusercontent.com/img/a/AVvXsEgKFmNQCUC7ARtXurDIwfOimVn3wogUvH7VaUOfjdutG44-cT4ajgh0KYkqSbRIoQ0b8YG3H6Edx-y1O3GW5SL88jymLZsO6cmS0QRtsp1y4gc24vmF4OGqyIY3PYSjxUYR1iJ5J-sP-00A7NwhNa19SPc0R_62KcuG6dbu2Rg-2YiMV1uUgaB0DGB6IBY_=s1600",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.1",
    "isNsfw": false,
    "pkgPath": "manga/src/ar/oduto.js",
    "notes": "This Source Just For Boruto"
}];

class DefaultExtension extends MProvider {
  async request(slug) {
    this.client ??= new Client();
    const res = await this.client.get(slug);
    return new Document(res.body);
  }

  getPopular(_) {
    return {
      list: [
        {
          name: "BORUTO: Two Blue Vortex",
          imageUrl:
            "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEggWB9vWPMqjEvIoDsJSO29OmW-srULDQD3cS9HJ8cDk0vq2jLwDerUX-i61CqmZf62eBVmWZwU5CgXi0p2lxhKrh2_nZum3p-k3q9QJ2uozove0QAbOKtbd1QPjytjrJc9UsL65X4BbFdgcicLDYubD9LgY1Kco8wyhDGm4YEOim8u1TL42gOFe16NaaEP/s3464/4D55C3C5-9168-4103-B45C-99B52B58B6A5.jpeg",
          link: "https://nb19u.blogspot.com/search/label/%D9%85%D8%A7%D9%86%D8%AC%D8%A7%20%D8%A8%D9%88%D8%B1%D9%88%D8%AA%D9%88?&max-results=4&m=1",
        },
      ],
      hasNextPage: false,
    };
  }
  getLatestUpdates(_) {
    return this.getPopular();
  }

  //  Chapters
  chapterFromElement(element) {
    const anchor = element.selectFirst("div.iPostInfoWrap > h3 > a");
    const timeElement = element.selectFirst("div.iPostInfoWrap time");
    if (!anchor || !timeElement) return {};

    const name = anchor.text?.trim();
    const url = anchor.getHref;
    const rawDate = timeElement.attr("datetime")?.trim();
    const dateUpload = rawDate ? new Date(rawDate).getTime().toString() : null;

    return { name, dateUpload, url };
  }

  //  Detail
  async getDetail(url) {
    let doc = await this.request(url);
    const allElements = [];

    for (;;) {
      const pageChapters = doc.select("#Blog1 article.blog-post.index-post");
      if (!pageChapters || pageChapters.length === 0) break;
      allElements.push(...pageChapters);

      const nextUrl = doc
        .selectFirst("#Blog1 > div.iPostsNavigation > button[data-load]")
        .attr("data-load");
      if (!nextUrl || nextUrl.length === 0) break;
      doc = await this.request(nextUrl);
    }

    const chapters = allElements.map((element) =>
      this.chapterFromElement(element),
    );

    return {
      title: "BORUTO: Two Blue Vortex",
      imageUrl:
        "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEggWB9vWPMqjEvIoDsJSO29OmW-srULDQD3cS9HJ8cDk0vq2jLwDerUX-i61CqmZf62eBVmWZwU5CgXi0p2lxhKrh2_nZum3p-k3q9QJ2uozove0QAbOKtbd1QPjytjrJc9UsL65X4BbFdgcicLDYubD9LgY1Kco8wyhDGm4YEOim8u1TL42gOFe16NaaEP/s3464/4D55C3C5-9168-4103-B45C-99B52B58B6A5.jpeg",
      author: "Masashi Kishimoto",
      description: "Artist: Mikio Ikemoto",
      status: 0,
      genre: ["شونين", "دراما", "خيال", "أكشن", "نينجا"],
      chapters,
    };
  }

  //  chapter pages
  async getPageList(url) {
    const doc = await this.request(url);
    return doc.select("div.#post-body img[src]").map((x) => ({
      url: x.attr("src"),
    }));
  }
}

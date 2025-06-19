// prettier-ignore
const mangayomiSources = [{
    "name": "ملوك الروايات",
    "lang": "ar",
    "baseUrl": "https://kolnovel.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://kolnovel.com",
    "typeSource": "single",
    "itemType": 2,
    "version": "0.0.1",
    "pkgPath": "novel/src/ar/kolnovel.js",
    "notes": ""
}];

class DefaultExtension extends MProvider {
  headers = {
    Referer: this.getActiveSiteUrl(),
    Origin: this.getActiveSiteUrl(),
    "Sec-Fetch-Mode": "cors",
    "Accept-Encoding": "gzip, deflate",
    "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
  };

  defaultKolBookUrl = "https://kolbook.xyz";

  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  cleanTitle(title) {
    if (!/[-_&@#%^)(*\s]*(كول|kol)/i.test(title)) return title;
    title = title.replace(/[-_&@#%^)(*\s]*(كول|kol)/i, "");
    title = title.replace(/[-–_&@#%^)(*+،؛:]+/g, " ");
    title = title.replace(/\s+/g, " ").trim();
    return title;
  }

  novelFromElement(res) {
    const doc = new Document(res.body);
    const elements = doc.select("div.listupd article");
    const list = [];
    for (const el of elements) {
      const name = this.cleanTitle(el.selectFirst("h2 a").text);
      const imageUrl = el.selectFirst("img").getSrc;
      const link = el.selectFirst("h2 a").getHref;
      list.push({ name, imageUrl, link });
    }
    const hasNextPage = doc.selectFirst("div.hpage > a.r").text == "Next ";
    return { list, hasNextPage };
  }

  async getPopular(page) {
    const res = await new Client().get(
      `${this.getActiveSiteUrl()}/series/?page=${page}&order=popular`,
      this.headers,
    );
    return this.novelFromElement(res);
  }

  async getLatestUpdates(page) {
    const res = await new Client().get(
      `${this.getActiveSiteUrl()}/series/?page=${page}&order=update`,
      this.headers,
    );
    return this.novelFromElement(res);
  }

  async search(query, page, filters) {
    throw new Error("search not implemented");
  }
  async getDetail(url) {
    throw new Error("getDetail not implemented");
  }
  // For novel html content
  async getHtmlContent(name, url) {
    throw new Error("getHtmlContent not implemented");
  }
  // Clean html up for reader
  async cleanHtmlContent(html) {
    throw new Error("cleanHtmlContent not implemented");
  }
  // For anime episode video list
  async getVideoList(url) {
    throw new Error("getVideoList not implemented");
  }
  // For manga chapter pages
  async getPageList(url) {
    throw new Error("getPageList not implemented");
  }
  getFilterList() {
    throw new Error("getFilterList not implemented");
  }

  getSanitizedUrl(prefKey) {
    const preference = new SharedPreferences();
    let url = preference.get(prefKey) || this.source.baseUrl;
    return url.endsWith("/") ? url.slice(0, -1) : url;
  }

  getActiveSiteUrl() {
    return this.getSanitizedUrl("selected_site_url");
  }

  getKolNovelUrl() {
    return this.getSanitizedUrl("kolnovel_custom_url");
  }

  getKolBookUrl() {
    return this.getSanitizedUrl("kolbook_custom_url");
  }

  getSourcePreferences() {
    return [
      {
        key: "kolnovel_custom_url",
        editTextPreference: {
          title: "المصدر الرئيسي",
          summary: "يوفر كافة الفصول، لكن بعض المحتوى يتطلب اشتراكًا.",
          value: this.source.baseUrl,
          dialogTitle: "URL",
          dialogMessage: "",
        },
      },
      {
        key: "kolbook_custom_url",
        editTextPreference: {
          title: "المصدر المجاني",
          summary: "لا يتطلب اشتراكًا، ولكن قد لا بحتوي على كافة الفصول.",
          value: this.defaultKolBookUrl,
          dialogTitle: "URL",
          dialogMessage: "",
        },
      },
      {
        key: "selected_site_url",
        listPreference: {
          title: "أختر المصدر.",
          summary: "",
          valueIndex: 0,
          entries: [
            "المصدر الرسمي (قد يتطلب اشتراك)",
            "المصدر المجانية (بدون اشتراك)",
          ],
          entryValues: [this.getKolNovelUrl(), this.getKolBookUrl()],
        },
      },
    ];
  }
}

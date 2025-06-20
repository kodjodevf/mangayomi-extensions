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

  toStatus(status) {
    return (
      {
        Ongoing: 0,
        Completed: 1,
        Hiatus: 2,
      }[status] ?? 5 // 5 => unknown
    );
  }

  async getDetail(url) {
    const res = await new Client().get(url, this.headers);
    const doc = new Document(res.body);
    const info = doc.selectFirst("div.sertoinfo");
    const subInfo = info.selectFirst("div.sertoauth");
    const rewName = info.selectFirst("h1.entry-title").text;

    const name = this.cleanTitle(rewName);
    const imageUrl = doc.selectFirst("img.attachment-post-thumbnail")?.getSrc;
    const scanlator = subInfo.selectFirst(".serl:contains('المترجم') a").text;

    let description =
      info.selectFirst("div.sersys.entry-content p").text + "\n\n";
    const lang = subInfo.selectFirst(
      ".serl:contains('اللغة الأم') .serval",
    )?.text;
    if (lang) description += `اللغة الأم: ${lang}\n`;
    const releaseYear = subInfo.selectFirst(
      ".serl:contains('صدر في سنة') .serval",
    )?.text;
    if (releaseYear) description += `سنة الصدور: ${releaseYear}\n`;
    const types = subInfo
      .select(".serl:contains('نوع') a")
      .map((el) => el.text)
      .join(", ");
    if (types) description += `الانواع: ${types}\n`;
    const altTitle = this.cleanTitle(info.selectFirst("span.alter")?.text);
    if (altTitle) description += `اسم آخر للعمل: ${altTitle}\n`;

    const genre = info.select("div.sertogenre a").map((el) => el.text);
    const author = subInfo.selectFirst(".serl:contains('الكاتب') a").text;
    const status = this.toStatus(info.selectFirst("div.sertostat span").text);

    const chapters = [];
    for (const el of doc.select("div.sertobody div.bixbox ul li > a")) {
      const url = el.getHref;
      const dateUpload = this.parseDate(el.selectFirst("div.epl-date").text);

      // Chapter name
      let title = el.selectFirst("div.epl-title").text.trim();
      const num = el.selectFirst("div.epl-num").text.trim();

      if (title.includes(num)) title = title.replace(num, "").trim();
      if (title.includes(rewName)) title = title.replace(rewName, "").trim();
      if (title.includes(name)) title = title.replace(name, "").trim();

      const numMatch = num.match(/(?:الفصل|chapter)\s+(\d+(?:\.\d+)?)/i);
      if (numMatch)
        title = title.replace(numMatch[0], "").replace(numMatch[1], "").trim();

      title = title.replace(/\s{2,}/g, " ").trim();
      const finalName =
        title && num ? `${num}: ${title}` : title ? title : num ? num : "?";

      chapters.push({ name: finalName, url, dateUpload, scanlator });
    }

    return {
      name,
      imageUrl,
      description,
      genre,
      author,
      status,
      chapters,
    };
  }

  extractIdFromUrl(url) {
    const match = url.match(/-(\d+)\/?$/);
    return match ? match[1] : null;
  }

  // For novel html content
  async getHtmlContent(name, url) {
    const id = this.extractIdFromUrl(url);
    const res = await new Client().get(
      `${this.getActiveSiteUrl()}/wp-json/wp/v2/posts/${id}`,
      this.headers,
    );

    return this.cleanHtmlContent(JSON.parse(res.body));
  }

  // Clean html up for reader
  async cleanHtmlContent(html) {
    return `<h2 style="text-align: center;">${html.title.rendered}</h2><hr><br>${html.content.rendered}`;
  }

  getFilterList() {
    throw new Error("getFilterList not implemented");
  }

  getActiveSiteUrl() {
    const preference = new SharedPreferences();
    const selectedSiteKey =
      preference.get("selected_site_key") || "kolnovel_custom_url";
    let url;
    if (selectedSiteKey === "kolnovel_custom_url") {
      url = preference.get(selectedSiteKey) || this.source.baseUrl;
    } else {
      // kolbook_custom_url
      url = preference.get(selectedSiteKey) || this.defaultKolBookUrl;
    }

    return url.endsWith("/") ? url.slice(0, -1) : url;
  }

  getSourcePreferences() {
    return [
      {
        key: "kolnovel_custom_url",
        editTextPreference: {
          title: "-تعديل الرابط -الرئيسي",
          summary: "",
          value: this.source.baseUrl,
          dialogTitle: "تعديل",
          dialogMessage: `Defaul URL ${this.source.baseUrl}`,
        },
      },
      {
        key: "kolbook_custom_url",
        editTextPreference: {
          title: "-تعديل الرابط -المجاني",
          summary: "",
          value: this.defaultKolBookUrl,
          dialogTitle: "تعديل",
          dialogMessage: `Defaul URL ${this.defaultKolBookUrl}`,
        },
      },
      {
        key: "selected_site_key",
        listPreference: {
          title: "أختر المصدر.",
          summary: "",
          valueIndex: 0,
          entries: [
            "المصدر الرسمي (قد يتطلب اشتراك)",
            "المصدر المجانية (بدون اشتراك)",
          ],
          entryValues: ["kolnovel_custom_url", "kolbook_custom_url"],
        },
      },
    ];
  }

  parseDate(date) {
    const months = {
      يناير: "January",
      فبراير: "February",
      مارس: "March",
      أبريل: "April",
      ابريل: "April",
      مايو: "May",
      يونيو: "June",
      يوليو: "July",
      أغسطس: "August",
      اغسطس: "August",
      سبتمبر: "September",
      أكتوبر: "October",
      اكتوبر: "October",
      نوفمبر: "November",
      ديسمبر: "December",
    };
    const [monthAr, day, year] = date.split(/[\s,]+/);
    const monthEnglish = months[monthAr] || "";
    if (!monthEnglish) return "";
    return new Date(`${monthEnglish} ${day}, ${year}`).getTime().toString();
  }
}

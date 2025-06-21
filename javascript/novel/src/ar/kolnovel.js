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

  novelFromJson(json) {
    const list = [];
    for (const el of json.series[0].all) {
      const name = this.cleanTitle(el.post_title);
      const imageUrl = el.post_image;
      const link = el.post_link;
      list.push({ name, imageUrl, link });
    }
    return { list, hasNextPage: false };
  }

  async getPopular(page) {
    const res = await new Client().get(
      `${this.getBaseUrl()}/series/?page=${page}&order=popular`,
      this.headers,
    );
    return this.novelFromElement(res);
  }

  async getLatestUpdates(page) {
    const res = await new Client().get(
      `${this.getBaseUrl()}/series/?page=${page}&order=update`,
      this.headers,
    );
    return this.novelFromElement(res);
  }

  async search(query, page, filters) {
    const keyword = query.trim().replace(/\s+/g, "+");
    if (keyword) {
      const res = await new Client().post(
        `${this.getBaseUrl()}/wp-admin/admin-ajax.php`,
        {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        `action=ts_ac_do_search&ts_ac_query=${keyword}`,
      );
      return this.novelFromJson(JSON.parse(res.body));
    }

    let url = `${this.getBaseUrl()}/series/?page=${page}`;
    filters.forEach((filter) => {
      if (filter.type === "GenreFilter") {
        const genre = filter.state.filter((e) => e.state);
        genre.forEach((gen) => (url += `${this.ll(url)}genre[]=${gen.value}`));
      } else if (filter.type === "TypeFilter") {
        const type = filter.state.filter((e) => e.state);
        type.forEach((ty) => (url += `${this.ll(url)}type[]=${ty.value}`));
      } else if (filter.type === "OrderFilter") {
        if (filter.values?.[filter.state]?.value)
          url += `${this.ll(url)}order=${filter.values[filter.state].value}`;
      } else if (filter.type === "StatusFilter") {
        if (filter.values?.[filter.state]?.value)
          url += `${this.ll(url)}status=${filter.values[filter.state].value}`;
      }
    });

    const res = await new Client().get(url, this.headers);
    return this.novelFromElement(res);
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
      if (numMatch) {
        title = title.replace(numMatch[0], "").trim();
        if (!title.includes(`(${numMatch[1]})`)) {
          title = title.replace(numMatch[1], "").trim();
        }
      }

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
      `${this.getBaseUrl()}/wp-json/wp/v2/posts/${id}`,
      this.headers,
    );

    return this.cleanHtmlContent(JSON.parse(res.body));
  }

  // Clean html up for reader
  async cleanHtmlContent(html) {
    return `<h2 style="text-align: center;">${this.cleanTitle(html.title.rendered)}</h2><hr><br>${html.content.rendered}`;
  }

  getFilterList() {
    return [
      {
        type: "StatusFilter",
        name: "الحالة",
        type_name: "SelectFilter",
        values: [
          {
            type_name: "SelectOption",
            name: "الكل",
            value: "",
          },
          {
            type_name: "SelectOption",
            name: "مستمر",
            value: "ongoing",
          },
          {
            type_name: "SelectOption",
            name: "متوقف مؤقتًا",
            value: "hiatus",
          },
          {
            type_name: "SelectOption",
            name: "مكتمل",
            value: "completed",
          },
        ],
        state: 0,
      },
      {
        type: "OrderFilter",
        name: "ترتيب حسب",
        type_name: "SelectFilter",
        values: [
          {
            type_name: "SelectOption",
            name: "الإعداد الأولي",
            value: "",
          },
          {
            type_name: "SelectOption",
            name: "A-Z",
            value: "title",
          },
          {
            type_name: "SelectOption",
            name: "Z-A",
            value: "titlereverse",
          },
          {
            type_name: "SelectOption",
            name: "أخر التحديثات",
            value: "update",
          },
          {
            type_name: "SelectOption",
            name: "أخر ما تم إضافته",
            value: "latest",
          },
          {
            type_name: "SelectOption",
            name: "الرائجة",
            value: "popular",
          },
          {
            type_name: "SelectOption",
            name: "التقييم",
            value: "rating",
          },
        ],
        state: 0,
      },
      {
        type_name: "GroupFilter",
        type: "GenreFilter",
        name: "تصنيف",
        state: [
          ["Romance", "romance"],
          ["Shounen Ai", "shounen-ai"],
          ["Wuxia", "wuxia"],
          ["Xianxia", "xianxia"],
          ["XUANHUAN", "xuanhuan"],
          [
            "أبطال خارقين",
            "%d8%a3%d8%a8%d8%b7%d8%a7%d9%84-%d8%ae%d8%a7%d8%b1%d9%82%d9%8a%d9%86",
          ],
          ["أساطير", "%d8%a3%d8%b3%d8%a7%d8%b7%d9%8a%d8%b1"],
          ["أشباح", "%d8%a3%d8%b4%d8%a8%d8%a7%d8%ad"],
          ["أكشن", "action"],
          ["ألعاب", "%d8%a3%d9%84%d8%b9%d8%a7%d8%a8"],
          ["إثارة", "excitement"],
          ["إسلامي", "%d8%a5%d8%b3%d9%84%d8%a7%d9%85%d9%8a"],
          ["إنتقال الى عالم أخر", "isekai"],
          ["إيتشي", "etchi"],
          ["اكاديمي", "%d8%a7%d9%83%d8%a7%d8%af%d9%8a%d9%85%d9%8a"],
          ["اكشن", "%d8%a7%d9%83%d8%b4%d9%86"],
          ["الإثارة", "%d8%a7%d9%84%d8%a5%d8%ab%d8%a7%d8%b1%d8%a9"],
          ["الخيال العلمي", "sci-fi"],
          ["الدراما", "%d8%a7%d9%84%d8%af%d8%b1%d8%a7%d9%85%d8%a7"],
          [
            "المغامرات",
            "%d8%a7%d9%84%d9%85%d8%ba%d8%a7%d9%85%d8%b1%d8%a7%d8%aa",
          ],
          ["انتقام", "%d8%a7%d9%86%d8%aa%d9%82%d8%a7%d9%85"],
          ["بطل مضاد", "%d8%a8%d8%b7%d9%84-%d9%85%d8%b6%d8%a7%d8%af"],
          ["بطل ناضج", "%d8%a8%d8%b7%d9%84-%d9%86%d8%a7%d8%b6%d8%ac"],
          ["بقاء", "%d8%a8%d9%82%d8%a7%d8%a1"],
          [
            "بناء مملكة",
            "%d8%a8%d9%86%d8%a7%d8%a1-%d9%85%d9%85%d9%84%d9%83%d8%a9",
          ],
          ["بوليسي", "policy"],
          ["تاريخ", "%d8%aa%d8%a7%d8%b1%d9%8a%d8%ae"],
          ["تاريخي", "historical"],
          ["تحقيقات", "%d8%aa%d8%ad%d9%82%d9%8a%d9%82"],
          ["تشويق", "%d8%aa%d8%b4%d9%88%d9%8a%d9%82"],
          ["تقمص شخصيات", "rpg"],
          ["تلاعب", "%d8%aa%d9%84%d8%a7%d8%b9%d8%a8"],
          ["تناسخ", "%d8%aa%d9%86%d8%a7%d8%b3%d8%ae"],
          ["جريمة", "crime"],
          ["جوسى", "josei"],
          ["جوسي", "%d8%ac%d9%88%d8%b3%d9%8a"],
          ["حريم", "harem"],
          [
            "حل الألغاز",
            "%d8%ad%d9%84-%d8%a7%d9%84%d8%a3%d9%84%d8%ba%d8%a7%d8%b2",
          ],
          ["حياة مدرسية", "school-life"],
          [
            "خارق للطبيعة",
            "%d8%ae%d8%a7%d8%b1%d9%82-%d9%84%d9%84%d8%b7%d8%a8%d9%8a%d8%b9%d8%a9",
          ],
          ["خيال", "%d8%ae%d9%8a%d8%a7%d9%84"],
          ["خيال علمي", "%d8%ae%d9%8a%d8%a7%d9%84-%d8%b9%d9%84%d9%85%d9%8a"],
          ["خيالي", "%d8%ae%d9%8a%d8%a7%d9%84%d9%8a"],
          ["خيالي(فانتازيا)", "fantasy"],
          ["دراما", "drama"],
          ["درامي", "%d8%af%d8%b1%d8%a7%d9%85%d9%8a"],
          ["رعب", "horror"],
          ["رعب كوني", "%d8%b1%d8%b9%d8%a8-%d9%83%d9%88%d9%86%d9%8a"],
          ["رعب نفسي", "%d8%b1%d8%b9%d8%a8-%d9%86%d9%81%d8%b3%d9%8a"],
          ["رومانسي", "romantic"],
          ["رومانسية", "%d8%b1%d9%88%d9%85%d8%a7%d9%86%d8%b3%d9%8a%d8%a9"],
          ["رومنسية", "%d8%b1%d9%88%d9%85%d9%86%d8%b3%d9%8a%d8%a9"],
          ["زنزانة", "%d8%b2%d9%86%d8%b2%d8%a7%d9%86%d8%a9"],
          ["زيانشيا", "%d8%b2%d9%8a%d8%a7%d9%86%d8%b4%d9%8a%d8%a7"],
          ["ستيم بانك", "%d8%b3%d8%aa%d9%8a%d9%85-%d8%a8%d8%a7%d9%86%d9%83"],
          ["سحر", "magic"],
          [
            "سفر بالزمن",
            "%d8%b3%d9%81%d8%b1-%d8%a8%d8%a7%d9%84%d8%b2%d9%85%d9%86",
          ],
          [
            "سفر عبر الزمن",
            "%d8%b3%d9%81%d8%b1-%d8%b9%d8%a8%d8%b1-%d8%a7%d9%84%d8%b2%d9%85%d9%86",
          ],
          ["سياسة", "%d8%b3%d9%8a%d8%a7%d8%b3%d8%a9"],
          ["سينن", "senen"],
          ["شريحة من الحياة", "slice-of-life"],
          ["شعر", "%d8%b4%d8%b9%d8%b1"],
          ["شوانهوان", "%d8%b4%d9%88%d8%a7%d9%86%d9%87%d9%88%d8%a7%d9%86"],
          ["شوجو", "shojo"],
          ["شونين", "shonen"],
          ["طبي", "medical"],
          ["ظواهر خارقة للطبيعة", "supernatural"],
          ["عائلي", "%d8%b9%d8%a7%d8%a6%d9%84%d9%8a"],
          ["عموض", "%d8%b9%d9%85%d9%88%d8%b6"],
          ["غموض", "mysteries"],
          ["فانتازي", "%d9%81%d8%a7%d9%86%d8%aa%d8%a7%d8%b2%d9%8a"],
          ["فانتازيا", "%d9%81%d8%a7%d9%86%d8%aa%d8%a7%d8%b2%d9%8a%d8%a7"],
          ["فانفيك", "%d9%81%d8%a7%d9%86%d9%81%d9%8a%d9%83"],
          ["فنتازيا", "%d9%81%d9%86%d8%aa%d8%a7%d8%b2%d9%8a%d8%a7"],
          ["فنون القتال", "martial-arts"],
          ["فنون قتال", "%d9%81%d9%86%d9%88%d9%86-%d9%82%d8%aa%d8%a7%d9%84"],
          ["قصة قصيرة", "%d9%82%d8%b5%d8%a9-%d9%82%d8%b5%d9%8a%d8%b1%d8%a9"],
          ["قوة خارقة", "%d9%82%d9%88%d8%a9-%d8%ae%d8%a7%d8%b1%d9%82%d8%a9"],
          ["قوى خارقة", "superpower"],
          ["كوميدي", "comedy"],
          ["كوميديا", "%d9%83%d9%88%d9%85%d9%8a%d8%af%d9%8a%d8%a7"],
          ["كوميدية", "%d9%83%d9%88%d9%85%d9%8a%d8%af%d9%8a%d8%a9"],
          ["مأساة", "%d9%85%d8%a3%d8%b3%d8%a7%d8%a9"],
          ["مأساوي", "tragedy"],
          ["مؤامرة", "%d9%85%d8%a4%d8%a7%d9%85%d8%b1%d8%a9"],
          ["ما بعد الكارثة", "after-the-disaster"],
          [
            "ما بعد نهاية العالم",
            "%d9%85%d8%a7-%d8%a8%d8%b9%d8%af-%d9%86%d9%87%d8%a7%d9%8a%d8%a9-%d8%a7%d9%84%d8%b9%d8%a7%d9%84%d9%85",
          ],
          [
            "مضاد البطل",
            "%d9%85%d8%b6%d8%a7%d8%af-%d8%a7%d9%84%d8%a8%d8%b7%d9%84",
          ],
          ["مغامرات", "%d9%85%d8%ba%d8%a7%d9%85%d8%b1%d8%a7%d8%aa"],
          ["مغامرة", "adventure"],
          ["ميكا", "mechanical"],
          ["ناضج", "mature"],
          ["نظام", "%d9%86%d8%b8%d8%a7%d9%85"],
          ["نفسي", "psychological"],
          ["ون شوت", "%d9%88%d9%86-%d8%b4%d9%88%d8%aa"],
          ["ووكسيا", "%d9%88%d9%88%d9%83%d8%b3%d9%8a%d8%a7"],
        ].map((x) => ({ type_name: "CheckBox", name: x[0], value: x[1] })),
      },
      {
        type_name: "GroupFilter",
        type: "TypeFilter",
        name: "النوع",
        state: [
          ["إنجليزية", "english"],
          ["رواية لايت", "light-novel"],
          [
            "رواية مؤلفة",
            "%d8%b1%d9%88%d8%a7%d9%8a%d8%a9-%d9%85%d8%a4%d9%84%d9%81%d8%a9",
          ],
          ["رواية ويب", "web-novel"],
          ["صينية", "chinese"],
          ["عربية", "arabic"],
          ["كورية", "korean"],
          ["مؤلفة", "%d9%85%d8%a4%d9%84%d9%81%d8%a9"],
          ["ون شوت", "%d9%88%d9%86-%d8%b4%d9%88%d8%aa"],
          ["يابانية", "japanese"],
        ].map((x) => ({ type_name: "CheckBox", name: x[0], value: x[1] })),
      },
    ];
  }

  getBaseUrl() {
    const preference = new SharedPreferences();
    var base_url = preference.get("base_url");
    if (base_url.length == 0) {
      return this.source.baseUrl;
    }
    if (base_url.endsWith("/")) {
      return base_url.slice(0, -1);
    }
    return base_url;
  }

  getSourcePreferences() {
    return [
      {
        key: "base_url",
        editTextPreference: {
          title: "تعديل الرابط",
          summary: "",
          value: this.source.baseUrl,
          dialogTitle: "تعديل",
          dialogMessage: `Defaul URL ${this.source.baseUrl}`,
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

  ll(url) {
    return url.includes("?") ? "&" : "?";
  }
}

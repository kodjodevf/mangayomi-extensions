const mangayomiSources = [
  {
    name: "TeamX",
    lang: "ar",
    baseUrl: "https://olympustaff.com",
    apiUrl: "",
    iconUrl:
      "https://www.google.com/s2/favicons?sz=256&domain=https://olympustaff.com&size=256",
    typeSource: "single",
    itemType: 0,
    version: "1.0.0",
    pkgPath: "manga/src/ar/teamx.js",
  },
];

class DefaultExtension extends MProvider {
  constructor() {
    super();
    this.client = new Client();
    this.baseUrl = new SharedPreferences().get("overrideBaseUrl1");
  }

  getHeaders(url) {
    return {
      Referer: this.source.baseUrl,
    };
  }

  toStatus(status) {
    return (
      {
        مستمرة: 0,
        مكتملة: 1,
        متوقف: 2,
        متروك: 3,
        مكتمل: 4,
      }[status] ?? 5
    );
  }
  hasNextPage(doc) {
    return (
      doc.selectFirst(".pagination li.page-item a[rel='next'] ").attr("href") !=
      ""
    );
  }

  parseChapterDate(date) {
    // Format YYYY-MM-DD
    return String(new Date(date).toISOString().split("T")[0]);
  }

  async request(slug) {
    const res = await this.client.get(`${this.baseUrl}${slug}`);
    return new Document(res.body);
  }

  chapterFromElement(element) {
    const chapter = {
      name: "",
      dateUpload: 0,
      url: "",
    };

    const chpNum = element.selectFirst("div.epl-num").text.trim();
    const chpTitle = element.selectFirst("div.epl-title").text.trim();

    chapter.name = chpTitle.includes(chpNum.replace(/[^0-9]/g, ""))
      ? chpTitle
      : !chpNum
        ? chpTitle
        : !chpTitle
          ? chpNum
          : `${chpNum} - ${chpTitle}`;

    chapter.dateUpload = this.parseChapterDate(
      element.selectFirst("div.epl-date").text.trim(),
    );
    chapter.url = element.getHref;

    return chapter;
  }
  async chapterListParse(response) {
    const allElements = [];
    let doc = response;

    while (true) {
      const pageChapters = doc.select("div.eplister ul a");
      if (pageChapters.length === 0) {
        break;
      }

      allElements.push(...pageChapters);
      const nextPage = doc.select("a[rel=next]");
      if (!nextPage.length > 0) {
        break;
      }

      const nextUrl = nextPage.at(0).attr("href");
      const nextResponse = await new Client().get(nextUrl);
      doc = new Document(nextResponse.body);
    }

    return allElements.map((element) => this.chapterFromElement(element));
  }
  async getMangaList(slug) {
    const doc = await this.request(`/${slug}`);
    const mangaElements = doc.select(".listupd .bsx");

    const list = [];
    for (const element of mangaElements) {
      const name = element.selectFirst("a").attr("title")?.trim();
      const imageUrl = element.selectFirst("img").getSrc;
      const link = element.getHref;
      list.push({ name, imageUrl, link });
    }
    const hasNextPage = this.hasNextPage(doc);
    return { list: list, hasNextPage };
  }

  async getPopular(page) {
    return await this.getMangaList(`series?page=${page}`);
  }

  async getLatestUpdates(page) {
    const doc = await this.request(`/?page=${page}`);
    const mangaElements = doc.select(".post-body .box");
    const list = [];
    for (const element of mangaElements) {
      const name = element.selectFirst(".info a h3").text;
      const imageUrl = element.selectFirst(".imgu img").getSrc;
      const link = element.selectFirst(".imgu a").getHref;
      list.push({ name, imageUrl, link });
    }
    const hasNextPage = this.hasNextPage(doc);
    return { list: list, hasNextPage };
  }

  get supportsLatest() {
    throw new Error("supportsLatest not implemented");
  }

  async search(query, page, filters) {
    if (!query) {
      const type = filters[0].values[filters[0].state].value;
      const status = filters[1].values[filters[1].state].value;
      const genre = filters[2].values[filters[2].state].value;
      return await this.getMangaList(
        `series?page=${page}&genre=${genre}&type=${type}&status=${status}`,
      );
    }

    const doc = await this.request(`/ajax/search?keyword="${query}`).select(
      "li.list-group-item",
    );

    const list = [];
    for (const element of doc) {
      const name = element.selectFirst("div.ms-2 a").text;
      const imageUrl = element.selectFirst("a img").getSrc;
      const link = element.selectFirst("div.ms-2 a").getHref;
      list.push({ name, imageUrl, link });
    }

    return { list, hasNextPage: false };
  }

  async getDetail(url) {
    const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
    const res = await this.client.get(url);
    const doc = new Document(res.body);

    const title = doc.selectFirst("div.author-info-title h1")?.text.trim();
    const imageUrl = doc.selectFirst("img.shadow-sm")?.getSrc;
    const description = doc.selectFirst(".review-content > p")?.text.trim();
    const authorText = doc
      .selectFirst(
        ".full-list-info > small:first-child:contains(الرسام) + small",
      )
      ?.text?.trim();
    const author = authorText !== "غير معروف" ? authorText : null;
    const status = this.toStatus(
      doc
        .selectFirst(
          ".full-list-info > small:first-child:contains(الحالة) + small",
        )
        ?.text?.trim(),
    );
    const genre = doc
      .select("div.review-author-info a")
      .map((e) => e.text.trim());

    const chapters = await this.chapterListParse(doc);

    return {
      title,
      imageUrl,
      description,
      author,
      status,
      genre,
      chapters,
    };
  }

  // For novel html content
  async getHtmlContent(url) {
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
    const res = await this.client.get(url);
    const doc = new Document(res.body);

    return doc.select("div.image_list img[src]").map((x) => ({
      url: x.attr("src"),
    }));
  }

  getFilterList() {
    return [
      {
        type_name: "SelectFilter",
        name: "النوع",
        values: [
          ["اختر النوع", ""],
          ["مانها صيني", "مانها صيني"],
          ["مانجا ياباني", "مانجا ياباني"],
          ["ويب تون انجليزية", "ويب تون انجليزية"],
          ["مانهوا كورية", "مانهوا كورية"],
          ["ويب تون يابانية", "ويب تون يابانية"],
          ["عربي", "عربي"],
        ].map((x) => ({
          type_name: "SelectOption",
          name: x[0],
          value: x[1],
        })),
      },
      {
        type_name: "SelectFilter",
        name: "الحالة",
        values: [
          ["اختر الحالة", ""],
          ["مستمرة", "مستمرة"],
          ["متوقف", "متوقف"],
          ["مكتمل", "مكتمل"],
          ["قادم قريبًا", "قادم قريبًا"],
          ["متروك", "متروك"],
        ].map((x) => ({
          type_name: "SelectOption",
          name: x[0],
          value: x[1],
        })),
      },
      {
        type_name: "SelectFilter",
        name: "التصنيف",
        values: [
          ["اختر التصنيف", ""],
          ["أكشن", "أكشن"],
          ["إثارة", "إثارة"],
          ["إيسيكاي", "إيسيكاي"],
          ["بطل غير إعتيادي", "بطل غير إعتيادي"],
          ["خيال", "خيال"],
          ["دموي", "دموي"],
          ["نظام", "نظام"],
          ["صقل", "صقل"],
          ["قوة خارقة", "قوة خارقة"],
          ["فنون قتال", "فنون قتال"],
          ["غموض", "غموض"],
          ["وحوش", "وحوش"],
          ["شونين", "شونين"],
          ["حريم", "حريم"],
          ["خيال علمي", "خيال علمي"],
          ["مغامرات", "مغامرات"],
          ["دراما", "دراما"],
          ["خارق للطبيعة", "خارق للطبيعة"],
          ["سحر", "سحر"],
          ["كوميدي", "كوميدي"],
          ["ويب تون", "ويب تون"],
          ["زمكاني", "زمكاني"],
          ["رومانسي", "رومانسي"],
          ["شياطين", "شياطين"],
          ["فانتازيا", "فانتازيا"],
          ["عنف", "عنف"],
          ["ملائكة", "ملائكة"],
          ["بعد الكارثة", "بعد الكارثة"],
          ["إعادة إحياء", "إعادة إحياء"],
          ["اعمار", "اعمار"],
          ["ثأر", "ثأر"],
          ["زنزانات", "زنزانات"],
          ["تاريخي", "تاريخي"],
          ["حرب", "حرب"],
          ["خارق", "خارق"],
          ["سنين", "سنين"],
          ["عسكري", "عسكري"],
          ["بوليسي", "بوليسي"],
          ["حياة مدرسية", "حياة مدرسية"],
          ["واقع افتراضي", "واقع افتراضي"],
          ["داخل لعبة", "داخل لعبة"],
          ["داخل رواية", "داخل رواية"],
          ["الحياة اليومية", "الحياة اليومية"],
          ["رعب", "رعب"],
          ["طبخ", "طبخ"],
          ["مدرسي", "مدرسي"],
          ["زومبي", "زومبي"],
          ["شوجو", "شوجو"],
          ["معالج", "معالج"],
          ["شريحة من الحياة", "شريحة من الحياة"],
          ["نفسي", "نفسي"],
          ["تاريخ", "تاريخ"],
          ["أكاديمية", "أكاديمية"],
          ["أرواح", "أرواح"],
          ["تراجيدي", "تراجيدي"],
          ["ابراج", "ابراج"],
          ["رياضي", "رياضي"],
          ["مصاص دماء", "مصاص دماء"],
          ["طبي", "طبي"],
          ["مأساة", "مأساة"],
          ["إيتشي", "إيتشي"],
          ["انتقام", "انتقام"],
          ["جوسي", "جوسي"],
          ["موريم", "موريم"],
          ["لعبة فيديو", "لعبة فيديو"],
          ["مغني", "مغني"],
          ["تشويق", "تشويق"],
          ["نجاة", "نجاة"],
          ["الجانب المظلم من الحياة", "الجانب المظلم من الحياة"],
          ["سينين", "سينين"],
          ["تنمر", "تنمر"],
          ["حيوانات أليفة", "حيوانات أليفة"],
          ["شرطة", "شرطة"],
          ["الخيال العلمي", "الخيال العلمي"],
          ["حشرات", "حشرات"],
          ["عوالم", "عوالم"],
          ["ممالك", "ممالك"],
          ["مؤامرات", "مؤامرات"],
          ["تخطيط", "تخطيط"],
          ["سفر عبر الأبعاد", "سفر عبر الأبعاد"],
          ["جواسيس", "جواسيس"],
          ["بطل مخطط", "بطل مخطط"],
          ["ممثل", "ممثل"],
        ].map((x) => ({
          type_name: "SelectOption",
          name: x[0],
          value: x[1],
        })),
      },
    ];
  }

  getSourcePreferences() {
    return [
      {
        key: "overrideBaseUrl1",
        editTextPreference: {
          title: "Override BaseUrl",
          summary: "https://olympustaff.com",
          value: "https://olympustaff.com",
          dialogTitle: "Override BaseUrl",
          dialogMessage: "",
        },
      },
    ];
  }
}

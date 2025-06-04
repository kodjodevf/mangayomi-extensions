// prettier-ignore
const mangayomiSources = [{
    "name": "TeamX",
    "lang": "ar",
    "baseUrl": "https://olympustaff.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://olympustaff.com",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.3",
    "isNsfw": false,
    "pkgPath": "manga/src/ar/teamx.js"
}];

class DefaultExtension extends MProvider {
  //  Helper Methods
  toStatus(status) {
    return (
      {
        مستمرة: 0,
        مكتملة: 1,
        مكتمل: 1,
        متوقف: 2,
        متروك: 3,
        "قادم قريبًا": 4,
      }[status] ?? 5 // 5 => unknown
    );
  }

  hasNextPage(doc) {
    return (
      doc
        .selectFirst(".pagination li.page-item a[rel='next']")
        ?.attr("href") !== ""
    );
  }

  parseChapterDate(date) {
    return new Date(date).getTime().toString();
  }

  getBaseUrl() {
    const preference = new SharedPreferences();
    var base_url = preference.get("domain_url");
    if (base_url.length == 0) {
      return this.source.baseUrl;
    }
    if (base_url.endsWith("/")) {
      return base_url.slice(0, -1);
    }
    return base_url;
  }

  async request(slug, useBaseUrl = true) {
    const url = useBaseUrl ? `${this.getBaseUrl()}${slug}` : slug;
    if (!this.client) {
      this.client = new Client();
    }
    const res = await this.client.get(url);
    return new Document(res.body);
  }

  //  Manga Listing
  async getMangaList(slug) {
    const doc = await this.request(`/${slug}`);
    const list = doc.select(".listupd .bsx").map((element) => ({
      name: element.selectFirst("a")?.attr("title")?.trim(),
      imageUrl: element.selectFirst("img")?.getSrc,
      link: element.getHref,
    }));

    return { list, hasNextPage: this.hasNextPage(doc) };
  }

  async getPopular(page) {
    return this.getMangaList(`series?page=${page}`);
  }

  async getLatestUpdates(page) {
    const doc = await this.request(`/?page=${page}`);
    const list = doc.select(".post-body .box").map((element) => ({
      name: element.selectFirst(".info a h3")?.text,
      imageUrl: element.selectFirst(".imgu img")?.getSrc,
      link: element.selectFirst(".imgu a")?.getHref,
    }));

    return { list, hasNextPage: this.hasNextPage(doc) };
  }

  //  Search
  async search(query, page, filters) {
    if (!query) {
      const [type, status, genre] = filters.map(
        (filter, i) => filter.values[filters[i].state]?.value,
      );
      return this.getMangaList(
        `series?page=${page}&genre=${genre}&type=${type}&status=${status}`,
      );
    }

    const doc = await this.request(`/ajax/search?keyword=${query}`);
    const list = doc.select("li.list-group-item").map((element) => ({
      name: element.selectFirst("div.ms-2 a")?.text,
      imageUrl: element.selectFirst("a img")?.getSrc,
      link: element.selectFirst("div.ms-2 a")?.getHref,
    }));

    return { list, hasNextPage: false };
  }

  //  Chapters
  chapterFromElement(element) {
    const chpNum = element.selectFirst("div.epl-num")?.text.trim();
    const chpTitle = element.selectFirst("div.epl-title")?.text.trim();

    let name;
    if (chpTitle?.includes(chpNum?.replace(/[^0-9]/g, ""))) {
      name = chpTitle;
    } else if (!chpNum) {
      name = chpTitle;
    } else if (!chpTitle) {
      name = chpNum;
    } else {
      name = `${chpNum} - ${chpTitle}`;
    }

    return {
      name,
      dateUpload: this.parseChapterDate(
        element.selectFirst("div.epl-date")?.text.trim(),
      ),
      url: element.getHref,
    };
  }

  //  Detail
  async getDetail(url) {
    let doc = await this.request(url, false);

    const title = doc.selectFirst("div.author-info-title h1")?.text.trim();
    const imageUrl = doc.selectFirst("img.shadow-sm")?.getSrc;
    const description = doc.selectFirst(".review-content > p")?.text.trim();

    const author = doc
      .selectFirst(
        ".full-list-info > small:first-child:contains(الرسام) + small",
      )
      ?.text?.trim();

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

    const allElements = [];
    for (;;) {
      const pageChapters = doc.select("div.eplister ul a");
      if (!pageChapters || pageChapters.length === 0) break;
      allElements.push(...pageChapters);

      const nextPage = doc.select("a[rel=next]");
      if (!nextPage || nextPage.length === 0) break;

      const nextUrl = nextPage[0].attr("href");
      if (!nextUrl) break;

      doc = await this.request(nextUrl, false);
    }

    const chapters = allElements.map((element) =>
      this.chapterFromElement(element),
    );

    return {
      title,
      imageUrl,
      description,
      author: author && author !== "غير معروف" ? author : null,
      status,
      genre,
      chapters,
    };
  }

  //  chapter pages
  async getPageList(url) {
    const doc = await this.request(url, false);

    return doc.select("div.image_list img[src]").map((x) => ({
      url: x.attr("src"),
    }));
  }

  //  Filter
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

  //  Preferences
  getSourcePreferences() {
    return [
      {
        key: "domain_url",
        editTextPreference: {
          title: "Override BaseUrl",
          summary: "",
          value: "https://olympustaff.com",
          dialogTitle: "URL",
          dialogMessage: "",
        },
      },
    ];
  }
}

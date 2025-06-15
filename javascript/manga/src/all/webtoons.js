// prettier-ignore
const mangayomiSources = [{
    "name": "Webtoons",
    "langs": ["en", "fr", "id", "th", "es", "zh", "de"],
    "baseUrl": "https://www.webtoons.com",
    "apiUrl": "",
    "iconUrl": "https://upload.wikimedia.org/wikipedia/commons/0/09/Naver_Line_Webtoon_logo.png",
    "typeSource": "single",
    "isManga": true,
    "isNsfw": false,
    "version": "0.0.35",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/all/webtoons.js"
}];

class DefaultExtension extends MProvider {
  headers = {
    "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
  };
  getHeaders(url) {
    return {
      Referer: this.source.baseUrl,
    };
  }

  mangaFromElement(doc) {
    const list = [];
    for (const el of doc.select(
      `div.webtoon_list_wrap li a, ul.webtoon_list li a`,
    )) {
      const imageUrl = el.selectFirst("img").getSrc;
      const name = el.selectFirst("strong.title").text;
      const link = el.getHref;
      list.push({ name, imageUrl, link });
    }

    return list;
  }

  async getPopular(page) {
    const baseUrl = this.source.baseUrl;
    const res = await new Client().get(
      `${baseUrl}/${this.langCode()}/originals`,
    );
    const doc = new Document(res.body);

    return {
      list: this.mangaFromElement(doc),
      hasNextPage: false,
    };
  }

  async getLatestUpdates(page) {
    const baseUrl = this.source.baseUrl;
    const res = await new Client().get(
      `${baseUrl}/${this.langCode()}/originals?sortOrder=UPDATE`,
    );
    const doc = new Document(res.body);

    return {
      list: this.mangaFromElement(doc),
      hasNextPage: false,
    };
  }

  async search(query, page, filters) {
    const keyword = query.trim().replace(/\s+/g, "+");
    const baseurl = this.source.baseUrl;
    let url = `${baseurl}/${this.langCode()}`;
    let hasNextPage = false;

    const getFilterValue = (type, defaultValue = "") => {
      const filter = filters.find((f) => f.type === type);
      return filter?.values?.[filter.state]?.value ?? defaultValue;
    };
    if (query) {
      url += `/search/${getFilterValue("searchType")}?keyword=${keyword}&page=${page}`;
    } else {
      const sortOrder = getFilterValue("sortOrder");
      const rankingType = getFilterValue("rankingType");
      const weekday = getFilterValue("weekday");
      const genreType = getFilterValue("genre");

      if (rankingType) {
        // const genreParam = genreType ? `&subTabGenreCode=${genreType}` : "";
        url += `/ranking/${rankingType}`;
      } else if (weekday) {
        url += `/originals/${weekday}?sortOrder=${sortOrder}`;
      } else if (genreType) {
        url += `/genres/${genreType}?sortOrder=${sortOrder}`;
      }
    }

    const res = await new Client().get(url);
    const doc = new Document(res.body);
    const list = this.mangaFromElement(doc);
    if (query) {
      hasNextPage = list.length !== 0;
    }

    return {
      list,
      hasNextPage,
    };
  }

  async getDetail(url) {
    const res = await new Client().get(url);
    const doc = new Document(res.body);
    const info = doc.selectFirst("div.cont_box");

    const title = info.selectFirst("h1.subj, h3.subj").text.trim();
    const genre =
      Array.from(info.select("p.genre")).map((el) => el.text) != ""
        ? Array.from(info.select("p.genre")).map((el) => el.text)
        : [info.selectFirst("div.info h2").text];
    const author =
      info
        .selectFirst("div.author_area")
        .text.replace(/\s+/g, " ")
        .replace(/author info/g, "")
        .trim() ?? info.selectFirst("a.author").text;
    const status_str = info.selectFirst("p.day_info").text;
    var status;
    if (status_str == "COMPLETED") {
      status = 1;
    } else {
      status = 0;
    }
    const desc = info.selectFirst("p.summary").text.replace(/\s+/g, " ").trim();
    const chapters = [];
    let tester = "";
    let page = 1;

    while (tester !== "#1") {
      const res = await new Client().get(url + `&page=${page}`);
      const doc = new Document(res.body);
      const info = doc.selectFirst("div.cont_box");
      const elements = info.select("div.detail_lst li");

      for (const element of elements) {
        tester = element.selectFirst("span.tx").text.trim();
        const dateString = element.selectFirst("span.date").text.trim();
        const date = new Date(
          this.formatDateString(dateString, this.source.lang),
        );
        const millisecondsSinceEpoch = date.getTime();
        const millisecondsString = millisecondsSinceEpoch.toString();
        chapters.push({
          name: tester + " " + element.selectFirst("span.subj span").text,
          url: element.selectFirst("a").attr("href"),
          dateUpload: millisecondsString,
        });
      }
      page++;
    }
    return {
      name: title,
      link: url,
      genre: genre,
      description: desc,
      author: author,
      status: status,
      episodes: chapters,
    };
  }

  langCode() {
    return {
      en: "en",
      fr: "fr",
      id: "id",
      th: "th",
      es: "es",
      zh: "zh-hant",
      de: "de",
    }[this.source.lang];
  }

  formatDateString(dateStr, lang) {
    // Month translations for supported languages
    const monthTranslations = {
      en: [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ],
      fr: [
        "janv.",
        "févr.",
        "mars",
        "avr.",
        "mai",
        "juin",
        "juil.",
        "août",
        "sept.",
        "oct.",
        "nov.",
        "déc.",
      ],
      id: [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "Mei",
        "Jun",
        "Jul",
        "Agt",
        "Sep",
        "Okt",
        "Nov",
        "Des",
      ],
      th: [
        "ม.ค.",
        "ก.พ.",
        "มี.ค.",
        "เม.ย.",
        "พ.ค.",
        "มิ.ย.",
        "ก.ค.",
        "ส.ค.",
        "ก.ย.",
        "ต.ค.",
        "พ.ย.",
        "ธ.ค.",
      ],
      es: [
        "ene.",
        "feb.",
        "mar.",
        "abr.",
        "may.",
        "jun.",
        "jul.",
        "ago.",
        "sep.",
        "oct.",
        "nov.",
        "dic.",
      ],
      zh: [], // No need for month names; uses yyyy年MM月dd日 format
      de: [], // No need for month names; uses dd.MM.yyyy format
    };
    const months = monthTranslations[lang];
    let parts;
    let month;
    let day;
    let year;
    // Handle formats based on the language
    switch (lang) {
      case "zh":
        // Expected format: yyyy年MM月dd日
        const match = dateStr.match(/(\d{4})年(\d{1,2})月(\d{1,2})日/);
        year = match[1];
        month = match[2];
        day = match[3];
      case "de":
        // Expected format: dd.MM.yyyy
        parts = dateStr.split(".");
        if (parts.length === 3) {
          month = parts[1];
          day = parts[0];
          year = parts[2];
        }
      case "es":
      case "fr":
      case "id":
      case "th":
        // Expected format: dd MMM yyyy
        parts = dateStr.split(" ");
        if (parts.length === 3) {
          month = months.indexOf(parts[1]) + 1;
          day = parts[0];
          year = parts[2];
        }
        break;
      default:
        parts = dateStr.split(" ");
        if (parts.length === 3) {
          month = months.indexOf(parts[0]) + 1;
          day = parts[1].replace(",", "");
          year = parts[2];
        }
    }
    if (!month || !year || !day) {
      return Date.now();
    }
    return `${year}-${month.toString().padStart(2, "0")}-${day.toString().padStart(2, "0")}`;
  }

  async getPageList(url) {
    const res = await new Client().get(url);
    const doc = new Document(res.body);
    const urls = [];
    const imageElement = doc.selectFirst("div#_imageList");
    const img_urls = imageElement.select("img");
    for (let i = 0; i < img_urls.length; i++) {
      urls.push(img_urls[i].attr("data-url"));
    }
    return urls;
  }

  getFilterList() {
    return [
      {
        type: "searchType",
        name: "Search Type",
        type_name: "SelectFilter",
        values: [
          {
            type_name: "SelectOption",
            name: "Originals",
            value: "originals",
          },
          {
            type_name: "SelectOption",
            name: "Canvas",
            value: "canvas",
          },
        ],
        state: 0,
      },
      {
        type: "separator",
        type_name: "SeparatorFilter",
      },

      {
        type: "rankingType",
        name: "Ranking Category",
        type_name: "SelectFilter",
        values: [
          {
            type_name: "SelectOption",
            name: "Not Selected",
            value: "",
          },
          {
            type_name: "SelectOption",
            name: "Trending",
            value: "trending",
          },
          {
            type_name: "SelectOption",
            name: "Popular",
            value: "popular",
          },
          {
            type_name: "SelectOption",
            name: "Originals",
            value: "originals",
          },
          {
            type_name: "SelectOption",
            name: "Canvas",
            value: "canvas",
          },
        ],
      },
      {
        type: "separator",
        type_name: "SeparatorFilter",
      },

      {
        type: "sortOrder",
        name: "Sort By (For Schedule & Genres)",
        type_name: "SelectFilter",
        values: [
          { type_name: "SelectOption", name: "Popular (MANA)", value: "MANA" },
          { type_name: "SelectOption", name: "Likes", value: "LIKEIT" },
          { type_name: "SelectOption", name: "Newest", value: "UPDATE" },
        ],
        state: 0,
        appliesTo: ["weekday", "genre"],
      },

      {
        type: "separator",
        type_name: "SeparatorFilter",
      },

      {
        type: "weekday",
        name: "Update Schedule",
        type_name: "SelectFilter",
        values: [
          {
            type_name: "SelectOption",
            name: "Day",
            value: "",
            data: "",
          },
          {
            type_name: "SelectOption",
            name: "Monday",
            value: "monday",
            data: "MONDAY",
          },
          {
            type_name: "SelectOption",
            name: "Tuesday",
            value: "tuesday",
            data: "TUESDAY",
          },
          {
            type_name: "SelectOption",
            name: "Wednesday",
            value: "wednesday",
            data: "WEDNESDAY",
          },
          {
            type_name: "SelectOption",
            name: "Thursday",
            value: "thursday",
            data: "THURSDAY",
          },
          {
            type_name: "SelectOption",
            name: "Friday",
            value: "friday",
            data: "FRIDAY",
          },
          {
            type_name: "SelectOption",
            name: "Saturday",
            value: "saturday",
            data: "SATURDAY",
          },
          {
            type_name: "SelectOption",
            name: "Sunday",
            value: "sunday",
            data: "SUNDAY",
          },
          {
            type_name: "SelectOption",
            name: "Completed",
            value: "complete",
            data: "COMPLETE",
          },
        ],
      },

      {
        type: "genre",
        name: "Genre",
        type_name: "SelectFilter",
        values: [
          {
            type_name: "SelectOption",
            name: "All Genres",
            value: "",
            data: "",
          },
          {
            type_name: "SelectOption",
            name: "Drama",
            value: "drama",
            data: "DRAMA",
          },
          {
            type_name: "SelectOption",
            name: "Fantasy",
            value: "fantasy",
            data: "FANTASY",
          },
          {
            type_name: "SelectOption",
            name: "Comedy",
            value: "comedy",
            data: "COMEDY",
          },
          {
            type_name: "SelectOption",
            name: "Action",
            value: "action",
            data: "ACTION",
          },
          {
            type_name: "SelectOption",
            name: "Slice of Life",
            value: "slice_of_life",
            data: "SLICE_OF_LIFE",
          },
          {
            type_name: "SelectOption",
            name: "Romance",
            value: "romance",
            data: "ROMANCE",
          },
          {
            type_name: "SelectOption",
            name: "Superhero",
            value: "super_hero",
            data: "SUPER_HERO",
          },
          {
            type_name: "SelectOption",
            name: "Sci-Fi",
            value: "sf",
            data: "SF",
          },
          {
            type_name: "SelectOption",
            name: "Thriller",
            value: "thriller",
            data: "THRILLER",
          },
          {
            type_name: "SelectOption",
            name: "Supernatural",
            value: "supernatural",
            data: "SUPERNATURAL",
          },
          {
            type_name: "SelectOption",
            name: "Mystery",
            value: "mystery",
            data: "MYSTERY",
          },
          {
            type_name: "SelectOption",
            name: "Sports",
            value: "sports",
            data: "SPORTS",
          },
          {
            type_name: "SelectOption",
            name: "Historical",
            value: "historical",
            data: "HISTORICAL",
          },
          {
            type_name: "SelectOption",
            name: "Heartwarming",
            value: "heartwarming",
            data: "HEARTWARMING",
          },
          {
            type_name: "SelectOption",
            name: "Horror",
            value: "horror",
            data: "HORROR",
          },
          {
            type_name: "SelectOption",
            name: "Graphic Novel",
            value: "graphic_novel",
            data: "GRAPHIC_NOVEL",
          },
          {
            type_name: "SelectOption",
            name: "Informative",
            value: "tiptoon",
            data: "TIPTOON",
          },
        ],
      },
    ];
  }
}

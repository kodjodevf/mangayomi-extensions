const mangayomiSources = [{
    "name": "Njav",
    "lang": "all",
    "baseUrl": "https://njav.tv/en",
    "apiUrl": "",
    "iconUrl": "https://njav.tv/assets/njav/images/favicon.png",
    "typeSource": "single",
    "isManga": false,
    "isNsfw": true,
    "version": "0.0.1",
    "apiUrl": "",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgName": "anime/src/all/njav.js"
  }];
  
  class DefaultExtension extends MProvider {
    dateStringToTimestamp(dateString) {
      var parts = dateString.split('-');
      var year = parseInt(parts[0]);
      var month = parseInt(parts[1]) - 1;
      var day = parseInt(parts[2]);
      var date = new Date(year, month, day);
      var timestamp = date.getTime();
      return timestamp;
    }
  
    async request(url) {
      const preference = new SharedPreferences();
      const res = await new Client().get(preference.get("url") + "/" + preference.get("lang") + url);
      return res.body;
    }
  
    async getItems(url) {
      const res = await this.request(url);
      const doc = new Document(res);
      const elements = doc.select("div.box-item");
      const items = [];
      for (const element of elements) {
        const cover = element.selectFirst("img").attr("data-src");
        const info = element.selectFirst("div.detail a");
        const url = info.attr("href");
        const title = info.text;
        items.push({
          link: "/" + url,
          imageUrl: cover,
          name: title
        });
      }
      return {
        list: items,
        hasNextPage: true
      }
    }
  
    async getPopular(page) {
      return await this.getItems(`/trending?page=${page}`);
    }
  
    async getLatestUpdates(page) {
      return await this.getItems(`/new-release?page=${page}`);
    }
  
    async search(query, page, filters) {
      if (query == "") {
        var category, sort;
        for (const filter of filters) {
          if (filter["type"] == "CateFilter") {
            category = filter["values"][filter["state"]]["value"];
          } else if (filter["type"] == "SortFilter") {
            sort = filter["values"][filter["state"]]["value"];
          }
        }
        return await this.getItems(`/${category}?sort=${sort}&page=${page}`);
      } else {
        return await this.getItems(`/search?keyword=${query}&page=${page}`);
      }
    }
  
    async getEpisodes(id, time) {
      const res = await this.request(`/ajax/v/${id}/videos`);
      const datas = JSON.parse(res);
      const ep = [];
      for (const data of datas["data"]["watch"]) {
        ep.push({
          name: data["name"],
          url: data["url"],
          dateUpload: time.toString()
        });
      }
      return ep;
    }
  
    async getDetail(url) {
      const res = await this.request(url);
      const doc = new Document(res);
      const body = doc.selectFirst("div#body");
      const title = body.selectFirst("h1").text;
      const cover = body.selectFirst("div#player").attr("data-poster");
      const info = body.selectFirst("div.detail-item").select("div");
      var desc;
      try {
        desc = body.selectFirst("div.description p").text;
      } catch {
        desc = "";
      }
      const updateTime = this.dateStringToTimestamp(info[1].select("span")[1].text);
      var author;
      try {
        author = info[3].select("span")[1].text.replaceAll("\n", "");
      } catch {
        author = "Unknown";
      }
      var genres
      try {
        genres = info[4].selectFirst("span.genre").select("a").map(e => e.text);
      } catch {
        genres = [];
      }
      const id = body.selectFirst("div.container").attr("v-scope").slice(12, -3);
      const eps = await this.getEpisodes(id, updateTime);
      return {
        name: title,
        imageUrl: cover,
        author: author,
        genre: genres,
        description: desc,
        episodes: eps
      };
    }
  
    async getVideoList(url) {
      const res = await new Client().get(url);
      const doc = new Document(res.body);
      const str = doc.selectFirst("div#player").attr("v-scope").match(/, {([^']*)\)/)[1];
      const data = JSON.parse("{" + str);
      return [{
        url: data["stream"],
        originalUrl: data["stream"],
        quality: "Origin",
        headers: {
          Referer: "https://javplayer.me/",
          Origin: "https://javplayer.me"
        }
      }];
    }
  
    getFilterList() {
      return [{
          "type": "CateFilter",
          "type_name": "SelectFilter",
          "name": "Category",
          "values": [{
              "value": "recommended",
              "name": "Recommended",
              "type_name": "SelectOption"
            },
            {
              "value": "censored",
              "name": "Censored",
              "type_name": "SelectOption"
            },
            {
              "value": "uncensored",
              "name": "Uncensored",
              "type_name": "SelectOption"
            },
            {
              "value": "uncensored-leaked",
              "name": "Uncensored Leaked",
              "type_name": "SelectOption"
            },
            {
              "value": "vr",
              "name": "VR",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/fc2",
              "name": "FC2",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/heyzo",
              "name": "HEYZO",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/tokyo-hot",
              "name": "Tokyo-Hot",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/1pondo",
              "name": "1pondo",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/caribbeancom",
              "name": "Caribbeancom",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/caribbeancompr",
              "name": "Caribbeancompr",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/10musume",
              "name": "10musume",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/pacopacomama",
              "name": "pacopacomama",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/gachig",
              "name": "Gachinco",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/xxx-av",
              "name": "XXX-AV",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/c0930",
              "name": "C0930",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/h4610",
              "name": "H4610",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/h0930",
              "name": "H0930",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/siro",
              "name": "SIRO",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/259luxu",
              "name": "LUXU",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/200gana",
              "name": "200GANA",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/prestige-premium",
              "name": "PRESTIGE PREMIUM",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/s-cute",
              "name": "S-CUTE",
              "type_name": "SelectOption"
            },
            {
              "value": "tags/261ara",
              "name": "ARA",
              "type_name": "SelectOption"
            }
          ]
        },
        {
          "type": "SortFilter",
          "type_name": "SelectFilter",
          "name": "Sort",
          "values": [{
              "value": "recent_update",
              "name": "Recent Update",
              "type_name": "SelectOption"
            },
            {
              "value": "release_date",
              "name": "Release date",
              "type_name": "SelectOption"
            },
            {
              "value": "trending",
              "name": "Trending",
              "type_name": "SelectOption"
            },
            {
              "value": "most_viewed_today",
              "name": "Most viewed today",
              "type_name": "SelectOption"
            },
            {
              "value": "most_viewed_week",
              "name": "Most viewed by week",
              "type_name": "SelectOption"
            },
            {
              "value": "most_viewed_month",
              "name": "Most viewed by month",
              "type_name": "SelectOption"
            },
            {
              "value": "most_viewed",
              "name": "Most viewed",
              "type_name": "SelectOption"
            }, {
              "value": "most_favourited",
              "name": "Most favourited",
              "type_name": "SelectOption"
            }
          ]
        }
      ];
  
    }
  
    getSourcePreferences() {
      return [{
          "key": "lang",
          "listPreference": {
            "title": "Language",
            "summary": "",
            "valueIndex": 0,
            "entries": ["English", "繁體中文", "日本語", "한국의", "Melayu", "ไทย", "Deutsch", "Français", "Tiếng Việt"],
            "entryValues": ["en", "zh", "ja", "ko", "ms", "th", "de", "fr", "vi"],
          }
        },
        {
          "key": "url",
          "listPreference": {
            "title": "Website Url",
            "summary": "",
            "valueIndex": 0,
            "entries": ["njav", "missav", "javgo", "supjav"],
            "entryValues": ["https://njav.xyz", "https://missav.li", "https://www.javgo.to", "https://supjav.pro"],
          }
        }
      ];
    }
  }

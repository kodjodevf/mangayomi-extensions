const mangayomiSources = [{
  "name": "樱花动漫",
  "lang": "zh",
  "baseUrl": "http://www.iyinghua.com",
  "apiUrl": "",
  "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.yhdm.png",
  "typeSource": "single",
  "itemType": 1,
  "isNsfw": false,
  "version": "0.0.2",
  "dateFormat": "",
  "dateFormatLocale": "",
  "pkgPath": "anime/src/zh/yhdm.js"
}];

class DefaultExtension extends MProvider {
  stringUTF8(text, d) {
    if (!d) {
      return text;
    }
    var bytes = [];
    for (var i = 0; i < text.length; i++) {
      bytes.push(text.charCodeAt(i));
    }
    var charCodes = [];
    var i = 0;
    while (i < bytes.length) {
      var byte1 = bytes[i];
      var charCode;
      if (byte1 < 0x80) {
        charCode = byte1;
        i += 1;
      } else if (byte1 < 0xE0) {
        var byte2 = bytes[i + 1];
        charCode = ((byte1 & 0x1F) << 6) | (byte2 & 0x3F);
        i += 2;
      } else if (byte1 < 0xF0) {
        var byte2 = bytes[i + 1];
        var byte3 = bytes[i + 2];
        charCode = ((byte1 & 0x0F) << 12) | ((byte2 & 0x3F) << 6) | (byte3 & 0x3F);
        i += 3;
      } else {
        var byte2 = bytes[i + 1];
        var byte3 = bytes[i + 2];
        var byte4 = bytes[i + 3];
        charCode = ((byte1 & 0x07) << 18) | ((byte2 & 0x3F) << 12) | ((byte3 & 0x3F) << 6) | (byte4 & 0x3F);
        i += 4;
      }
      charCodes.push(charCode);
    }
    return String.fromCharCode.apply(null, charCodes);
  }

  getBaseUrl() {
    const preference = new SharedPreferences();
    var base_url = preference.get("domain_url");
    if (base_url.endsWith("/")) {
      return base_url.slice(0, -1);
    }
    return base_url;
  }

  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  async getItems(url, p, d) {
    const res = await new Client().get(this.getBaseUrl() + url);
    const doc = new Document(res.body);
    const items = [];
    const elements = doc.select(p);
    for (const element of elements) {
      items.push({
        name: this.stringUTF8(element.selectFirst("img").attr("alt"), d),
        imageUrl: element.selectFirst("img").attr("src"),
        link: element.selectFirst("a").attr("href")
      });
    }
    return {
      list: items,
      hasNextPage: true
    };
  }

  async getPopular(page) {
    const results = await this.getItems("", "div.img li", true);
    results["hasNextPage"] = false;
    return results;
  }

  async getLatestUpdates(page) {
    return await this.getItems(`/${new Date().getFullYear()}/${(page == 1)? "":page.toString()+".html"}`, "div.lpic li", true);
  }

  async search(query, page, filters) {
    if (query) {
      return await this.getItems(`/search/${query}/?page=${page}`, "div.lpic li", false);
    }
    return await this.getItems(filters[0]["values"][filters[0]["state"]]["value"] + ((page == 1) ? "" : page.toString() + ".html"), "div.lpic li", true);
  }

  async getDetail(url) {
    const res = await new Client().get(this.getBaseUrl() + url);
    const doc = new Document(res.body);
    const cover = doc.selectFirst("div.thumb img").attr("src");
    const title = this.stringUTF8(doc.selectFirst("div.rate h1").text, true);
    const genre = doc.select("div.sinfo a").map(e => this.stringUTF8(e.text, true));
    genre.splice(-1);
    const desc = this.stringUTF8(doc.selectFirst("div.info").text, true);
    const eps = [];
    const elements = doc.select("div.movurl a");
    for (const element of elements) {
      eps.push({
        name: this.stringUTF8(element.text, true),
        url: element.attr("href")
      });
    }
    if (eps[0]["url"].search("-1.html") != -1) {
      eps.reverse();
    }
    return {
      name: title,
      imageUrl: cover,
      description: desc,
      genre: genre,
      episodes: eps
    };
  }

  async getVideoList(url) {
    const res = await new Client().get(this.getBaseUrl() + url);
    const doc = new Document(res.body);
    const video_url = this.stringUTF8(doc.selectFirst("div#playbox").attr("data-vid").split("$")[0], true);
    return [{
      url: video_url,
      originalUrl: video_url,
      quality: "Origin"
    }];
  }

  getFilterList() {
    return [{
      type: "Select",
      type_name: "SelectFilter",
      name: "分类",
      values: [{
          name: "2024",
          value: "/2024/",
          type_name: "SelectOption"
        },
        {
          name: "2023",
          value: "/2023/",
          type_name: "SelectOption"
        },
        {
          name: "2022",
          value: "/2022/",
          type_name: "SelectOption"
        },
        {
          name: "2021",
          value: "/2021/",
          type_name: "SelectOption"
        },
        {
          name: "2020",
          value: "/2020/",
          type_name: "SelectOption"
        },
        {
          name: "2019",
          value: "/2019/",
          type_name: "SelectOption"
        },
        {
          name: "2018",
          value: "/2018/",
          type_name: "SelectOption"
        },
        {
          name: "2017",
          value: "/2017/",
          type_name: "SelectOption"
        },
        {
          name: "2016",
          value: "/2016/",
          type_name: "SelectOption"
        },
        {
          name: "2015",
          value: "/2015/",
          type_name: "SelectOption"
        },
        {
          name: "日本",
          value: "/japan/",
          type_name: "SelectOption"
        },
        {
          name: "大陆",
          value: "/china/",
          type_name: "SelectOption"
        },
        {
          name: "美国",
          value: "/american/",
          type_name: "SelectOption"
        },
        {
          name: "英国",
          value: "/england/",
          type_name: "SelectOption"
        },
        {
          name: "韩国",
          value: "/korea/",
          type_name: "SelectOption"
        },
        {
          name: "日语",
          value: "/29/",
          type_name: "SelectOption"
        },
        {
          name: "国语",
          value: "/30/",
          type_name: "SelectOption"
        },
        {
          name: "粤语",
          value: "/31/",
          type_name: "SelectOption"
        },
        {
          name: "英语",
          value: "/32/",
          type_name: "SelectOption"
        },
        {
          name: "韩语",
          value: "/33/",
          type_name: "SelectOption"
        },
        {
          name: "方言",
          value: "/34/",
          type_name: "SelectOption"
        },
        {
          name: "热血",
          value: "/66/",
          type_name: "SelectOption"
        },
        {
          name: "格斗",
          value: "/64/",
          type_name: "SelectOption"
        },
        {
          name: "恋爱",
          value: "/91/",
          type_name: "SelectOption"
        },
        {
          name: "校园",
          value: "/70/",
          type_name: "SelectOption"
        },
        {
          name: "搞笑",
          value: "/67/",
          type_name: "SelectOption"
        },
        {
          name: "LOLI",
          value: "/111/",
          type_name: "SelectOption"
        },
        {
          name: "神魔",
          value: "/83/",
          type_name: "SelectOption"
        },
        {
          name: "机战",
          value: "/81/",
          type_name: "SelectOption"
        },
        {
          name: "科幻",
          value: "/75/",
          type_name: "SelectOption"
        },
        {
          name: "真人",
          value: "/74/",
          type_name: "SelectOption"
        },
        {
          name: "青春",
          value: "/84/",
          type_name: "SelectOption"
        },
        {
          name: "魔法",
          value: "/73/",
          type_name: "SelectOption"
        },
        {
          name: "美少女",
          value: "/72/",
          type_name: "SelectOption"
        },
        {
          name: "神话",
          value: "/102/",
          type_name: "SelectOption"
        },
        {
          name: "冒险",
          value: "/61/",
          type_name: "SelectOption"
        },
        {
          name: "运动",
          value: "/69/",
          type_name: "SelectOption"
        },
        {
          name: "竞技",
          value: "/62/",
          type_name: "SelectOption"
        },
        {
          name: "童话",
          value: "/103/",
          type_name: "SelectOption"
        },
        {
          name: "励志",
          value: "/85/",
          type_name: "SelectOption"
        },
        {
          name: "后宫",
          value: "/99/",
          type_name: "SelectOption"
        },
        {
          name: "战争",
          value: "/80/",
          type_name: "SelectOption"
        },
        {
          name: "吸血鬼",
          value: "/119/",
          type_name: "SelectOption"
        }
      ]
    }];
  }

  getSourcePreferences() {
    return [{
        "key": "domain_url",
        "editTextPreference": {
          "title": "Url",
          "summary": "樱花动漫网址",
          "value": "http://www.iyinghua.com",
          "dialogTitle": "URL",
          "dialogMessage": "",
        }
      }
    ];
  }
}
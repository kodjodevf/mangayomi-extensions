const mangayomiSources = [{
  "name": "漫画DB",
  "lang": "zh",
  "baseUrl": "https://www.manhuadb.com",
  "apiUrl": "",
  "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.manhuadb.png",
  "typeSource": "single",
  "isManga": true,
  "isNsfw": false,
  "version": "0.0.25",
  "dateFormat": "",
  "dateFormatLocale": "",
  "pkgPath": "manga/src/zh/manhuadb.js"
}];

class DefaultExtension extends MProvider {
  base64decode(str) {
    var base64DecodeChars = new Array(-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1);
    var c1, c2, c3, c4;
    var i, len, out;
    len = str.length;
    i = 0;
    out = "";
    while (i < len) {
      do {
        c1 = base64DecodeChars[str.charCodeAt(i++) & 0xff]
      } while (i < len && c1 == -1);
      if (c1 == -1)
        break;
      do {
        c2 = base64DecodeChars[str.charCodeAt(i++) & 0xff]
      } while (i < len && c2 == -1);
      if (c2 == -1)
        break;
      out += String.fromCharCode((c1 << 2) | ((c2 & 0x30) >> 4));
      do {
        c3 = str.charCodeAt(i++) & 0xff;
        if (c3 == 61)
          return out;
        c3 = base64DecodeChars[c3]
      } while (i < len && c3 == -1);
      if (c3 == -1)
        break;
      out += String.fromCharCode(((c2 & 0XF) << 4) | ((c3 & 0x3C) >> 2));
      do {
        c4 = str.charCodeAt(i++) & 0xff;
        if (c4 == 61)
          return out;
        c4 = base64DecodeChars[c4]
      } while (i < len && c4 == -1);
      if (c4 == -1)
        break;
      out += String.fromCharCode(((c3 & 0x03) << 6) | c4)
    }
    return out
  }

  coverUrlConvert(cover_url) {
    if (cover_url.search("com") == -1) {
      return this.source.baseUrl + cover_url;
    }
    return cover_url;
  }

  async getMangas(url, search) {
    const res = await new Client().get(this.source.baseUrl + url);
    const doc = new Document(res.body);
    var str;
    if (search) {
      str = "div.comicbook-index";
    } else {
      str = "div.media";
    }
    const items = doc.select(str);
    const mangas = [];
    for (const item of items) {
      const cover = this.coverUrlConvert(item.selectFirst("a.d-block img").attr("src"));
      var title;
      if (search) {
        title = item.selectFirst("a.d-block").attr("title");
      } else {
        title = item.selectFirst("a.d-block img").attr("alt");
        title = title.replace("的封面图", "");
      }
      const url = item.selectFirst("a.d-block").attr("href");
      mangas.push({
        name: title,
        link: url,
        imageUrl: cover
      });
    }
    return {
      list: mangas,
      hasNextPage: true
    }
  }

  async getPopular(page) {
    const res = await new Client().get(this.source.baseUrl);
    const doc = new Document(res.body);
    const items = doc.select("div.comicbook-index");
    var mangas = [];
    for (let item of items) {
      const cover = this.coverUrlConvert(item.selectFirst("a img").attr("src"));
      const title = item.selectFirst("a img").attr("alt");
      const url = item.selectFirst("a").attr("href")
      mangas.push({
        name: title.replace("封面", ""),
        link: url,
        imageUrl: cover
      });
    }
    return {
      list: mangas,
      hasNextPage: false
    };
  }

  async getLatestUpdates(page) {
    return await this.getMangas(`/manhua/list-page-${page}.html`, false);
  }

  async search(query, page, filters) {
    if (query == "") {
      var locations, readers, status, categories;
      for (const filter of filters) {
        if (filter["type"] == "locations") {
          locations = filter["values"][filter["state"]]["value"];
        } else if (filter["type"] == "readers") {
          readers = filter["values"][filter["state"]]["value"];
        } else if (filter["type"] == "status") {
          status = filter["values"][filter["state"]]["value"];
        } else if (filter["type"] == "categories") {
          categories = filter["values"][filter["state"]]["value"];
        }
      }
      const url = `/manhua/list${locations}${readers}${status}${categories}-page-${page}.html`;
      return await this.getMangas(url.replaceAll("all", ""), false);
    } else {
      return await this.getMangas(`/search?q=${query}&p=${page}`, true);
    }
  }

  async getDetail(url) {
    const res = await new Client().get(this.source.baseUrl + url);
    const doc = new Document(res.body);
    const title = doc.selectFirst("h1.comic-title").text;
    const cover = this.coverUrlConvert(doc.selectFirst("td.comic-cover img").attr("src"));
    const desc = doc.selectFirst("p.comic_story").text;
    const author = doc.selectFirst("ul.creators a").text;
    var tags = doc.select("ul.tags a").map(e => e.text);
    var status = 5;
    if (tags[0] == "已完结") {
      status = 1;
      tags.shift();
    }
    if (tags[0] == "连载中") {
      status = 0;
      tags.shift();
    }
    const items = doc.select("ol.links-of-books");
    const episodes = [];
    const ep_names = doc.select("span.h3");
    const ep_titles = [];
    for (const ep_name of ep_names) {
      ep_titles.push(ep_name.text);
    }
    var index = 0;
    for (const lists of items) {
      const chapters = lists.select("li");
      for (const chapter of chapters) {
        const name = chapter.selectFirst("a").attr("title");
        const url = chapter.selectFirst("a").attr("href");
        episodes.push({
          name: `[[${ep_titles[index]}]]${name}`,
          url: url
        });
      }
      index = index + 1;
    }
    episodes.reverse();
    return {
      name: title,
      imageUrl: cover,
      description: desc,
      episodes: episodes,
      genre: tags,
      author: author,
      status: status
    };
  }

  async getPageList(url) {
    const res = await new Client().get(this.source.baseUrl + url);
    const html = res.body;
    const doc = new Document(html);
    const urls = [];
    var script_str = html.match(/<script>var img_data = '([^']*)';<\/script>/)[1];
    const img_urls = JSON.parse(this.base64decode(script_str));
    var img_base = doc.selectFirst("img.show-pic").attr("src");
    img_base = img_base.substring(0, img_base.search(img_urls[0]['img']));
    for (const url of img_urls) {
      urls.push(img_base + url['img']);
    }
    return urls;
  }

  getFilterList() {
    return [{
        type: "locations",
        name: "地区",
        type_name: "SelectFilter",
        values: [{
            value: "all",
            name: "全部",
            type_name: "SelectOption"
          },
          {
            value: "-r-4",
            name: "日本",
            type_name: "SelectOption"
          },
          {
            value: "-r-5",
            name: "香港",
            type_name: "SelectOption"
          },
          {
            value: "-r-6",
            name: "韩国",
            type_name: "SelectOption"
          },
          {
            value: "-r-7",
            name: "台湾",
            type_name: "SelectOption"
          },
          {
            value: "-r-8",
            name: "内地",
            type_name: "SelectOption"
          },
          {
            value: "-r-9",
            name: "欧美",
            type_name: "SelectOption"
          }
        ]
      },
      {
        type: "readers",
        name: "读者",
        type_name: "SelectFilter",
        values: [{
            value: "all",
            name: "全部",
            type_name: "SelectOption"
          },
          {
            value: "-a-3",
            name: "少年",
            type_name: "SelectOption"
          },
          {
            value: "-a-4",
            name: "青年",
            type_name: "SelectOption"
          },
          {
            value: "-a-5",
            name: "少女",
            type_name: "SelectOption"
          },
          {
            value: "-a-6",
            name: "男性",
            type_name: "SelectOption"
          },
          {
            value: "-a-7",
            name: "女性",
            type_name: "SelectOption"
          },
          {
            value: "-a-9",
            name: "通用",
            type_name: "SelectOption"
          },
          {
            value: "-a-10",
            name: "儿童",
            type_name: "SelectOption"
          },
          {
            value: "-a-11",
            name: "女青",
            type_name: "SelectOption"
          },
          {
            value: "-a-12",
            name: "18限",
            type_name: "SelectOption"
          }
        ]
      },
      {
        type: "status",
        name: "状态",
        type_name: "SelectFilter",
        values: [{
            value: "all",
            name: "全部",
            type_name: "SelectOption"
          },
          {
            value: "-s-1",
            name: "连载中",
            type_name: "SelectOption"
          },
          {
            value: "-s-2",
            name: "已完结",
            type_name: "SelectOption"
          }
        ]
      },
      {
        type: "categories",
        name: "类型",
        type_name: "SelectFilter",
        values: [{
            value: "all",
            name: "全部",
            type_name: "SelectOption"
          },
          {
            value: "-c-26",
            name: "爱情",
            type_name: "SelectOption"
          },
          {
            value: "-c-66",
            name: "东方",
            type_name: "SelectOption"
          },
          {
            value: "-c-12",
            name: "冒险",
            type_name: "SelectOption"
          },
          {
            value: "-c-64",
            name: "欢乐向",
            type_name: "SelectOption"
          },
          {
            value: "-c-39",
            name: "百合",
            type_name: "SelectOption"
          },
          {
            value: "-c-41",
            name: "搞笑",
            type_name: "SelectOption"
          },
          {
            value: "-c-20",
            name: "科幻",
            type_name: "SelectOption"
          },
          {
            value: "-c-40",
            name: "校园",
            type_name: "SelectOption"
          },
          {
            value: "-c-33",
            name: "生活",
            type_name: "SelectOption"
          },
          {
            value: "-c-48",
            name: "魔幻",
            type_name: "SelectOption"
          },
          {
            value: "-c-13",
            name: "奇幻",
            type_name: "SelectOption"
          },
          {
            value: "-c-46",
            name: "热血",
            type_name: "SelectOption"
          },
          {
            value: "-c-44",
            name: "格斗",
            type_name: "SelectOption"
          },
          {
            value: "-c-71",
            name: "其他",
            type_name: "SelectOption"
          },
          {
            value: "-c-52",
            name: "神鬼",
            type_name: "SelectOption"
          },
          {
            value: "-c-43",
            name: "魔法",
            type_name: "SelectOption"
          },
          {
            value: "-c-27",
            name: "悬疑",
            type_name: "SelectOption"
          },
          {
            value: "-c-18",
            name: "动作",
            type_name: "SelectOption"
          },
          {
            value: "-c-55",
            name: "竞技",
            type_name: "SelectOption"
          },
          {
            value: "-c-72",
            name: "纯爱",
            type_name: "SelectOption"
          },
          {
            value: "-c-32",
            name: "喜剧",
            type_name: "SelectOption"
          },
          {
            value: "-c-59",
            name: "萌系",
            type_name: "SelectOption"
          },
          {
            value: "-c-16",
            name: "恐怖",
            type_name: "SelectOption"
          },
          {
            value: "-c-53",
            name: "耽美",
            type_name: "SelectOption"
          },
          {
            value: "-c-56",
            name: "四格",
            type_name: "SelectOption"
          },
          {
            value: "-c-80",
            name: "ゆり",
            type_name: "SelectOption"
          },
          {
            value: "-c-54",
            name: "治愈",
            type_name: "SelectOption"
          },
          {
            value: "-c-60",
            name: "伪娘",
            type_name: "SelectOption"
          },
          {
            value: "-c-73",
            name: "舰娘",
            type_name: "SelectOption"
          },
          {
            value: "-c-47",
            name: "励志",
            type_name: "SelectOption"
          },
          {
            value: "-c-58",
            name: "职场",
            type_name: "SelectOption"
          },
          {
            value: "-c-30",
            name: "战争",
            type_name: "SelectOption"
          },
          {
            value: "-c-51",
            name: "侦探",
            type_name: "SelectOption"
          },
          {
            value: "-c-21",
            name: "惊悚",
            type_name: "SelectOption"
          },
          {
            value: "-c-22",
            name: "职业",
            type_name: "SelectOption"
          },
          {
            value: "-c-9",
            name: "历史",
            type_name: "SelectOption"
          },
          {
            value: "-c-11",
            name: "体育",
            type_name: "SelectOption"
          },
          {
            value: "-c-45",
            name: "美食",
            type_name: "SelectOption"
          },
          {
            value: "-c-68",
            name: "秀吉",
            type_name: "SelectOption"
          },
          {
            value: "-c-67",
            name: "性转换",
            type_name: "SelectOption"
          },
          {
            value: "-c-19",
            name: "推理",
            type_name: "SelectOption"
          },
          {
            value: "-c-70",
            name: "音乐舞蹈",
            type_name: "SelectOption"
          },
          {
            value: "-c-57",
            name: "后宫",
            type_name: "SelectOption"
          },
          {
            value: "-c-29",
            name: "料理",
            type_name: "SelectOption"
          },
          {
            value: "-c-61",
            name: "机战",
            type_name: "SelectOption"
          },
          {
            value: "-c-78",
            name: "AA",
            type_name: "SelectOption"
          },
          {
            value: "-c-37",
            name: "社会",
            type_name: "SelectOption"
          },
          {
            value: "-c-76",
            name: "节操",
            type_name: "SelectOption"
          },
          {
            value: "-c-17",
            name: "音乐",
            type_name: "SelectOption"
          },
          {
            value: "-c-23",
            name: "武侠",
            type_name: "SelectOption"
          },
          {
            value: "-c-65",
            name: "西方魔幻",
            type_name: "SelectOption"
          },
          {
            value: "-c-28",
            name: "资料集",
            type_name: "SelectOption"
          },
          {
            value: "-c-10",
            name: "传记",
            type_name: "SelectOption"
          },
          {
            value: "-c-49",
            name: "宅男",
            type_name: "SelectOption"
          },
          {
            value: "-c-69",
            name: "轻小说",
            type_name: "SelectOption"
          },
          {
            value: "-c-62",
            name: "黑道",
            type_name: "SelectOption"
          },
          {
            value: "-c-50",
            name: "舞蹈",
            type_name: "SelectOption"
          },
          {
            value: "-c-42",
            name: "杂志",
            type_name: "SelectOption"
          },
          {
            value: "-c-34",
            name: "灾难",
            type_name: "SelectOption"
          },
          {
            value: "-c-77",
            name: "宅系",
            type_name: "SelectOption"
          },
          {
            value: "-c-74",
            name: "颜艺",
            type_name: "SelectOption"
          },
          {
            value: "-c-63",
            name: "腐女",
            type_name: "SelectOption"
          },
          {
            value: "-c-81",
            name: "露营",
            type_name: "SelectOption"
          },
          {
            value: "-c-82",
            name: "旅行",
            type_name: "SelectOption"
          },
          {
            value: "-c-83",
            name: "TS",
            type_name: "SelectOption"
          }
        ]
      }
    ]
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }
}

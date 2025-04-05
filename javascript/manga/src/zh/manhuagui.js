const mangayomiSources = [{
  "name": "漫画柜",
  "lang": "zh",
  "baseUrl": "https://www.manhuagui.com",
  "apiUrl": "",
  "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.manhuagui.png",
  "typeSource": "single",
  "itemType": 0,
  "isNsfw": false,
  "version": "0.0.25",
  "dateFormat": "",
  "dateFormatLocale": "",
  "pkgPath": "manga/src/zh/manhuagui.js"
}];

LZString = function() {
  function o(o, r) {
    if (!t[o]) {
      t[o] = {};
      for (var n = 0; n < o.length; n++) t[o][o.charAt(n)] = n
    }
    return t[o][r]
  }
  var r = String.fromCharCode,
    n = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
    e = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-$",
    t = {},
    i = {
      decompressFromBase64: function(r) {
        return null == r ? "" : "" == r ? null : i._decompress(r.length, 32, function(e) {
          return o(n, r.charAt(e))
        })
      },
      _decompress: function(o, n, e) {
        var t, i, s, p, u, c, a, l, f = [],
          h = 4,
          d = 4,
          m = 3,
          v = "",
          w = [],
          A = {
            val: e(0),
            position: n,
            index: 1
          };
        for (i = 0; 3 > i; i += 1) f[i] = i;
        for (p = 0, c = Math.pow(2, 2), a = 1; a != c;) u = A.val & A.position, A.position >>= 1, 0 == A.position && (A.position = n, A.val = e(A.index++)), p |= (u > 0 ? 1 : 0) * a, a <<= 1;
        switch (t = p) {
          case 0:
            for (p = 0, c = Math.pow(2, 8), a = 1; a != c;) u = A.val & A.position, A.position >>= 1, 0 == A.position && (A.position = n, A.val = e(A.index++)), p |= (u > 0 ? 1 : 0) * a, a <<= 1;
            l = r(p);
            break;
          case 1:
            for (p = 0, c = Math.pow(2, 16), a = 1; a != c;) u = A.val & A.position, A.position >>= 1, 0 == A.position && (A.position = n, A.val = e(A.index++)), p |= (u > 0 ? 1 : 0) * a, a <<= 1;
            l = r(p);
            break;
          case 2:
            return ""
        }
        for (f[3] = l, s = l, w.push(l);;) {
          if (A.index > o) return "";
          for (p = 0, c = Math.pow(2, m), a = 1; a != c;) u = A.val & A.position, A.position >>= 1, 0 == A.position && (A.position = n, A.val = e(A.index++)), p |= (u > 0 ? 1 : 0) * a, a <<= 1;
          switch (l = p) {
            case 0:
              for (p = 0, c = Math.pow(2, 8), a = 1; a != c;) u = A.val & A.position, A.position >>= 1, 0 == A.position && (A.position = n, A.val = e(A.index++)), p |= (u > 0 ? 1 : 0) * a, a <<= 1;
              f[d++] = r(p), l = d - 1, h--;
              break;
            case 1:
              for (p = 0, c = Math.pow(2, 16), a = 1; a != c;) u = A.val & A.position, A.position >>= 1, 0 == A.position && (A.position = n, A.val = e(A.index++)), p |= (u > 0 ? 1 : 0) * a, a <<= 1;
              f[d++] = r(p), l = d - 1, h--;
              break;
            case 2:
              return w.join("")
          }
          if (0 == h && (h = Math.pow(2, m), m++), f[l]) v = f[l];
          else {
            if (l !== d) return null;
            v = s + s.charAt(0)
          }
          w.push(v), f[d++] = s + v.charAt(0), h--, s = v, 0 == h && (h = Math.pow(2, m), m++)
        }
      }
    };
  return i
}();

function decode(text) {
  function packed(functionStr, a, c, data) {
    function e(c) {
      return String(c < a ? '' : e(Math.floor(c / a))) + String((c % a > 35) ? String.fromCharCode(c % a + 29) : tr(c % a, 36));
    }

    function tr(value, num) {
      var tmp = itr(value, num);
      return tmp == '' ? '0' : tmp;
    }

    function itr(value, num) {
      const d = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      return value <= 0 ? '' : itr(Math.floor(value / num), num) + d[value % num];
    }

    c = c - 1;
    const d = {};
    while (c + 1) {
      d[e(c)] = data[c] == '' ? e(c) : data[c];
      c -= 1;
    }
    const pieces = functionStr.split(/\b(\w+)\b/);
    const js = pieces.map(function(x) {
      return d[x] !== undefined ? d[x] : x;
    }).join('').replace(/\\'/g, '\'');
    return JSON.parse(js.match(/^.*\((\{.*\})\).*$/)[1]);
  }
  const m = text.match(/^.*\}\(\'(.*)\',(\d*),(\d*),\'([\w|\+|\/|=]*)\'.*$/);
  return packed(m[1], parseInt(m[2]), parseInt(m[3]), LZString.decompressFromBase64(m[4]).split('|'));
}

class DefaultExtension extends MProvider {
  headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36"
  };

  getHeaders(url) {
    return {
      Referer: this.source.baseUrl
    }
  }

  async getItems(url, p) {
    const res = await new Client().get(this.source.baseUrl + url, this.headers);
    const doc = new Document(res.body);
    const mangas = [];
    const elements = doc.select(p);
    for (const element of elements) {
      const title = element.selectFirst("a").attr("title");
      const url = element.selectFirst("a").attr("href");
      var cover = element.selectFirst("img").attr("src");
      if (cover == "") {
        cover = element.selectFirst("img").attr("data-src");
      }
      cover = "https:" + cover;
      mangas.push({
        name: title,
        imageUrl: cover,
        link: url
      });
    }
    return {
      list: mangas,
      hasNextPage: true
    };
  }

  async getPopular(page) {
    return await this.getItems(`/list/view_p${page}.html`, "ul#contList li");
  }

  async getLatestUpdates(page) {
    return await this.getItems(`/list/index_p${page}.html`, "ul#contList li");
  }

  async search(query, page, filters) {
    if (query == "") {
      var sort, locations, categories, status, reader;
      for (const filter of filters) {
        if (filter["type"] == "sort") {
          sort = filter["values"][filter["state"]]["value"];
        } else if (filter["type"] == "locations") {
          locations = filter["values"][filter["state"]]["value"];
        } else if (filter["type"] == "categories") {
          categories = filter["values"][filter["state"]]["value"];
        } else if (filter["type"] == "status") {
          status = filter["values"][filter["state"]]["value"];
        } else if (filter["type"] == "reader") {
          reader = filter["values"][filter["state"]]["value"];
        }
      }
      const params = [locations, categories, reader, status];
      return await this.getItems(`/list${"/"+params.filter(item => item != "").join("_")}/${sort}_p${page}.html`, "ul#contList li");
    } else {
      return await this.getItems(`/s/${query}_p${page}.html`, "div.book-result li");
    }
  }

  async getDetail(url) {
    const res = await new Client().get(this.source.baseUrl + url, this.headers);
    const doc = new Document(res.body);
    const title = doc.selectFirst("div.book-title h1").text;
    const cover = "https:" + doc.selectFirst("p.hcover img").attr("src");
    const desc = doc.selectFirst("div#intro-all").text;
    const info = doc.select("ul.detail-list li")[1].select("span");
    const authors = info[1].text.replace("漫画作者：", "");
    const genres = info[0].select("a").map(e => e.text);
    const status_str = doc.selectFirst("li.status span").text;
    var status;
    if (status_str == "已完结") {
      status = 1;
    } else {
      status = 0;
    }
    const eps = [];
    var chapter_html;
    if (res.body.search("请点击此处继续阅读！") == -1) {
      chapter_html = doc;
    } else {
      const text = LZString.decompressFromBase64(doc.selectFirst("input#__VIEWSTATE").attr("value"));
      chapter_html = new Document(text);
    }
    const ch_title = chapter_html.select("h4 span");
    const chapters = chapter_html.select("div.chapter-list")
    var index = 0;
    for (const chs of ch_title) {
      const t = chs.text;
      for (const ch of chapters[index].select("ul")) {
        const ep_ = [];
        for (const c of ch.select("a.status0")) {
          ep_.push({
            name: `|${t}|` + c.attr("title"),
            url: c.attr("href")
          });
        }
        ep_.reverse();
        for (const e of ep_) {
          eps.push(e);
        }
      }
      index = index + 1;
    }
    eps.reverse();
    return {
      name: title,
      imageUrl: cover,
      description: desc,
      genre: genres,
      author: authors,
      status: status,
      episodes: eps
    };
  }

  async getPageList(url) {
    const preference = new SharedPreferences();
    const image_host = preference.get("imghost");
    const res = await new Client().get(this.source.baseUrl + url, this.headers);
    const datas = decode(res.body);
    const imgs = [];
    for (const data of datas["files"]) {
      imgs.push(`https://${image_host}.hamreus.com` + datas["path"] + data + `?e=${datas["sl"]["e"]}&m=${datas["sl"]["m"]}`);
    }
    return imgs;
  }

  getFilterList() {
    return [{
        type: "sort",
        name: "排序",
        type_name: "SelectFilter",
        values: [{
            type_name: "SelectOption",
            name: "最新发布",
            value: "index"
          },
          {
            type_name: "SelectOption",
            name: "最新更新",
            value: "update"
          },
          {
            type_name: "SelectOption",
            name: "人气最旺",
            value: "view"
          },
          {
            type_name: "SelectOption",
            name: "评分最高",
            value: "rate"
          }
        ]
      },
      {
        type: "locations",
        name: "地区",
        type_name: "SelectFilter",
        values: [{
            type_name: "SelectOption",
            name: "全部",
            value: ""
          },
          {
            type_name: "SelectOption",
            name: "日本",
            value: "japan"
          },
          {
            type_name: "SelectOption",
            name: "港台",
            value: "hongkong"
          },
          {
            type_name: "SelectOption",
            name: "其他",
            value: "other"
          },
          {
            type_name: "SelectOption",
            name: "欧美",
            value: "europe"
          },
          {
            type_name: "SelectOption",
            name: "内地",
            value: "china"
          },
          {
            type_name: "SelectOption",
            name: "韩国",
            value: "korea"
          }
        ]
      },
      {
        type: "categories",
        name: "剧情",
        type_name: "SelectFilter",
        values: [{
            type_name: "SelectOption",
            name: "全部",
            value: ""
          },
          {
            type_name: "SelectOption",
            name: "热血",
            value: "rexue"
          },
          {
            type_name: "SelectOption",
            name: "冒险",
            value: "maoxian"
          },
          {
            type_name: "SelectOption",
            name: "魔幻",
            value: "mohuan"
          },
          {
            type_name: "SelectOption",
            name: "神鬼",
            value: "shengui"
          },
          {
            type_name: "SelectOption",
            name: "搞笑",
            value: "gaoxiao"
          },
          {
            type_name: "SelectOption",
            name: "萌系",
            value: "mengxi"
          },
          {
            type_name: "SelectOption",
            name: "爱情",
            value: "aiqing"
          },
          {
            type_name: "SelectOption",
            name: "科幻",
            value: "kehuan"
          },
          {
            type_name: "SelectOption",
            name: "魔法",
            value: "mofa"
          },
          {
            type_name: "SelectOption",
            name: "格斗",
            value: "gedou"
          },
          {
            type_name: "SelectOption",
            name: "武侠",
            value: "wuxia"
          },
          {
            type_name: "SelectOption",
            name: "机战",
            value: "jizhan"
          },
          {
            type_name: "SelectOption",
            name: "战争",
            value: "zhanzheng"
          },
          {
            type_name: "SelectOption",
            name: "竞技",
            value: "jingji"
          },
          {
            type_name: "SelectOption",
            name: "体育",
            value: "tiyu"
          },
          {
            type_name: "SelectOption",
            name: "校园",
            value: "xiaoyuan"
          },
          {
            type_name: "SelectOption",
            name: "生活",
            value: "shenghuo"
          },
          {
            type_name: "SelectOption",
            name: "励志",
            value: "lizhi"
          },
          {
            type_name: "SelectOption",
            name: "历史",
            value: "lishi"
          },
          {
            type_name: "SelectOption",
            name: "伪娘",
            value: "weiniang"
          },
          {
            type_name: "SelectOption",
            name: "宅男",
            value: "zhainan"
          },
          {
            type_name: "SelectOption",
            name: "腐女",
            value: "funv"
          },
          {
            type_name: "SelectOption",
            name: "耽美",
            value: "danmei"
          },
          {
            type_name: "SelectOption",
            name: "百合",
            value: "baihe"
          },
          {
            type_name: "SelectOption",
            name: "后宫",
            value: "hougong"
          },
          {
            type_name: "SelectOption",
            name: "治愈",
            value: "zhiyu"
          },
          {
            type_name: "SelectOption",
            name: "美食",
            value: "meishi"
          },
          {
            type_name: "SelectOption",
            name: "推理",
            value: "tuili"
          },
          {
            type_name: "SelectOption",
            name: "悬疑",
            value: "xuanyi"
          },
          {
            type_name: "SelectOption",
            name: "恐怖",
            value: "kongbu"
          },
          {
            type_name: "SelectOption",
            name: "四格",
            value: "sige"
          },
          {
            type_name: "SelectOption",
            name: "职场",
            value: "zhichang"
          },
          {
            type_name: "SelectOption",
            name: "侦探",
            value: "zhentan"
          },
          {
            type_name: "SelectOption",
            name: "社会",
            value: "shehui"
          },
          {
            type_name: "SelectOption",
            name: "音乐",
            value: "yinyue"
          },
          {
            type_name: "SelectOption",
            name: "舞蹈",
            value: "wudao"
          },
          {
            type_name: "SelectOption",
            name: "杂志",
            value: "zazhi"
          },
          {
            type_name: "SelectOption",
            name: "黑道",
            value: "heidao"
          }
        ]
      },
      {
        type: "reader",
        name: "受众",
        type_name: "SelectFilter",
        values: [{
            type_name: "SelectOption",
            name: "全部",
            value: ""
          },
          {
            type_name: "SelectOption",
            name: "少女",
            value: "shaonv"
          },
          {
            type_name: "SelectOption",
            name: "少年",
            value: "shaonian"
          },
          {
            type_name: "SelectOption",
            name: "青年",
            value: "qingnian"
          },
          {
            type_name: "SelectOption",
            name: "儿童",
            value: "ertong"
          },
          {
            type_name: "SelectOption",
            name: "通用",
            value: "tongyong"
          }
        ]
      },
      {
        type: "status",
        name: "状态",
        type_name: "SelectFilter",
        values: [{
            type_name: "SelectOption",
            name: "全部",
            value: ""
          },
          {
            type_name: "SelectOption",
            name: "连载中",
            value: "lianzai"
          },
          {
            type_name: "SelectOption",
            name: "已完结",
            value: "wanjie"
          }
        ]
      }
    ];
  }

  getSourcePreferences() {
    return [{
      "key": "imghost",
      "listPreference": {
        "title": "图片服务器",
        "summary": "",
        "valueIndex": 0,
        "entries": ["通用", "欧洲", "美国"],
        "entryValues": ["i", "eu", "us"],
      }
    }];
  }
}

const mangayomiSources = [{
    "name": "拷贝漫画",
    "lang": "zh",
    "baseUrl": "https://www.mangacopy.com",
    "apiUrl": "https://api.mangacopy.com",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.copymanga.png",
    "typeSource": "single",
    "itemType": 0,
    "isNsfw": false,
    "version": "0.0.25",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/zh/copymanga.js"
  }];
  
  class DefaultExtension extends MProvider {
    stringUTF8(text) {
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
  
    base64encode(str) {
      const base64EncodeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      var out, i, len;
      var c1, c2, c3;
      len = str.length;
      i = 0;
      out = "";
      while (i < len) {
        c1 = str.charCodeAt(i++) & 0xff;
        if (i == len) {
          out += base64EncodeChars.charAt(c1 >> 2);
          out += base64EncodeChars.charAt((c1 & 0x3) << 4);
          out += "==";
          break;
        }
        c2 = str.charCodeAt(i++);
        if (i == len) {
          out += base64EncodeChars.charAt(c1 >> 2);
          out += base64EncodeChars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4));
          out += base64EncodeChars.charAt((c2 & 0xF) << 2);
          out += "=";
          break;
        }
        c3 = str.charCodeAt(i++);
        out += base64EncodeChars.charAt(c1 >> 2);
        out += base64EncodeChars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4));
        out += base64EncodeChars.charAt(((c2 & 0xF) << 2) | ((c3 & 0xC0) >> 6));
        out += base64EncodeChars.charAt(c3 & 0x3F);
      }
      return out;
    }
  
    decode(result) {
      var iv = result.substring(0, 16);
      result = result.replace(iv, "");
      const bytes = [];
      for (var i = 0; i < result.length; i = i + 2) {
        bytes.push(parseInt(result.substr(i, 2), 16));
      }
      var charString = String.fromCharCode.apply(null, bytes);
      const data = this.base64encode(charString);
      const text = cryptoHandler(data, iv, "xxxmanga.woo.key", false);
      return text;
    }
  
    getHeaders(url) {
      return {
        Referer: this.source.baseUrl
      };
    }

    reqHeaders() {
      const date = new Date();
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return {
        'User-Agent': 'duoTuoCartoon/3.2.4 (iPhone; iOS 18.0.1; Scale/3.00) iDOKit/1.0.0 RSSX/1.0.0',
        'version': `${year}.${month}.${day}`,
        'region': '0',
        'webp': '0',
        "platform": "1",
        "Referer": "https://www.copymanga.com/"
      }
    }
  
    async getManga(url) {
      const res = await new Client().get(this.source.apiUrl + url);
      const datas = JSON.parse(res.body);
      const manga = [];
      for (const data of datas["results"]["list"]) {
        manga.push({
          name: this.stringUTF8(data["name"]),
          imageUrl: data["cover"],
          link: data["path_word"]
        });
      }
      return {
        list: manga,
        hasNextPage: true
      };
    }
  
    async getPopular(page) {
      return await this.getManga(`/api/v3/comics?free_type=1&limit=16&offset=${(page-1)*16}&ordering=-popular&_update=true`);
    }
  
    async getLatestUpdates(page) {
      return await this.getManga(`/api/v3/comics?free_type=1&limit=16&offset=${(page-1)*16}&ordering=-datetime_updated&_update=true`);
    }
  
    async search(query, page, filters) {
      if (query != "") {
        const res = await new Client().get(this.source.apiUrl + `/api/v3/search/comic?platform=1&q=${query}&limit=16&offset=${(page -1)*16}&q_type=&_update=true`, 
        this.reqHeaders());
        const datas = JSON.parse(res.body)["results"]["list"];
        const manga = [];
        for (const data of datas) {
          manga.push({
            name: this.stringUTF8(data["name"]),
            imageUrl: data["cover"],
            link: data["path_word"]
          });
        }
        return {
          list: manga,
          hasNextPage: true
        };
      }
      var type, region, sort;
      for (const filter of filters) {
        if (filter["type"] == "type") {
          type = filter["values"][filter["state"]]["value"];
        }
        if (filter["type"] == "region") {
          region = filter["values"][filter["state"]]["value"];
        }
        if (filter["type"] == "sort") {
          sort = filter["values"][filter["state"]]["value"];
        }
      }
      return await this.getManga(`/api/v3/comics?free_type=1&limit=16&offset=${(page-1)*16}&theme=${type}&top=${region}&ordering=${sort}&_update=true`);
    }
  
    async getDetail(url) {
      url = url.substringAfter("/comic/");
      const res = await new Client().get(this.source.apiUrl + `/api/v3/comic2/${url}`, this.reqHeaders());
      const data = JSON.parse(res.body)["results"]["comic"];
      const title = this.stringUTF8(data["name"]);
      const cover = data["cover"];
      const desc = this.stringUTF8(data["brief"]);
      const author_ = [];
      for (const a of data["author"]) {
        author_.push(this.stringUTF8(a["name"]));
      }
      const author = author_.join(",");
      const status = data["status"]["value"];
      const genres = data["theme"].map(e => this.stringUTF8(e["name"]));
      const chapters = [];
      const res_ = await new Client().get(this.source.baseUrl + `/comicdetail/${url}/chapters`, {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36"
      });
      const ch_text = JSON.parse(res_.body)["results"];
      const chapter_datas = JSON.parse(this.decode(ch_text));
      for (const ch of chapter_datas["groups"]["default"]["chapters"]) {
        chapters.push({
          name: ch["name"],
          url: url + "|" + ch["id"]
        });
      }
      chapters.reverse();
      return {
        name: title,
        imageUrl: cover,
        description: desc,
        author: author,
        status: status,
        genre: genres,
        episodes: chapters,
        link: "/comic/" + url
      }
    }
  
    async getPageList(url) {
      const urls = url.split("|");
      const res = await new Client().get(this.source.baseUrl + `/comic/${urls[0]}/chapter/${urls[1]}`, {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36"
      });
      const img_text = res.body.match(/contentKey="(.*)"/)[1];
      const results = JSON.parse(this.decode(img_text));
      return results.map(e => e["url"]);
    }
  
    getFilterList() {
      return [{
          type: "type",
          name: "分类",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "全部",
              value: ""
            },
            {
              type_name: "SelectOption",
              name: "愛情",
              value: "aiqing"
            },
            {
              type_name: "SelectOption",
              name: "歡樂向",
              value: "huanlexiang"
            },
            {
              type_name: "SelectOption",
              name: "冒险",
              value: "maoxian"
            },
            {
              type_name: "SelectOption",
              name: "奇幻",
              value: "qihuan"
            },
            {
              type_name: "SelectOption",
              name: "百合",
              value: "baihe"
            },
            {
              type_name: "SelectOption",
              name: "校园",
              value: "xiaoyuan"
            },
            {
              type_name: "SelectOption",
              name: "科幻",
              value: "kehuan"
            },
            {
              type_name: "SelectOption",
              name: "東方",
              value: "dongfang"
            },
            {
              type_name: "SelectOption",
              name: "生活",
              value: "shenghuo"
            },
            {
              type_name: "SelectOption",
              name: "轻小说",
              value: "qingxiaoshuo"
            },
            {
              type_name: "SelectOption",
              name: "格鬥",
              value: "gedou"
            },
            {
              type_name: "SelectOption",
              name: "耽美",
              value: "danmei"
            },
            {
              type_name: "SelectOption",
              name: "悬疑",
              value: "xuanyi"
            },
            {
              type_name: "SelectOption",
              name: "神鬼",
              value: "shengui"
            },
            {
              type_name: "SelectOption",
              name: "其他",
              value: "qita"
            },
            {
              type_name: "SelectOption",
              name: "职场",
              value: "zhichang"
            },
            {
              type_name: "SelectOption",
              name: "萌系",
              value: "mengxi"
            },
            {
              type_name: "SelectOption",
              name: "治愈",
              value: "zhiyu"
            },
            {
              type_name: "SelectOption",
              name: "長條",
              value: "changtiao"
            },
            {
              type_name: "SelectOption",
              name: "四格",
              value: "sige"
            },
            {
              type_name: "SelectOption",
              name: "舰娘",
              value: "jianniang"
            },
            {
              type_name: "SelectOption",
              name: "节操",
              value: "jiecao"
            },
            {
              type_name: "SelectOption",
              name: "TL",
              value: "teenslove"
            },
            {
              type_name: "SelectOption",
              name: "竞技",
              value: "jingji"
            },
            {
              type_name: "SelectOption",
              name: "搞笑",
              value: "gaoxiao"
            },
            {
              type_name: "SelectOption",
              name: "伪娘",
              value: "weiniang"
            },
            {
              type_name: "SelectOption",
              name: "热血",
              value: "rexue"
            },
            {
              type_name: "SelectOption",
              name: "後宮",
              value: "hougong"
            },
            {
              type_name: "SelectOption",
              name: "美食",
              value: "meishi"
            },
            {
              type_name: "SelectOption",
              name: "性转换",
              value: "xingzhuanhuan"
            },
            {
              type_name: "SelectOption",
              name: "侦探",
              value: "zhentan"
            },
            {
              type_name: "SelectOption",
              name: "励志",
              value: "lizhi"
            },
            {
              type_name: "SelectOption",
              name: "AA",
              value: "aa"
            },
            {
              type_name: "SelectOption",
              name: "彩色",
              value: "COLOR"
            },
            {
              type_name: "SelectOption",
              name: "音乐舞蹈",
              value: "yinyuewudao"
            },
            {
              type_name: "SelectOption",
              name: "异世界",
              value: "yishijie"
            },
            {
              type_name: "SelectOption",
              name: "战争",
              value: "zhanzheng"
            },
            {
              type_name: "SelectOption",
              name: "历史",
              value: "lishi"
            },
            {
              type_name: "SelectOption",
              name: "机战",
              value: "jizhan"
            },
            {
              type_name: "SelectOption",
              name: "惊悚",
              value: "jingsong"
            },
            {
              type_name: "SelectOption",
              name: "C99",
              value: "comiket99"
            },
            {
              type_name: "SelectOption",
              name: "恐怖",
              value: "恐怖"
            },
            {
              type_name: "SelectOption",
              name: "都市",
              value: "dushi"
            },
            {
              type_name: "SelectOption",
              name: "C97",
              value: "comiket97"
            },
            {
              type_name: "SelectOption",
              name: "穿越",
              value: "chuanyue"
            },
            {
              type_name: "SelectOption",
              name: "C96",
              value: "comiket96"
            },
            {
              type_name: "SelectOption",
              name: "重生",
              value: "chongsheng"
            },
            {
              type_name: "SelectOption",
              name: "魔幻",
              value: "mohuan"
            },
            {
              type_name: "SelectOption",
              name: "宅系",
              value: "zhaixi"
            },
            {
              type_name: "SelectOption",
              name: "武侠",
              value: "wuxia"
            },
            {
              type_name: "SelectOption",
              name: "C98",
              value: "C98"
            },
            {
              type_name: "SelectOption",
              name: "生存",
              value: "shengcun"
            },
            {
              type_name: "SelectOption",
              name: "C95",
              value: "comiket95"
            },
            {
              type_name: "SelectOption",
              name: "FATE",
              value: "fate"
            },
            {
              type_name: "SelectOption",
              name: "無修正",
              value: "Uncensored"
            },
            {
              type_name: "SelectOption",
              name: "转生",
              value: "zhuansheng"
            },
            {
              type_name: "SelectOption",
              name: "LoveLive",
              value: "loveLive"
            },
            {
              type_name: "SelectOption",
              name: "男同",
              value: "nantong"
            },
            {
              type_name: "SelectOption",
              name: "仙侠",
              value: "xianxia"
            },
            {
              type_name: "SelectOption",
              name: "玄幻",
              value: "xuanhuan"
            },
            {
              type_name: "SelectOption",
              name: "真人",
              value: "zhenren"
            },
          ],
        },
        {
          type: "region",
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
              name: "韩国",
              value: "korea"
            },
            {
              type_name: "SelectOption",
              name: "欧美",
              value: "west"
            },
            {
              type_name: "SelectOption",
              name: "完结",
              value: "finish"
            },
          ],
        },
        {
          type: "sort",
          name: "排序",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "更新时间⬇️",
              value: "-datetime_updated"
            },
            {
              type_name: "SelectOption",
              name: "更新时间⬆️",
              value: "datetime_updated"
            },
            {
              type_name: "SelectOption",
              name: "热度⬇️",
              value: "-popular"
            },
            {
              type_name: "SelectOption",
              name: "热度⬆️",
              value: "popular"
            },
          ],
        },
      ];
    }
  
    getSourcePreferences() {
      throw new Error("getSourcePreferences not implemented");
    }
  }
const mangayomiSources = [{
    "name": "动漫之家",
    "lang": "zh",
    "baseUrl": "https://www.dmzj.com",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.dmzj.png",
    "typeSource": "single",
    "itemType": 0,
    "isNsfw": false,
    "version": "0.0.3",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/zh/dmzj.js"
  }];
  
  class DefaultExtension extends MProvider {
    getHeaders(url) {
      throw new Error("getHeaders not implemented");
    }
    async getManga(url) {
      const res = await new Client().get(url);
      const datas = JSON.parse(res.body);
      const mangas = [];
      for (const data of datas) {
        mangas.push({
          name: data["name"],
          imageUrl: "https://images.idmzj.com/" + data["cover"],
          link: data["comic_py"]
        });
      }
      return {
        list: mangas,
        hasNextPage: true
      };
    }
    async getPopular(page) {
      return await this.getManga(`https://m.idmzj.com/classify/0-0-0-0-0-${page-1}.json`);
    }
    async getLatestUpdates(page) {
      return await this.getManga(`https://m.idmzj.com/classify/0-0-0-0-1-${page-1}.json`);
    }
    async search(query, page, filters) {
      if (query == "") {
        var type, region, status, sort;
        for (const filter of filters) {
          if (filter["type"] == "type") {
            type = filter["values"][filter["state"]]["value"];
          }
          if (filter["type"] == "region") {
            region = filter["values"][filter["state"]]["value"];
          }
          if (filter["type"] == "status") {
            status = filter["values"][filter["state"]]["value"];
          }
          if (filter["type"] == "sort") {
            sort = filter["values"][filter["state"]]["value"];
          }
        }
        return await this.getManga(`https://m.idmzj.com/classify/${type}-0-${status}-${region}-${sort}-${page - 1}.json`);
      }
      const res = await new Client().get(`http://sacg.dmzj.com/comicsum/search.php?s=${query}`);
      const datas = JSON.parse(res.body.slice(20, -1));
      const mangas = [];
      for (const data of datas) {
        mangas.push({
          name: data["comic_name"],
          imageUrl: data["comic_cover"],
          link: data["comic_url"].replace("//manhua.dmzj.com/", "")
        });
      }
      return {
        list: mangas,
        hasNextPage: true
      };
    }
  
    async getDetail(url) {
      const preference = new SharedPreferences();
      const res = await new Client().get(`https://www.dmzj.com/api/v1/comic1/comic/detail?comic_py=${url}&channel=pc&app_name=dmzj&version=1.0.0&uid=${preference.get("uid")}`);
      const datas = JSON.parse(res.body);
      if (datas["errno"] != 0) {
        return {
          name: datas["errmsg"]
        };
      }
      const title = datas["data"]["comicInfo"]["title"];
      const status = datas["data"]["comicInfo"]["status"] == "连载中" ? 0 : 1;
      const cover = datas["data"]["comicInfo"]["cover"];
      const author = datas["data"]["comicInfo"]["authorInfo"]["authorName"];
      const genres = datas["data"]["comicInfo"]["types"].split("/");
      const desc = datas["data"]["comicInfo"]["description"]
      const chapters = [];
      if (datas["data"]["comicInfo"]["chapterList"] != null) {
        for (const chlist of datas["data"]["comicInfo"]["chapterList"]) {
          for (const ch of chlist["data"]) {
            chapters.push({
              name: `[[${chlist["title"]}]]` + ch["chapter_title"],
              url: datas["data"]["comicInfo"]["id"].toString() + "|" + ch["chapter_id"].toString(),
              dateUpload: ch["updatetime"].toString() + "000"
            });
          }
        }
      }
      return {
        name: title,
        imageUrl: cover,
        author: author,
        genre: genres,
        description: desc,
        episodes: chapters,
        status: status,
        link: "/info/" + url + ".html"
      };
    }
  
    async getPageList(url) {
      const preference = new SharedPreferences();
      const ids = url.split("|");
      const res = await new Client().get(`https://www.dmzj.com/api/v1/comic1/chapter/detail?channel=pc&app_name=dmzj&version=1.0.0&comic_id=${ids[0]}&chapter_id=${ids[1]}&uid=${preference.get("uid")}`);
      const datas = JSON.parse(res.body);
      if (datas["errno"] != 0) {
        return [];
      }
      if (preference.get("hd") && "page_url_hd" in datas["data"]["chapterInfo"]) {
        return datas["data"]["chapterInfo"]["page_url_hd"];
      }
      return datas["data"]["chapterInfo"]["page_url"];
    }
  
    getFilterList() {
      return [{
          type: "type",
          name: "分类",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "全部",
              value: "0"
            },
            {
              type_name: "SelectOption",
              name: "冒险",
              value: "1"
            },
            {
              type_name: "SelectOption",
              name: "欢乐向",
              value: "2"
            },
            {
              type_name: "SelectOption",
              name: "格斗",
              value: "3"
            },
            {
              type_name: "SelectOption",
              name: "科幻",
              value: "4"
            },
            {
              type_name: "SelectOption",
              name: "爱情",
              value: "5"
            },
            {
              type_name: "SelectOption",
              name: "竞技",
              value: "6"
            },
            {
              type_name: "SelectOption",
              name: "魔法",
              value: "7"
            },
            {
              type_name: "SelectOption",
              name: "校园",
              value: "8"
            },
            {
              type_name: "SelectOption",
              name: "悬疑",
              value: "9"
            },
            {
              type_name: "SelectOption",
              name: "恐怖",
              value: "10"
            },
            {
              type_name: "SelectOption",
              name: "生活亲情",
              value: "11"
            },
            {
              type_name: "SelectOption",
              name: "百合",
              value: "12"
            },
            {
              type_name: "SelectOption",
              name: "伪娘",
              value: "13"
            },
            {
              type_name: "SelectOption",
              name: "耽美",
              value: "14"
            },
            {
              type_name: "SelectOption",
              name: "后宫",
              value: "15"
            },
            {
              type_name: "SelectOption",
              name: "萌系",
              value: "16"
            },
            {
              type_name: "SelectOption",
              name: "治愈",
              value: "17"
            },
            {
              type_name: "SelectOption",
              name: "武侠",
              value: "18"
            },
            {
              type_name: "SelectOption",
              name: "职场",
              value: "19"
            },
            {
              type_name: "SelectOption",
              name: "奇幻",
              value: "20"
            },
            {
              type_name: "SelectOption",
              name: "节操",
              value: "21"
            },
            {
              type_name: "SelectOption",
              name: "轻小说",
              value: "22"
            },
            {
              type_name: "SelectOption",
              name: "搞笑",
              value: "23"
            },
          ]
        },
        {
          type: "region",
          name: "地区",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "全部",
              value: "0"
            },
            {
              type_name: "SelectOption",
              name: "日本",
              value: "1"
            },
            {
              type_name: "SelectOption",
              name: "内地",
              value: "2"
            },
            {
              type_name: "SelectOption",
              name: "欧美",
              value: "3"
            },
            {
              type_name: "SelectOption",
              name: "港台",
              value: "4"
            },
            {
              type_name: "SelectOption",
              name: "韩国",
              value: "5"
            },
            {
              type_name: "SelectOption",
              name: "其他",
              value: "6"
            },
          ]
        },
        {
          type: "status",
          name: "状态",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "全部",
              value: "0"
            },
            {
              type_name: "SelectOption",
              name: "连载中",
              value: "1"
            },
            {
              type_name: "SelectOption",
              name: "已完结",
              value: "2"
            },
          ]
        },
        {
          type: "sort",
          name: "排序",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "浏览次数",
              value: "0"
            },
            {
              type_name: "SelectOption",
              name: "更新时间",
              value: "1"
            },
          ]
        },
      ];
    }
  
    getSourcePreferences() {
      return [{
          "key": "uid",
          "editTextPreference": {
            "title": "用户uid",
            "summary": "设置后可以解锁部分漫画",
            "value": "2665531",
            "dialogTitle": "UID",
            "dialogMessage": "",
          }
        },
        {
          "key": "hd",
          "switchPreferenceCompat": {
            "title": "高清画质",
            "summary": "启用后使用高清画质",
            "value": false
          }
        }
      ];
    }
  }

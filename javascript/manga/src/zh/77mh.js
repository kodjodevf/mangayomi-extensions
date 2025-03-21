const mangayomiSources = [{
    "name": "新新漫画",
    "lang": "zh",
    "baseUrl": "http://www.77mh.xyz",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.77mh.png",
    "typeSource": "single",
    "itemType": 0,
    "isNsfw": false,
    "version": "0.0.35",
    "apiUrl": "",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgName": "manga/src/zh/77mh.js"
  }];
  
  class DefaultExtension extends MProvider {
    StringResolve1(p, a, c, k, e, d) {
      e = function(c) {
        return c.toString(36)
      };
      if (!''.replace(/^/, String)) {
        while (c--) {
          d[c.toString(a)] = k[c] || c.toString(a)
        }
        k = [function(e) {
          return d[e]
        }];
        e = function() {
          return '\\w+'
        };
        c = 1
      };
      while (c--) {
        if (k[c]) {
          p = p.replace(new RegExp('\\b' + e(c) + '\\b', 'g'), k[c])
        }
      }
      return p
    }
  
    StringResolve2(p, a, c, k, e, d) {
      e = function(c) {
        return (c < a ? '' : e(parseInt(c / a))) + ((c = c % a) > 35 ? String.fromCharCode(c + 29) : c.toString(36))
      };
      if (!''.replace(/^/, String)) {
        while (c--) {
          d[e(c)] = k[c] || e(c)
        }
        k = [function(e) {
          return d[e]
        }];
        e = function() {
          return '\\w+'
        };
        c = 1
      };
      while (c--) {
        if (k[c]) {
          p = p.replace(new RegExp('\\b' + e(c) + '\\b', 'g'), k[c])
        }
      }
      return p
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
  
    async getIndex1(url) {
      const res = await new Client().get(url);
      const doc = new Document(res.body);
      const elements = doc.select("div.ar_list_co li");
      const mangas = [];
      for (const element of elements) {
        const title = element.selectFirst("span a").text;
        const url = element.selectFirst("span a").attr("href");
        const cover = element.selectFirst("img").attr("src");
        mangas.push({
          name: title,
          link: url,
          imageUrl: cover
        });
      }
      return {
        list: mangas,
        hasNextPage: true
      };
  
    }
  
    async getIndex2(url) {
      const res = await new Client().get(url);
      const doc = new Document(res.body);
      const elements = doc.select("div.ar_list_co dl");
      const mangas = [];
      for (const element of elements) {
        const title = element.selectFirst("h1 a").text.replace("<em>", "").replace("</em>", "");
        const url = "/" + element.selectFirst("h1 a").attr("href").split("/").slice(-1)[0];
        const cover = element.selectFirst("img").attr("src");
        mangas.push({
          name: title,
          link: url,
          imageUrl: cover
        });
      }
      return {
        list: mangas,
        hasNextPage: true
      };
    }
    
    async getPopular(page) {
      return await this.getIndex1(this.getBaseUrl() + "/new_coc.html");
    }
  
    async getLatestUpdates(page) {
      return await this.getIndex1(`${this.getBaseUrl()}/lianzai/index_${page - 1}.html`);
    }
  
    async search(query, page, filters) {
      var url;
      if (query == "") {
        if (filters.length == 0) {
          return {
            list: [],
            hasNextPage: false
          };
        }
        url = `${this.getBaseUrl()}${filters[0]["values"][filters[0]["state"]]["value"]}/index_${page-1}.html`
      } else {
        url = `${this.getBaseUrl().replace("www","so")}/k.php?k=${query}&p=${page}`;
      }
      return await this.getIndex2(url);
    }
  
    async getDetail(url) {
      const res = await new Client().get(this.getBaseUrl() + url);
      const doc = new Document(res.body);
      const info = doc.selectFirst("div.ar_list_coc");
      const cover = info.selectFirst("img").attr("src");
      const title = info.selectFirst("h1").text;
      const info_other = info.selectFirst("ul.ar_list_coc");
      const author = info_other.selectFirst("a").text;
      const status_str = info_other.select("a")[1].text;
      var status;
      if (status_str == "已完结") {
        status = 1;
      } else {
        status = 0;
      }
      const desc = info.selectFirst("i#det").text;
      const elements = doc.select("ul.ar_rlos_bor li a");
      const chapters = [];
      for (const element of elements) {
        chapters.push({
          name: element.text,
          url: element.attr("href")
        });
      }
      return {
        name: title,
        imageUrl: cover,
        description: desc,
        author: author,
        status: status,
        episodes: chapters
      };
    }
  
    async getPageList(url) {
      const preference = new SharedPreferences();
      const image_host = preference.get("imghost");
      const res = await new Client().get(this.getBaseUrl() + url);
      const strs = res.body.match(/return p}\('(.*?)'.split\('/)[1].split(',');
      var result;
      try {
        result = this.StringResolve1(strs[0], strs[1], strs[2], strs[3].split('|'), 0, {}).replaceAll("'", "");
      } catch {
        result = this.StringResolve2(strs[0], strs[1], strs[2], strs[3].split('|'), 0, {}).replaceAll("'", "");
      }
      const url_part = result.match(/var img_s=(.*?);var preLink_b/)[1];
      const urls = result.match(/var msg=(.*?);var maxPage/)[1].replaceAll("\\", "").split('|');
      const pages = [];
      for (const url of urls) {
        pages.push(image_host + `/h${url_part}/` + url);
      }
      return pages;
    }
    
    getFilterList() {
      return [{
        type: "category",
        name: "分类",
        type_name: "SelectFilter",
        values: [{
            value: "/rexue",
            name: "热血机战",
            type_name: "SelectOption"
          },
          {
            value: "/kehuan",
            name: "科幻未来",
            type_name: "SelectOption"
          },
          {
            value: "/kongbu",
            name: "恐怖惊悚",
            type_name: "SelectOption"
          },
          {
            value: "/xuanyi",
            name: "推理悬疑",
            type_name: "SelectOption"
          },
          {
            value: "/gaoxiao",
            name: "滑稽搞笑",
            type_name: "SelectOption"
          },
          {
            value: "/love",
            name: "恋爱生活",
            type_name: "SelectOption"
          },
          {
            value: "/danmei",
            name: "耽美人生",
            type_name: "SelectOption"
          },
          {
            value: "/tiyu",
            name: "体育竞技",
            type_name: "SelectOption"
          },
          {
            value: "/chunqing",
            name: "纯情少女",
            type_name: "SelectOption"
          },
          {
            value: "/qihuan",
            name: "魔法奇幻",
            type_name: "SelectOption"
          },
          {
            value: "/wuxia",
            name: "武侠经典",
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
          "summary": "网址",
          "value": "http://www.77mh.xyz",
          "dialogTitle": "URL",
          "dialogMessage": "",
        }
      },{
        "key": "imghost",
        "listPreference": {
          "title": "图片服务器",
          "summary": "",
          "valueIndex": 0,
          "entries": ["服务器1", "服务器2", "服务器3"],
          "entryValues": ["https://picsh.77dm.top", "https://imgsh.dm365.top", "https://hws.gdbyhtl.net"],
        }
      }];
    }
  }

const mangayomiSources = [{
    "name": "禁漫天堂",
    "lang": "zh",
    "baseUrl": "https://18comic.vip",
    "apiUrl": "",
    "iconUrl": "https://cdn-msp.jmcomic.me/media/logo/new_logo.png?v=2024043002",
    "typeSource": "single",
    "isManga": true,
    "isNsfw": true,
    "version": "0.0.15",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/zh/jmcomic.js"
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
  
    getHeaders(url) {
      throw new Error("getHeaders not implemented");
    }
  
    async getManga(url, p) {
      const res = await new Client().get(this.source.baseUrl + url, {
        Referer: this.source.baseUrl
      });
      const doc = new Document(res.body);
      const manga = [];
      const elements = doc.select(p);
      for (const element of elements) {
        var text = element.innerHtml;
        text = text.slice(text.search("<noscript>"), -1);
        const title = text.match(/title="(.*)" alt=/)[1];
        var cover = text.match(/data-original="(.*)" title=/);
        if (cover == null) {
          cover = text.match(/src="(.*)" title=/);
        }
        const url = element.innerHtml.match(/<a href="(.*)"/)[1];
        manga.push({
          name: title,
          link: url,
          imageUrl: cover[1]
        });
      }
      return {
        list: manga,
        hasNextPage: true
      };
    }
  
    async getPopular(page) {
      return await this.getManga(`/albums?t=a&o=mv&page=${page}`, "div.thumb-overlay-albums");
    }
  
    async getLatestUpdates(page) {
      return await this.getManga(`/albums?t=a&o=mr&page=${page}`, "div.thumb-overlay-albums");
    }
  
    async search(query, page, filters) {
      var type, time, sort;
      for (const filter of filters) {
        if (filter["type"] == "type") {
          type = filter["values"][filter["state"]]["value"];
        }
        if (filter["type"] == "time") {
          time = filter["values"][filter["state"]]["value"];
        }
        if (filter["type"] == "sort") {
          sort = filter["values"][filter["state"]]["value"];
        }
      }
      if (query != "") {
        return await this.getManga(`/search/photos?search_query=${query}&t=a&o=mr`, "div.thumb-overlay");
      }
      return await this.getManga(`/albums${"/"+type}?t=${time}&o=${sort}&page=${page}`, "div.thumb-overlay-albums");
    }
  
    async getDetail(url) {
      const res = await new Client().get(this.source.baseUrl + url, {
        Referer: this.source.baseUrl
      });
      const doc = new Document(res.body);
      const cover = doc.selectFirst("div.show_zoom").innerHtml.match(/data-cfsrc="(.*)" data-cfstyle/)[1];
      const title = doc.selectFirst("h1").text;
      const desc = doc.selectFirst("div#intro-block div.p-t-5").text;
      const infos = doc.select("div#intro-block div.tag-block");
      const tags = infos[2].select("a").map(e => e.text);
      const author = infos[3].selectFirst("a").text;
      const date_str = res.body.match(/更新日期 : (.*)\n<\/p>/)[1];
      const chapters = [];
      const elements = doc.selectFirst("div.episode ul").select("a");
      if (elements.length == 0) {
        chapters.push({
          name: title,
          dateUpload: this.dateStringToTimestamp(date_str).toString(),
          url: url.replace("album", "photo")
        });
      } else {
        for (const element of elements) {
          const url = element.attr("href");
          const title = element.selectFirst("li").text;
          const date = element.selectFirst("span.hidden-xs").text;
          chapters.push({
            name: title.split("\n")[1],
            dateUpload: this.dateStringToTimestamp(date).toString(),
            url: url
          });
        }
      }
      chapters.reverse();
      return {
        name: title,
        imageUrl: cover,
        description: desc,
        genre: tags,
        author: author,
        episodes: chapters
      };
    }
  
    async getPageList(url) {
      const res = await new Client().get(this.source.baseUrl + url);
      const doc = new Document(res.body);
      const elements = doc.select("div.scramble-page");
      const pages = [];
      for (const element of elements) {
        var text = element.innerHtml;
        text = text.slice(text.search("<noscript>"), -1);
        const img = text.match(/data-original="(.*)" id/);
        if (img != null) {
          pages.push(img[1]);
        }
      }
      return pages;
    }
  
    getFilterList() {
      return [{
          type: "sort",
          name: "排序",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "最新",
              value: "mr"
            },
            {
              type_name: "SelectOption",
              name: "最多订阅",
              value: "mv"
            },
            {
              type_name: "SelectOption",
              name: "最多图片",
              value: "mp"
            },
            {
              type_name: "SelectOption",
              name: "最高评分",
              value: "tr"
            },
            {
              type_name: "SelectOption",
              name: "最多评论",
              value: "md"
            },
            {
              type_name: "SelectOption",
              name: "最多爱心",
              value: "tf"
            },
          ]
        }, {
          type: "time",
          name: "时间",
          type_name: "SelectFilter",
          values: [{
              type_name: "SelectOption",
              name: "全部",
              value: "a"
            },
            {
              type_name: "SelectOption",
              name: "今天",
              value: "t"
            },
            {
              type_name: "SelectOption",
              name: "这周",
              value: "w"
            },
            {
              type_name: "SelectOption",
              name: "本月",
              value: "m"
            },
          ]
        },
        {
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
              name: "其他类",
              value: "another"
            },
            {
              type_name: "SelectOption",
              name: "同人",
              value: "doujin"
            },
            {
              type_name: "SelectOption",
              name: "韩漫",
              value: "hanman"
            },
            {
              type_name: "SelectOption",
              name: "美漫",
              value: "meiman"
            },
            {
              type_name: "SelectOption",
              name: "短篇",
              value: "short"
            },
            {
              type_name: "SelectOption",
              name: "单本",
              value: "single"
            },
          ]
        }
      ];
    }
  
    getSourcePreferences() {
      throw new Error("getSourcePreferences not implemented");
    }
  }
const mangayomiSources = [{
  "name": "蜜柑计划",
  "lang": "zh",
  "baseUrl": "https://mikanime.tv",
  "apiUrl": "",
  "iconUrl": "https://mikanime.tv/images/mikan-pic.png",
  "typeSource": "torrent",
  "isManga": false,
  "isNsfw": false,
  "version": "0.0.15",
  "dateFormat": "",
  "dateFormatLocale": "",
  "pkgPath": "anime/src/zh/mikan.js"
}];

class DefaultExtension extends MProvider {
  dateStringToTimestamp(dateString) {
    var parts = dateString.split('/');
    var year = parseInt(parts[2]);
    var month = parseInt(parts[0]) - 1;
    var day = parseInt(parts[1]);
    var date = new Date(year, month, day);
    var timestamp = date.getTime();
    return timestamp;
  }

  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  async getItems(url, cookies) {
    var res;
    if (cookies) {
      res = await new Client().get(this.source.baseUrl + url, {
        Cookie: `.AspNetCore.Identity.Application=${new SharedPreferences().get("cookies")}`
      });
    } else {
      res = await new Client().get(this.source.baseUrl + url);
    }
    const doc = new Document(res.body);
    const items = [];
    const elements = doc.select("div.m-week-square");
    for (const element of elements) {
      const url = element.selectFirst("a").attr("href");
      if (url == "javascript:void(0);") {
        continue;
      }
      const title = element.selectFirst("a").attr("title");
      const cover = this.source.baseUrl + element.selectFirst("img").attr("data-src");
      items.push({
        name: title,
        imageUrl: cover,
        link: url
      });
    }
    return {
      list: items,
      hasNextPage: false
    };
  }

  async getPopular(page) {
    return await this.getItems("/Home/MyBangumi", true);
  }

  async getLatestUpdates(page) {
    return await this.getItems("", false);
  }

  async search(query, page, filters) {
    const res = await new Client().get(this.source.baseUrl + `/Home/Search?searchstr=${query}`);
    const doc = new Document(res.body);
    const items = [];
    const elements = doc.select("div.central-container ul.list-inline li");
    for (const element of elements) {
      const title = element.selectFirst("div.an-text").text;
      const cover = this.source.baseUrl + element.selectFirst("span").attr("data-src");
      const url = element.selectFirst("a").attr("href");
      items.push({
        name: title,
        imageUrl: cover,
        link: url
      });
    }
    return {
      list: items,
      hasNextPage: false
    };
  }

  async getDetail(url) {
    const res = await new Client().get(this.source.baseUrl + url);
    const doc = new Document(res.body);
    const cover = this.source.baseUrl + doc.selectFirst("div.content img").attr("src");
    const title = doc.selectFirst("p.title").text;
    const desc = doc.selectFirst("div.info").text;
    const eps = [];
    const lists = doc.select("div.m-bangumi-list-content");
    for (const list of lists) {
      //const header = list.selectFirst("span.title").text;
      for (const item of list.select("div.m-bangumi-item")) {
        const title = item.selectFirst("div.text").text;
        const url = this.source.baseUrl + item.selectFirst("div.right a").attr("href");
        const date = this.dateStringToTimestamp(item.selectFirst("div.date").text.split(" ")[0]);
        eps.push({
          name: title,
          url: url,
          dateUpload: date.toString()
        });
      }
    }
    eps.reverse();
    return {
      name: title,
      imageUrl: cover,
      description: desc,
      episodes: eps
    };
  }


  getFilterList() {
    throw new Error("getFilterList not implemented");
  }

  getSourcePreferences() {
    return [{
      "key": "cookies",
      "editTextPreference": {
        "title": "用户Cookies",
        "summary": "用于读取用户订阅的Cookies（.AspNetCore.Identity.Application）",
        "value": "",
        "dialogTitle": "Cookies",
        "dialogMessage": "",
      }
    }];
  }
}

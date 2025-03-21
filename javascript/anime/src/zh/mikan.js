const mangayomiSources = [{
  "name": "蜜柑计划",
  "lang": "zh",
  "baseUrl": "https://mikanani.me",
  "apiUrl": "",
  "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.mikan.png",
  "typeSource": "torrent",
  "itemType": 1,
  "isNsfw": false,
  "version": "0.0.3",
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

  baseURL () {
    const preference = new SharedPreferences();
    var base_url = preference.get("domain_url");
    if (base_url.endsWith("/")) {
      base_url = base_url.slice(0, -1);
    }
    return base_url;
  }

  getHeaders(url) {
    throw new Error("getHeaders not implemented");
  }

  async getItems(url, cookies) {
    var res;
    if (cookies) {
      const identity = new SharedPreferences().get("cookies");
      res = await new Client().get(this.baseURL() + url, {
        Cookie: `.AspNetCore.Identity.Application=${identity}`
      });
      if (res.body.search("退出登录") == -1) {
        return {
          list: [{name: "请设置Cookies", link: "", imageUrl: "https://mikan.tangbai.cc/images/mikan-pic.png"}],
          hasNextPage: false
        }
      }
    } else {
      res = await new Client().get(this.baseURL() + url);
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
      const cover = this.baseURL() + element.selectFirst("img").attr("data-src");
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
    const res = await new Client().get(this.baseURL() + `/Home/Search?searchstr=${query}`);
    const doc = new Document(res.body);
    const items = [];
    const elements = doc.select("div.central-container ul.list-inline li");
    for (const element of elements) {
      const title = element.selectFirst("div.an-text").text;
      const cover = this.baseURL() + element.selectFirst("span").attr("data-src");
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
    const res = await new Client().get(this.baseURL() + url);
    const doc = new Document(res.body);
    const cover = this.baseURL() + doc.selectFirst("div.content img").attr("src");
    const title = doc.selectFirst("p.title").text;
    const desc = doc.selectFirst("div.info").text;
    const eps = [];
    const lists = doc.select("div.m-bangumi-list-content");
    for (const list of lists) {
      //const header = list.selectFirst("span.title").text;
      for (const item of list.select("div.m-bangumi-item")) {
        const title = item.selectFirst("div.text").text;
        const url = this.baseURL() + item.selectFirst("div.right a").attr("href");
        const date = this.dateStringToTimestamp(item.selectFirst("div.date").text.split(" ")[0]);
        eps.push({
          name: title,
          url: url,
          dateUpload: date.toString()
        });
      }
    }
    //eps.reverse();
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
      "key": "domain_url",
      "editTextPreference": {
          "title": "Url",
          "summary": "蜜柑计划网址",
          "value": "https://mikanani.me",
          "dialogTitle": "URL",
          "dialogMessage": "",
      }
    },{
      "key": "cookies",
      "editTextPreference": {
        "title": "用户Cookies（在webview中登陆则可不设）",
        "summary": "用于读取用户订阅的Cookies（.AspNetCore.Identity.Application）",
        "value": "",
        "dialogTitle": "Cookies",
        "dialogMessage": "",
      }
    }];
  }
}
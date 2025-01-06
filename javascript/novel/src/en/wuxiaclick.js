const mangayomiSources = [{
    "name": "WuxiaClick",
    "lang": "en",
    "baseUrl": "https://wuxia.click",
    "apiUrl": "",
    "iconUrl":
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/en.wuxiaclick.png",
    "typeSource": "single",
    "itemType": 2,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "novel/src/en/wuxiaclick.js",
    "appMinVerReq": "0.4.0",
    "isNsfw": false,
    "hasCloudflare": false
  }];
  
  class DefaultExtension extends MProvider {
    getHeaders(url) {
      throw new Error("getHeaders not implemented");
    }
  
    mangaListFromPage(res) {
      const doc = new Document(res.body);
      const mangaElements = doc.select("div.page-item-detail");
      const list = [];
      for (const element of mangaElements) {
        const name = element.selectFirst(".item-thumb > a").attr("title");
        const link = element.selectFirst(".item-thumb > a").getHref;
        const imageUrl = element.selectFirst("img").getSrc;
        list.push({ name, imageUrl, link });
      }
      const hasNextPage =
        doc.selectFirst("nav > div.nav-links > a").text?.includes("Posts") ?? false;
      return { list: list, hasNextPage };
    }
  
    toStatus(status) {
      if (status.includes("OnGoing")) return 0;
      else if (status.includes("Completed")) return 1;
      else if (status.includes("Hiatus")) return 2;
      else if (status.includes("Dropped")) return 3;
      else return 5;
    }
  
    async getPopular(page) {
      const res = await new Client().get(
        `${this.source.baseUrl}/manga-genre/novel/page/${page}/?m_orderby=trending`,
      );
      return this.mangaListFromPage(res);
    }
  
    async getLatestUpdates(page) {
      const res = await new Client().get(
        `${this.source.baseUrl}/manga-genre/novel/page/${page}/?m_orderby=latest`,
      );
      return this.mangaListFromPage(res);
    }
  
    async search(query, page, filters) {
      let url = `${this.source.baseUrl}/?s=${query}`;
      const res = await new Client().get(url);
      return this.mangaListFromPage(res);
    }
  
    async getDetail(url) {
      const client = new Client();
      const res = await client.get(url);
      const doc = new Document(res.body);
      const imageUrl = doc.selectFirst("div.summary_image > a > img")?.getSrc;
      const description = doc.select("div.summary__content > p > span").map((el) => el.text).join(" ");
      const author = doc.selectFirst("div.author-content > a")?.text.trim();
      const artist = doc.selectFirst("div.artist-content > a")?.text.trim();
      const status = this.toStatus(doc.selectFirst("div.post-status > div.post-content_item > div.summary-content")?.text.trim());
      const tags = doc.select("div.summary-content > div.tags-content > a").map((el) => el.text.trim());
      let genre = doc.select("div.summary-content > div.genres-content > a").map((el) => el.text.trim());
      if (tags.length != 0) {
        genre.push(tags);
      }

      const chapters = [];
      const chapterRes = await client.post(`${url}ajax/chapters/`, {
        Priority: "u=0, i",
        "Origin": this.source.baseUrl,
        "Referer": url,
      });
      const chapterDoc = new Document(chapterRes.body);

      const chapterElements = chapterDoc.select("li.free-chap");
      for (const el of chapterElements) {
        let chapterName = el.selectFirst("a")?.text.trim();
        const chapterUrl = el.selectFirst("a").getHref;
        let dateUpload; 
        try {
          dateUpload = this.parseDate(el.selectFirst("span.chapter-release-date > i")?.text.trim());
        } catch (_) {
          dateUpload = null;
        }
        chapters.push({
          name: chapterName,
          url: chapterUrl,
          dateUpload: dateUpload,
          scanlator: null,
        });
      }
  
      chapters.reverse();
  
      return {
        imageUrl,
        description,
        genre,
        author,
        artist,
        status,
        chapters,
      };
    }
  
    async getHtmlContent(url) {
      const client = await new Client();
      const res = await client.get(url);
      const doc = new Document(res.body);
      const title =
          doc.selectFirst("#chapter-heading")?.text.trim() ||
          "";
      const content = doc.selectFirst(".entry-content")?.innerHtml;
      return `<h2>${title}</h2><hr><br>${content}`;
    }
  
    getFilterList() {
      return [];
    }
  
    getSourcePreferences() {
      throw new Error("getSourcePreferences not implemented");
    }

    parseDate(date) {
        const months = {
          "January": "01", "February": "02", "March": "03", "April": "04", "May": "05", "June": "06", 
          "July": "07", "August": "08", "September": "09", "October": "10", "November": "11", "December": "12"
        };
        date = date.toLowerCase().replace(",", "").split(" ");

        if (!(date[0] in months)) {
            return String(new Date().valueOf())
        }
        
        date[0] = months[date[0]];
        date = [date[2], date[0], date[1]];
        date = date.join("-");
        return String(new Date(date).valueOf());
    }
  }

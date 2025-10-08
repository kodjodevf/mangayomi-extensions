const mangayomiSources = [{
    "name": "Web Novel Translations",
    "lang": "en",
    "baseUrl": "https://webnoveltranslations.com",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/entityJY/mangayomi-extensions-eJ/main/javascript/icon/en.webnoveltranslations.png",
    "typeSource": "single",
    "itemType": 2,
    "version": "1.0.0",
    "pkgPath": "novel/src/en/webnoveltranslations.js",
    "notes": ""
}];

class DefaultExtension extends MProvider {
  
    mangaListFromPage(res) {
        const doc = new Document(res.body);
        const mangaElements = doc.select(".row.c-tabs-item__content");
        const list = [];
        for (const element of mangaElements) {
          const name = element.selectFirst("h3")?.text.trim();
          const imageUrl = element.selectFirst("img").getSrc;
          const link = element.selectFirst(".tab-thumb.c-image-hover > a").getHref;
          list.push({ name, imageUrl, link });
        }
        const hasNextPage = false;
        return { list: list, hasNextPage };
    }

    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }
    
    async getPopular(page) {
        let url = `${this.source.baseUrl}/?s=&post_type=wp-manga`;
        const res = await new Client().get(url, this.headers);
        return this.mangaListFromPage(res);
    }
    
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    
    async getLatestUpdates(page) {
        throw new Error("getLatestUpdates not implemented");
        let url = this.source.baseUrl;
        const res = await new Client().get(url, this.headers);
        const doc = new Document(res.body);
        const mangaElements = doc.select("#loop-content > div");
        const list = [];
        for (const element of mangaElements) {
          const name = element.selectFirst("div.post-title.font-title")?.text.trim();
          const imageUrl = element.selectFirst("img").getSrc;
          const link = element.selectFirst(".item-summary > a").getHref;
          list.push({ name, imageUrl, link });
        }
        const hasNextPage = false;
        return { list: list, hasNextPage };
    }
    async search(query, page, filters) {
        let url = `${this.source.baseUrl}/?s=${query}&post_type=wp-manga`;
        const res = await new Client().get(url, this.headers);
        return this.mangaListFromPage(res);
    }
    async getDetail(url) {
        const client = new Client();
        const res = await client.get(url, this.headers);
        const doc = new Document(res.body);
        const main = doc.selectFirst('.site-content');
        
        const name = doc.selectFirst("div.post-title > h1").text.trim();;
        
        const link = url;
        
        let description = "";
        for (const element of doc.select(".summary__content > p")) {
          description += element.text;
        }
        
        const genre = doc.select("div.genres-content > a").map((el) => el.text.trim());
        
        const author = doc.selectFirst("div.author-content > a").text.trim();
        
        const status_string = doc.selectFirst("div.post-status > div.summary-content")?.text.trim();
        let status = -1;
        if (status_string === "OnGoing") {
          status = 0;
        } else {
          status = 5;
        }
        
        
        const chapterRes = await client.post(url + "ajax/chapters/?t=1", {"x-requested-with": "XMLHttpRequest"});
        const chapterDoc = new Document(chapterRes.body);
        
        let chapters = [];
        for (const chapter of chapterDoc.select("li.wp-manga-chapter ")) {
          chapters.push({
            name: chapter.selectFirst("a").text.trim(),
            url: chapter.selectFirst("a").getHref,
            dateUpload: null,
            scanlator: null,
          });
        }
        
        return {
          name,
          link,
          description,
          genre,
          author,
          status,
          chapters,
        };
    }
    // For novel html content
    async getHtmlContent(name, url) {
        const client = await new Client();
        const res = await client.get(url);
        
        const html = await this.cleanHtmlContent(res.body);
        
        return html;
    }
    // Clean html up for reader
    async cleanHtmlContent(html) {
        const doc = new Document(html);
        const title = doc.selectFirst("#chapter-heading")?.text.trim() || "";
        
        const content = doc.select("#novel-chapter-container.text-left > p");
        let chapterContent = "";
        for (const line of content) {
          chapterContent += "<p>" + line.text + "</p>";
        };
        return `<h2>${title}</h2><hr><br>${chapterContent}`;
    }
    // For anime episode video list
    async getVideoList(url) {
        throw new Error("getVideoList not implemented");
    }
    // For manga chapter pages
    async getPageList(url) {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

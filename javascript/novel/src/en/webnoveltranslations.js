const mangayomiSources = [{
    "name": "Web Novel Translations",
    "lang": "en",
    "baseUrl": "https://webnoveltranslations.com",
    "apiUrl": "",
    "iconUrl": "data:image/png;base64,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",
    "typeSource": "single",
    "itemType": 2,
    "version": "0.0.1",
    "pkgPath": "",
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
        // const res = await client.get(this.source.baseUrl + url, this.headers);
        const res = await client.get(url, this.headers);
        const doc = new Document(res.body);
        const main = doc.selectFirst('.site-content');
        
        let description = "";
        for (const element of doc.select(".summary__content > p")) {
          description += element.text;
        }
        
        const genre = doc.select("div.genres-content > a").map((el) => el.text.trim());
        
        const author = doc.selectFirst("div.author-content > a").text.trim();
        
        //const status = doc.selectFirst("div.post-status > .summary-content")?.text.trim();
        const status = 5;
        
        
        const chapterRes = await client.post(url + "ajax/chapters/?t=1", {"x-requested-with": "XMLHttpRequest"});
        const chapterDoc = new Document(chapterRes.body);
        
        let chapters = [];
        for (const chapter of chapterDoc.select("li.wp-manga-chapter ")) {
          chapters.push({
            name: chapter.selectFirst("a").text.trim(),
            url: chapter.selectFirst("a").getHref,
            dateUpload: chapter.selectFirst('i').text,
            //dateUpload: "",
            scanlator: null,
          });
        }
        
        console.log(chapters[0]);
        console.log(chapters[30]);
        
        return {
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

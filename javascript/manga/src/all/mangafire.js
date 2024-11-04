const languages = ["en", "ja", "fr", "es", "es-la", "pt", "pt-br"];
const mangayomiSources = languages.map(lang => {
    return {
        "name": "Mangafire",
        "lang": lang,
        "baseUrl": "https://mangafire.to",
        "apiUrl": "",
        "iconUrl": "https://mangafire.to/assets/sites/mangafire/favicon.png?v3",
        "typeSource": "single",
        "isManga": true,
        "version": "0.0.1",
        "dateFormat": "",
        "dateFormatLocale": "",
        "pkgPath": "manga/src/all/mangafire.js"
    };
});

class DefaultExtension extends MProvider {
    mangaListFromPage(res) {
        const doc = new Document(res.body);
        const elements = doc.select("div.unit");
        const list = [];

        for (const element of elements){
          const name = element.selectFirst("div.info > a").text;
          const imageUrl = element.selectFirst("img").getSrc;
          const link = element.selectFirst("a").getHref;
          list.push({name, imageUrl, link});
        }

        const hasNextPage = doc.selectFirst("li.page-item.active + li").text != "";
        return { "list": list, "hasNextPage": hasNextPage };
    }

    statusFromString(status){
        if (status == "Releasing")
            return 0;
        else if (status == "Completed")
            return 1;
        else if (status == "On_Hiatus")
            return 2;
        else if (status == "Discontinued")
            return 3;
        else
            return 5;
    }

    parseDate(date) {
        const months = {
          "jan": "01", "feb": "02", "mar": "03", "apr": "04", "may": "05", "jun": "06", "jul": "07", "aug": "08", "sep": "09", "oct": "10", "nov": "11", "dec": "12"
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

    async getPopular(page) {
        console.log(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=trending&page=${page}`);
        const res = await new Client().get(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=trending&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getLatestUpdates(page) {
        const res = await new Client().get(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=recently_updated&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async search(query, page, filters) {
        query = query.trim().replaceAll(/\ +/g, "+");
        const res = await new Client().get(`${this.source.baseUrl}/filter?keyword=${query}&language=${this.source.lang}&sort=most_relevance&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getDetail(url) {
        // get urls
        const id = url.split(".").pop();
        const infoUrl = this.source.baseUrl + url;
        const chapterUrl = `https://mangafire.to/ajax/read/${id}/chapter/${this.source.lang}`;
        const detail = {};
        
        // request
        const idRes = await new Client().get(chapterUrl);
        const idDoc = new Document(JSON.parse(idRes.body).result.html);
        const infoRes = await new Client().get(infoUrl);
        const infoDoc = new Document(infoRes.body);
        
        // extract info
        const info = infoDoc.selectFirst("div.info");
        const sidebar = infoDoc.select("aside.sidebar div.meta div");
        detail.name = info.selectFirst("h1").text;
        detail.status = this.statusFromString(info.selectFirst("p").text);
        detail.imageUrl = infoDoc.selectFirst("div.poster img").getSrc;
        detail.author = sidebar[0].selectFirst("a").text;
        detail.description = infoDoc.selectFirst("div#synopsis").text.trim();
        detail.genre = sidebar[2].select("a");
        detail.genre.forEach((e, i) => {
            detail.genre[i] = e.text;
        });

        // get chapter
        const ids = idDoc.select("a");
        const dates = infoDoc.select("div.list-body > ul.scroll-sm > li > a > span + span");
        detail.chapters = [];
        for (let i = 0; i < ids.length; i++) {
            const name = ids[i].text;
            const id = ids[i].attr("data-id");
            const url = `https://mangafire.to/ajax/read/chapter/${id}`;
            const dateUpload = this.parseDate(dates[i].text);
            detail.chapters.push({name, url, dateUpload});
        }
        return detail;
    }

    // For manga chapter pages
    async getPageList(url) {
        const res = await new Client().get(url);
        const data = JSON.parse(res.body);
        const pages = [];
        data.result.images.forEach(img => {
            pages.push(img[0]);
        });
        return pages;
    }

    getFilterList() {
        throw new Error("getFilterList not implemented");
    }

    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

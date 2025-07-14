const mangayomiSources = [{
    "name": "Toptoon頂通",
    "lang": "zh",
    "baseUrl": "https://www.toptoon.net",
    "apiUrl": "",
    "iconUrl": "https://tw-assets.toptoon.net/www_v1/img/app_icon/android-icon-192x192.png",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.1.0",
    "pkgPath": "manga/src/zh/toptoon.js",
    "isNsfw": true,
    "notes": "Log in and confirm adult in WebView"
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client({"useDartHttpClient": true, "followRedirects": false});
    }
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }
    async getPopular(page) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/ranking`);
        const json_url = res.body.substringAfter('jsonFileUrl: ["').substringBefore('"').replaceAll('\\/', '/');
        const res_json = await this.client.get(`https:${json_url}`);
        const comicJson = JSON.parse(res_json.body);
        const list = [];
        for (const comic of Object.values(comicJson.adult)) {
                list.push({
                    'name': comic.meta.title,
                    'imageUrl': "https://tw-contents-image.toptoon.net" + comic.thumbnail.standard,
                    'link': `/comic/epList/${comic.id}`
                });
        }
        return {
          'list': list, 'hasNextPage': false
        };
    }
    get supportsLatest() {
        return true;
    }
    async getLatestUpdates(page) {
        // Only 7 pages
        if (page > 7) {
            return {
                'list': [], 'hasNextPage': false
            };
        }
        const dayOfWeek = new Date().getDay();
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/weekly`);
        const json_urls = res.body.substringAfter('jsonFileUrl: ["').substringBefore(']"').replaceAll('\\/', '/').split('","');
        const res_json = await this.client.get(`https:${json_urls[(dayOfWeek - page + 7) % 7]}`);
        const comicJson = JSON.parse(res_json.body);
        const list = [];
        for (const comic of Object.values(comicJson.adult)) {
                list.push({
                    'name': comic.meta.title,
                    'imageUrl': "https://tw-contents-image.toptoon.net" + comic.thumbnail.standard,
                    'link': `/comic/epList/${comic.id}`
                });
        }
        return {
          'list': list, 'hasNextPage': page < 7
        };
    }
    async search(query, page, filters) {
        const query_lower = query.toLowerCase();
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/search`);
        const json_url = res.body.substringAfter("var jsonFileUrl = '").substringBefore("'");
        const comicJson = JSON.parse((await this.client.get(`https:${json_url}`)).body);
        const list = [];
        for (const comic of Object.values(comicJson)) {
            if (comic.meta.title.toLowerCase().includes(query_lower) || comic.meta.author.authorString.toLowerCase().includes(query_lower)) {
                list.push({
                    'name': comic.meta.title,
                    'imageUrl': "https://tw-contents-image.toptoon.net" + comic.thumbnail.standard,
                    'link': `/comic/epList/${comic.id}`
                });
            }
        }
        return {
            'list': list, 'hasNextPage': false
        }
    }
    async getDetail(url) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(baseUrl + url);
        if (res.isRedirect) {
            if (res.headers["set-cookie"].includes("openAlertUrl=confirmAdult")) {
                throw new Error("Please confirm adult in WebView");
            }
            throw new Error("Unknown error");
        }
        const document = new Document(res.body);
        const name = document.selectFirst("section.infoContent div.title").text.trim();
        const description = document.selectFirst("div.comic_story div.desc").text;
        const author = document.selectFirst("section.infoContent div.etc").text.split("作家 : ")[1].split("|")[0].trim();
        const chapters = document.select("section.episode_area ul.list_area li.episodeBox").map(chapter => {
            return {
                'name': chapter.selectFirst('div.title').text.trim(),
                'url': chapter.selectFirst('a').attr("href")
            }
        });
        return {name, description, author, chapters};
    }
    // For novel html content
    async getHtmlContent(name, url) {
        throw new Error("getHtmlContent not implemented");
    }
    // Clean html up for reader
    async cleanHtmlContent(html) {
        throw new Error("cleanHtmlContent not implemented");
    }
    // For anime episode video list
    async getVideoList(url) {
        throw new Error("getVideoList not implemented");
    }
    // For manga chapter pages
    async getPageList(url) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(baseUrl + url);
        if (res.isRedirect) {
            const cookie = res.headers["set-cookie"];
            if (cookie.includes("openAlertUrl=formLogin")) {
                throw new Error("Please login in WebView");
            }
            if (cookie.includes("openAlertUrl=confirmAdult")) {
                throw new Error("Please confirm adult in WebView");
            }
            if (cookie.includes("openAlertUrl=formLowCoinPayment") || cookie.includes("openAlertUrl=confirmBuyEpisode")) {
                throw new Error("Please buy chapter");
            }
            throw new Error("Unknown error");
        }
        const document = new Document(res.body);
        return document.select("article.epContent section.imgWrap div.cImg img").map(image => {
            return {"url": "https:" + image.attr("data-src")}
        });
    }
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

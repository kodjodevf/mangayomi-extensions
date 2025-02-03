const mangayomiSources = [{
    "name": "Animeparadise",
    "lang": "en",
    "baseUrl": "https://animeparadise.moe",
    "apiUrl": "https://api.animeparadise.moe",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://animeparadise.moe",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.0.3",
    "pkgPath": "anime/src/en/animeparadise.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }

    async extractFromUrl(url) {
        var res = await new Client().get(url);
        var doc = new Document(res.body);
        var jsonData = doc.selectFirst("#__NEXT_DATA__").text
        return JSON.parse(jsonData).props.pageProps.data;
    }

    async requestAPI(slug) {
        var api = `${this.source.apiUrl}/${slug}`
        var response = await new Client().get(api);
        var body = JSON.parse(response.body);
        return body;
    }

    async formList(slug) {
        var jsonData = await this.requestAPI(slug);
        var list = [];
        if ("episodes" in jsonData) {
            jsonData.episodes.forEach(item => {
                list.push({
                    "name": item.origin.title,
                    "link": item.origin.link,
                    "imageUrl": item.image
                });
            })
        } else {
            jsonData.data.forEach(item => {
                list.push({
                    "name": item.title,
                    "link": item.link,
                    "imageUrl": item.posterImage.original
                });
            })
        }

        return {
            "list": list,
            "hasNextPage": false
        }

    }

    async getPopular(page) {
        return await this.formList('?sort={"rate": -1 }')
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        var slug = '?sort={"postDate": -1 }';

        var choice = this.getPreference("animeparadise_pref_latest_tab");
        if (choice === "recent_ep") slug = 'ep/recently-added';

        return await this.formList(slug)
    }
    async search(query, page, filters) {
        throw new Error("search not implemented");
    }
    statusCode(status) {
        return {
            "current": 0,
            "finished": 1,
        }[status] ?? 5;
    }

    async getDetail(url) {
        var link = this.source.baseUrl + `/anime/${url}`
        var jsonData = await this.extractFromUrl(link)
        var details = {}
        var chapters = []
        details.name = jsonData.title
        details.link = link
        details.imageUrl = jsonData.posterImage.original
        details.description = jsonData.synopsys
        details.genre = jsonData.genres
        details.status = this.statusCode(jsonData.status)
        var id = jsonData._id
        var epAPI = await this.requestAPI(`anime/${id}/episode`)
        epAPI.data.forEach(ep => {
            var epName = `E${ep.number}: ${ep.title}`;
            var epUrl = `${ep.uid}?origin=${ep.origin}`
            chapters.push({ name: epName, url: epUrl })
        })
        details.chapters = chapters.reverse();
        return details;
    }
    // For novel html content
    async getHtmlContent(url) {
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
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    getSourcePreferences() {
        return [{
            key: 'animeparadise_pref_latest_tab',
            listPreference: {
                title: 'Latest tab category',
                summary: 'Anime list to be shown in latest tab',
                valueIndex: 0,
                entries: ["Recently added anime", "Recently added episode"],
                entryValues: ["recent_ani", "recent_ep"]
            }
        },]
    }
}

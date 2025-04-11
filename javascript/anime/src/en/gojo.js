const mangayomiSources = [{
    "name": "Gojo",
    "lang": "en",
    "baseUrl": "https://gojo.wtf",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://gojo.wtf/",
    "typeSource": "multi",
    "itemType": 1,
    "version": "0.0.1",
    "pkgPath": "anime/src/en/gojo.js"
}];

class DefaultExtension extends MProvider {
    getHeaders() {
        return {
            'Referer': this.source.baseUrl,
            'Origin': this.source.baseUrl,
            'User-Agent': "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4084.56 Safari/537.3"
        }
    }

    constructor() {
        super();
        this.client = new Client();
    }

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }


    async gojoAPI(slug) {
        var url = `https://backend.gojo.wtf/api/anime${slug}`
        var res = await this.client.post(url, this.getHeaders())
        if (res.statusCode != 200) return null
        return JSON.parse(res.body)
    }

    getTitle(data) {
        var pref = this.getPreference('gojo_pref_title')
        if (data.hasOwnProperty(pref)) {
            return data[pref]
        }
        return data['romaji']
    }

    formatList(animeList) {
        var list = []
        // 
        animeList.forEach(anime => {
            var name = this.getTitle(anime.title)
            var image = anime.coverImage
            var imageUrl = ""
            if (typeof (image) == 'object' && image.hasOwnProperty('large')) {
                imageUrl = image.large
            } else {
                imageUrl = image
            }
            var link = ""+anime.id

            list.push({ name, imageUrl, link });
        })
        return list
    }

    async getPopular(page) {
        var list = []
        var res = await this.gojoAPI("/home")
        if (res != null) {
            list.push(...this.formatList(res.popular))
            list.push(...this.formatList(res.trending))
            list.push(...this.formatList(res.seasonal))
            list.push(...this.formatList(res.top))
        }
        return { list, hasNextPage: true }
    }

    async getLatestUpdates(page) {
        var list = []
        var res = await this.gojoAPI(`/recent?type=anime&page=${page}&perPage=30`)
        if (res != null) {
            list.push(...this.formatList(res))
        }
        var hasNextPage = true;
        if(list.length < 30) hasNextPage = false;

        return { list, hasNextPage }
    }

    async search(query, page, filters) {
        var list = []
        var hasNextPage = false;

        var res = await this.gojoAPI(`/search?query=${query}&page=${page}&perPage=30`)
        if (res != null) {
            list.push(...this.formatList(res.results))
            if(res.lastPage < page) hasNextPage = true;
        }
        
        return { list, hasNextPage }
    }


    async getDetail(url) {
        throw new Error("getDetail not implemented");
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
        return [
            {
                key: "gojo_pref_title",
                listPreference: {
                    title: "Preferred Title",
                    summary: "",
                    valueIndex: 0,
                    entries: ["Romaji", "English", "Native"],
                    entryValues: ["romaji", "english", "native"],
                }
            },
        ]
    }
}

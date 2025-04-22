const mangayomiSources = [{
    "name": "KissKH",
    "lang": "all",
    "baseUrl": "https://kisskh.ovh",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.kisskh.jpg",
    "typeSource": "multi",
    "itemType": 1,
    "version": "0.0.1",
    "pkgPath": "anime/src/all/kisskh.js"
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    getHeaders() {
        return {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6832.64 Safari/537.36",
            "Referer": this.source.baseUrl,
            "Origin": this.source.baseUrl,
        }
    }

    getBaseUrl() {
        return this.getPreference("kisskh_base_url");
    }

    async request(slug) {
        try {
            var baseUrl = this.getBaseUrl();
            var api = baseUrl + `/api/DramaList${slug}`;
            var res = await this.client.get(api, { headers: this.getHeaders() });
            return JSON.parse(res.body);
        } catch (e) {
            console.log(e);
        }
        return [];
    }

    async formatpageList(slug) {
        var res = await this.request(slug);
        var list = []
        var hasNextPage = false

        for (var media of res) {
            var name = media.title
            var imageUrl = media.thumbnail
            var link = "" + media.id

            list.push({ name, imageUrl, link });
        }
        return { list, hasNextPage }
    }

    async getPopular(page) {
        var mostViewed = await this.formatpageList("/MostView?c=1");
        var topRated = await this.formatpageList("/TopRating");

        var list = [...mostViewed.list, ...topRated.list]
        return { list, hasNextPage: false };
    }

    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }

    async getLatestUpdates(page) {
        return await this.formatpageList("/LastUpdate");
    }
    async search(query, page, filters) {
        return await this.formatpageList(`/Search?q=${query}&type=0`);
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
                key: "kisskh_base_url",
                editTextPreference: {
                    title: "Override base url",
                    summary: "",
                    value: "https://kisskh.ovh",
                    dialogTitle: "Override base url",
                    dialogMessage: "",
                }
            },
        ]
    }
}

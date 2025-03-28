const mangayomiSources = [{
    "name": "Animeonsen",
    "lang": ["en", "ja"],
    "baseUrl": "https://www.animeonsen.xyz",
    "apiUrl": "https://api.animeonsen.xyz",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://www.animeonsen.xyz",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.0.2",
    "pkgPath": "anime/src/all/animeonsen.js"
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    async getToken() {
        const preferences = new SharedPreferences();
        var token_ts = parseInt(preferences.getString("animeosen_token_expiry_at", "0"))
        var now_ts = parseInt(new Date().getTime() / 1000);

        // token lasts for 7days but still checking after 6days
        if (now_ts - token_ts > 60 * 60 * 24 * 6) {
            var tokenBody = {
                client_id: "f296be26-28b5-4358-b5a1-6259575e23b7",
                client_secret: "349038c4157d0480784753841217270c3c5b35f4281eaee029de21cb04084235",
                grant_type: "client_credentials"
            }
            var res = await this.client.post("https://auth.animeonsen.xyz/oauth/token", {}, tokenBody)
            res = JSON.parse(res.body)
            var token = res.access_token
            preferences.setString("animeosen_token", token);
            preferences.setString("animeosen_token_expiry_at", "" + now_ts);
            return token
        } else {
            return preferences.getString("animeosen_token", "");

        }
    }

    async getHeaders(slug) {
        var brToken = ""
        if (slug.endsWith("/search")) {
            brToken = "0e36d0275d16b40d7cf153634df78bc229320d073f565db2aaf6d027e0c30b13"
        }
        else {
            brToken = await this.getToken()
        }

        return {
            'Authorization': `Bearer ${brToken}`,
            'content-type': "application/json"
        }
    }

    async request(slug, body = {}) {

        var headers = await this.getHeaders(slug)

        if (slug.endsWith("/search")) {

            var api = `https://search.animeonsen.xyz${slug}`
            var res = await this.client.post(api, headers, body)
            return JSON.parse(res.body)
        }
        var api = `${this.source.apiUrl}${slug}`
        var res = await this.client.get(api, headers)
        return JSON.parse(res.body)
    }

    animeContent(anime, pref_name, imgRes) {
        var name_eng = anime.content_title_en
        var name_jp = anime.content_title
        var name = pref_name == "jpn" ? name_jp : name_eng;
        var link = anime.content_id
        var imageUrl = `${this.source.apiUrl}/v4/image/${imgRes}/${link}`
        return { name, imageUrl, link };
    }

    async getHome(page) {
        var limit = 20
        var start = (page - 1) * limit;

        var slug = `/v4/content/index?start=${start}&limit=${limit}`
        var res = await this.request(slug)

        var pref_name = this.getPreference("animeonsen__pref_title_lang")
        var imgRes = this.getPreference("animeonsen__pref_img_res")

        var hasNextPage = res.cursor.next[0]
        var list = []
        for (var anime of res.content) {
            list.push(this.animeContent(anime, pref_name, imgRes));
        }
        return { list, hasNextPage }
    }

    async getPopular(page) {
        return await this.getHome(page)
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        return await this.getHome(page)
    }
    async search(query, page, filters) {
        var slug = "/indexes/content/search"

        var limit = 30;
        var offset = (page - 1) * limit;
        var nextOffset = offset + limit;

        var params = { limit, offset, q: query };

        var res = await this.request(slug, params);

        var estimatedTotalHits = res.estimatedTotalHits
        var hasNextPage = estimatedTotalHits > nextOffset;

        var list = []
        var hits = res.hits
        var pref_name = this.getPreference("animeonsen__pref_title_lang")
        var imgRes = this.getPreference("animeonsen__pref_img_res")
        if (hits.length > 0) {
            for (var anime of hits) {
                list.push(this.animeContent(anime, pref_name, imgRes));
            }
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
        return [{
            key: 'animeonsen__pref_title_lang',
            listPreference: {
                title: 'Preferred title language',
                summary: '',
                valueIndex: 0,
                entries: ["Japenese", "English"],
                entryValues: ["jpn", "en"]
            }
        }, {
            key: 'animeonsen__pref_img_res',
            listPreference: {
                title: 'Preferred image resolution',
                summary: '',
                valueIndex: 1,
                entries: ["Low", "Medium", "High"],
                entryValues: ["240x300", "480x600", "960x1200"]
            }
        }];
    }
}

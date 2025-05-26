const mangayomiSources = [{
    "name": "Animeonsen",
    "langs": ["en", "ja"],
    "baseUrl": "https://www.animeonsen.xyz",
    "apiUrl": "https://api.animeonsen.xyz",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://www.animeonsen.xyz",
    "typeSource": "single",
    "itemType": 1,
    "version": "1.0.1",
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
        var api = `${this.source.apiUrl}/v4/content${slug}`
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

        var slug = `/index?start=${start}&limit=${limit}`
        var res = await this.request(slug)

        var pref_name = this.getPreference("animeonsen__pref_title_lang")
        var imgRes = this.getPreference("animeonsen__pref_img_res_1")

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
        var imgRes = this.getPreference("animeonsen__pref_img_res_1")
        if (hits.length > 0) {
            for (var anime of hits) {
                list.push(this.animeContent(anime, pref_name, imgRes));
            }
        }
        return { list, hasNextPage }
    }

    statusCode(status) {
        return {
            "currently_airing": 0,
            "finished_airing": 1,
        }[status] ?? 5;
    }

    async getDetail(url) {
        var linkSlug = `${this.source.baseUrl}/details/`
        url = url.replace(linkSlug, "")
        var link = `${linkSlug}${url}`
        var detailsApiSlug = `/${url}/extensive`
        var animeDetails = await this.request(detailsApiSlug);
        
        var pref_name = this.getPreference("animeonsen_pref_ep_title_lang")
        var imgRes = this.getPreference("animeonsen__pref_img_res_1")

        var name_eng = animeDetails.content_title_en
        var name_jp = animeDetails.content_title
        var name = pref_name == "jpn" ? name_jp : name_eng;
        var link = animeDetails.content_id
        var imageUrl = `${this.source.apiUrl}/v4/image/${imgRes}/${link}`
        var is_movie = animeDetails.is_movie

        var mal_data = animeDetails.mal_data
        var description = mal_data.synopsis
        var genre = []
        mal_data.genres.forEach(g => genre.push(g.name))
        var status = this.statusCode(mal_data.status);

        var chapters = [];
        var episodeAPISlug = `/${url}/episodes`
        var episodeDetails = await this.request(episodeAPISlug);
        
        Object.keys(episodeDetails).forEach(ep => {
            var ep_data = episodeDetails[ep]

            var ep_name_eng = ep_data.contentTitle_episode_en
            var ep_name_jp = ep_data.contentTitle_episode_jp
            var ep_name = pref_name == "jpn" ? ep_name_jp : ep_name_eng;

            chapters.push({
                name:`E${ep}: ${ep_name}`,
                url: `/${url}/video/${ep}`,
            })
        })

        chapters.reverse()
        return { name, imageUrl, status, description, genre,link, chapters }
    }

    // For anime episode video list
    async getVideoList(url) {
        var streamDetails = await this.request(url);
        var streamData = streamDetails.uri

        var streams = [
            {
                quality:`Default (720p)`,
                url: streamData.stream,
                originalUrl: streamData.stream
            }
        ];

        var subtitles = [];
        var subData = streamDetails.subtitles;
        Object.keys(subData).forEach(sub => {
            subtitles.push({
                label:sub,
                file: subData[url]
            })
        });

        streams[0].subtitles = subtitles

        return streams
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
            key: 'animeonsen_pref_ep_title_lang',
            listPreference: {
                title: 'Preferred episode title language',
                summary: '',
                valueIndex: 1,
                entries: ["Japenese", "English"],
                entryValues: ["jpn", "en"]
            }
        },{
            key: 'animeonsen__pref_img_res_1',
            listPreference: {
                title: 'Preferred image resolution',
                summary: '',
                valueIndex: 1,
                entries: ["Low", "Medium", "High"],
                entryValues: ["210x300", "420x600", "840x1200"]
            }
        }];
    }
}

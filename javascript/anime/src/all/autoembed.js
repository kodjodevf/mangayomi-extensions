const mangayomiSources = [{
    "name": "Autoembed",
    "lang": "all",
    "baseUrl": "https://autoembed.cc",
    "apiUrl": "https://tom.autoembed.cc",
    "iconUrl": "https://www.google.com/s2/favicons?sz=64&domain=https://autoembed.cc/",
    "typeSource": "multi",
    "isManga": false,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": ""
}];

class DefaultExtension extends MProvider {
    tmdb_api = "https://94c8cb9f702d-tmdb-addon.baby-beamup.club";
    getHeaders(url) {
        return {
            Referer: this.source.apiUrl
        }
    }

    async tmdbSearchRequest(slug, page = 1) {
        var skip = (page - 1) * 20;
        const api = `${this.tmdb_api}/${slug}skip=${skip}.json`
        const response = await new Client().get(api);
        const body = JSON.parse(response.body);
        return body;
    }

    async getSearchItems(body) {
        var items = [];
        var results = body.metas;
        for (let i in results) {
            var result = results[i];
            var id = result.id
            var media_type = result.type;
            items.push({
                name: result.name,
                imageUrl: result.poster,
                link: `${media_type}/${id}`,
                description: result.description,
                genre: result.genre
            });
        }
        var hasNextPage = true;
        return {
            "list": items,
            hasNextPage
        };
    }

    async getPopular(page) {
        const preferences = new SharedPreferences();
        var media_type = preferences.get("pref_popular_page");
        var body = await this.tmdbSearchRequest(`catalog/${media_type}/tmdb.popular/`, page);
        return this.getSearchItems(body);
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        throw new Error("getLatestUpdates not implemented");
    }
    async search(query, page, filters) {
        throw new Error("search not implemented");
    }
    async getDetail(url) {
        var parts = url.split("/");
        var media_type = parts[0];
        var tmdbId = parts[1];
        var api = `${this.tmdb_api}/meta/${media_type}/${tmdbId}.json`
        const response = await new Client().get(api);
        const body = JSON.parse(response.body);
        var result = body.meta;
      
        var release = result.released ? new Date(result.released) : Date.now();

        var item = {
            name: result.name,
            imageUrl: result.poster,
            link: `${media_type}/${tmdbId}`,
            description: result.description,
            genre: result.genre,
        };
        var chaps = [];

        chaps.push({
            name: "Movie",
            url: `${media_type}/${result.imdb_id}`,
            dateUpload: release.valueOf().toString(),
        })

        item.chapters = chaps;

        return item;
    }

    async extractStreams(url) {
        const response = await new Client().get(url);
        const body = response.body;
        const lines = body.split('\n');
        var streams = [];

        for (let i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('#EXT-X-STREAM-INF:')) {
                const resolution = lines[i].match(/RESOLUTION=(\d+x\d+)/)[1];
                const m3u8Url = lines[i + 1].trim();

                streams.push({
                    url: m3u8Url,
                    originalUrl: m3u8Url,
                    quality: resolution,
                });
            }
        }     
        return streams;
    }

    // For anime episode video list
    async getVideoList(url) {
        var parts = url.split("/");
        var media_type = parts[0];
        var imdbId = parts[1];
        var api = `${this.source.apiUrl}/api/getVideoSource?type=${media_type}&id=${imdbId}`
        const response = await new Client().get(api, this.getHeaders());
        const body = JSON.parse(response.body);
        var link = body.videoSource
        var subtitles = body.subtitles
        var streams = await this.extractStreams(link);          
        streams.push({
            url: link,
            originalUrl: link,
            quality: "Auto",
            subtitles: subtitles,
        });

        return streams;
    }
    // For manga chapter pages
    async getPageList() {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        throw new Error("getSourcePreferences not implemented");
    }

    getSourcePreferences() {
        return [{
                key: 'pref_popular_page',
                listPreference: {
                    title: 'Preferred popular page',
                    summary: '',
                    valueIndex: 0,
                    entries: ["Movies", "TV Shows"],
                    entryValues: ["movie", "tv"]
                }
            },

        ];
    }
}
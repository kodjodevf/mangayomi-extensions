const mangayomiSources = [{
    "name": "Autoembed",
    "lang": "all",
    "baseUrl": "https://autoembed.cc",
    "apiUrl": "https://tom.autoembed.cc",
    "iconUrl": "https://www.google.com/s2/favicons?sz=64&domain=https://autoembed.cc/",
    "typeSource": "multi",
    "isManga": false,
    "version": "0.0.2",
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
        var id = parts[1];
        var api = `${this.tmdb_api}/meta/${media_type}/${id}.json`
        const response = await new Client().get(api);
        const body = JSON.parse(response.body);
        var result = body.meta;

        var tmdb_id = id.substring(5, )
        var imdb_id = result.imdb_id
        var dateNow = Date.now().valueOf();
        var release = result.released ? new Date(result.released).valueOf() : dateNow
        var chaps = [];

        var item = {
            name: result.name,
            imageUrl: result.poster,
            link: `https://imdb.com/title/${imdb_id}`,
            description: result.description,
            genre: result.genre,
        };

        if (media_type == "series") {

            var videos = result.videos
            for (var i in videos) {
                var video = videos[i];
                var seasonNum = video.season;

                if (!seasonNum) continue;

                var episodeNum = video.episode

                var eplink = `tv||${tmdb_id}/${seasonNum}/${episodeNum}`
                release = video.released ? new Date(video.released).valueOf() : dateNow


                if (release < dateNow) {
                    var name = video.name
                    chaps.push({
                        name: name,
                        url: eplink,
                        dateUpload: release.toString(),
                    })
                }
            }
        } else {
            if (release < dateNow) {
                chaps.push({
                    name: "Movie",
                    url: `${media_type}||${tmdb_id}`,
                    dateUpload: release.toString(),
                })
            }
        }

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
        var parts = url.split("||");
        var media_type = parts[0];
        var id = parts[1];
        var api = `${this.source.apiUrl}/api/getVideoSource?type=${media_type}&id=${id}`
        const response = await new Client().get(api, this.getHeaders());
        const body = JSON.parse(response.body);

        if (response.statusCode == 404) {
            throw new Error("Video unavailable");

        }
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
                    entryValues: ["movie", "series"]
                }
            },

        ];
    }
}
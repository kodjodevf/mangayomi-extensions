const mangayomiSources = [{
    "name": "Sudatchi",
    "lang": "en",
    "baseUrl": "https://sudatchi.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://sudatchi.com",
    "typeSource": "single",
    "version": "1.1.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "itemType": 1,
    "pkgPath": "anime/src/en/sudatchi.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        return {
            "Referer": this.source.baseUrl,
        }
    }

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }

    getUrl(slug) {
        return `https://ipfs.sudatchi.com/ipfs/${slug}`
    }

    async requestApi(slug) {
        var url = this.source.baseUrl + "/api" + slug

        var res = await new Client().get(url, this.getHeaders());

        return JSON.parse(res.body);
    }

    async formListForAnilist(animes) {
        var list = []
        var lang = this.getPreference("sudatchi_pref_lang")
        for (var item of animes) {
            var titles = item.title
            var name = titles.romaji
            switch (lang) {
                case "e": {
                    name = titles.english != null ? titles.english : name;
                    break;
                }
                case "j": {
                    name = titles.native != null ? titles.native : name;
                    break;
                }

            }
            var link = item.id
            var coverImage = item.coverImage
            var imageUrl = "large" in coverImage ? coverImage.large : coverImage.medium

            list.push({
                name,
                imageUrl,
                link: `${link}`
            });
        }
        return list;
    }

    async formList(animes) {
        var list = []
        var lang = this.getPreference("sudatchi_pref_lang")
        for (var item of animes) {
            var details = "Anime" in item ? item.Anime : item
            var name = "titleRomanji" in details ? details.titleRomanji : details.title
            switch (lang) {
                case "e": {
                    name = "titleEnglish" in details ? details.titleEnglish : name;
                    break;
                }
                case "j": {
                    name = "titleJapanese" in details ? details.titleJapanese : name;
                    break;
                }

            }
            var link = "anilistId" in details ? details.anilistId : details.id
            var imageUrl = "coverImage" in details ? details.coverImage : this.getUrl(details.imgUrl)
            list.push({
                name,
                imageUrl,
                link: `${link}`
            });
        }
        return list;
    }

    async getPopular(page) {
        var pageProps = await this.requestApi("/fetchHomeData")
        //  var  = extract
        var latestEpisodes = await this.formList(pageProps.latestEpisodes)
        var latestAnimes = await this.formListForAnilist(pageProps.ongoingAnimes)
        var animeSpotlight = await this.formList(pageProps.AnimeSpotlight)
        var list = [...animeSpotlight, ...latestAnimes, ...latestEpisodes]
        return {
            list,
            hasNextPage: false
        };
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        var pageProps = await this.requestApi("/fetchHomeData")
        var list = await this.formList(pageProps.latestEpisodes)

        return {
            list,
            hasNextPage: false
        };
    }
    async search(query, page, filters) {

        var body = await this.requestApi("/fetchAnime",);

        var url = this.source.baseUrl + "/api/fetchAnime"

        var res = await new Client().post(url, this.getHeaders(), { "query": query });
        var body = JSON.parse(res.body);

        var list = await this.formListForAnilist(body.results)
        var hasNextPage = body.pages > page ? true : false;

        return {
            list,
            hasNextPage
        };
    }

    statusCode(status) {
        return {
            "Currently Airing": 0,
            "Finished Airing": 1,
            "Hiatus": 2,
            "Discontinued": 3,
            "Not Yet Released": 4,
        }[status] ?? 5;
    }


    async getDetail(url) {
        var linkSlug = "https://sudatchi.com/anime/"
        if (url.includes(linkSlug)) url = url.replace(linkSlug, "");
        
        var lang = this.getPreference("sudatchi_pref_lang")
        var link = `${linkSlug}${url}`
        var details = await this.requestApi(`/anime/${url}`);
        var titles = details.title
        var name = titles.romaji
        switch (lang) {
            case "e": {
                name = titles.english != null ? titles.english : name;
                break;
            }
            case "j": {
                name = titles.native != null ? titles.native : name;
                break;
            }

        }
        var description = details.description
        var status = this.statusCode(details.status)
        var imageUrl = details.coverImage
        var genre = details.genres

        var chapters = []
        var episodes = details.episodes
        if (episodes.length > 0) {
            var typeId = details.format
            if (typeId == "MOVIE") {
                var number = episodes[0].number
                var epUrl = `${url}/${number}`
                chapters.push({ name: "Movie", url: epUrl })
            } else {
                for (var eObj of episodes) {
                    var epName = eObj.title
                    var number = eObj.number
                    var epUrl = `${url}/${number}`
                    chapters.push({ name: epName, url: epUrl })
                }
            }
        }

        chapters.reverse()

        return { name, description, status, imageUrl, genre, chapters, link }

    }
    // For novel html content
    async getHtmlContent(url) {
        throw new Error("getHtmlContent not implemented");
    }
    // Clean html up for reader
    async cleanHtmlContent(html) {
        throw new Error("cleanHtmlContent not implemented");
    }

    async extractStreams(url) {
        const response = await new Client().get(url);
        const body = response.body;
        const lines = body.split('\n');
        var audios = []

        var streams = [{
            url: url,
            originalUrl: url,
            quality: "auto",
        }];

        for (let i = 0; i < lines.length; i++) {
            var currentLine = lines[i]
            if (currentLine.startsWith('#EXT-X-STREAM-INF:')) {
                var resolution = currentLine.match(/RESOLUTION=(\d+x\d+)/)[1];
                var m3u8Url = lines[i + 1].trim();
                m3u8Url = m3u8Url.replace("./", `${url}/`)
                streams.push({
                    url: m3u8Url,
                    originalUrl: m3u8Url,
                    quality: resolution,
                });
            } else if (currentLine.startsWith('#EXT-X-MEDIA:TYPE=AUDIO')) {
                var attributesString = currentLine.split(",")
                var attributeRegex = /([A-Z-]+)=("([^"]*)"|[^,]*)/g;
                let match;
                var trackInfo = {};
                while ((match = attributeRegex.exec(attributesString)) !== null) {
                    var key = match[1];
                    var value = match[3] || match[2];
                    if (key === "NAME") {
                        trackInfo.label = value
                    } else if (key === "URI") {
                        trackInfo.file = value
                    }
                }
                audios.push(trackInfo);
            }
        }
        streams[0].audios = audios
        return streams
    }

    // For anime episode video list
    async getVideoList(url) {
        var jsonData = await this.requestApi(`/episode/${url}`);
        var episodeData = jsonData.episode;
        var epId = episodeData.id;

        var epLink = `https://sudatchi.com/videos/m3u8/episode-${epId}.m3u8`
        var streams = await this.extractStreams(epLink);

        var subs = JSON.parse(jsonData.subtitlesJson)
        var subtitles = [];
        for (var sub of subs) {
            var file = `https://ipfs.sudatchi.com${sub.url}`
            var label = sub.SubtitlesName.name;
            subtitles.push({ file: file, label: label });
        }
        streams[0].subtitles = subtitles

        return streams;

    }
    // For manga chapter pages
    async getPageList() {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }

    getSourcePreferences() {
        return [{
            key: 'sudatchi_pref_lang',
            listPreference: {
                title: 'Preferred title language',
                summary: '',
                valueIndex: 0,
                entries: ["Romanji", "English", "Japanese"],
                entryValues: ["r", "e", "j"]
            }
        },]
    }
}

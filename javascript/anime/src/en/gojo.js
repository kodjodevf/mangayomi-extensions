const mangayomiSources = [{
    "name": "Gojo",
    "lang": "en",
    "baseUrl": "https://gojo.wtf",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://gojo.wtf/",
    "typeSource": "multi",
    "itemType": 1,
    "version": "0.0.6",
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
            var link = "" + anime.id

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
        if (list.length < 30) hasNextPage = false;

        return { list, hasNextPage }
    }

    async search(query, page, filters) {
        var list = []
        var hasNextPage = false;

        var res = await this.gojoAPI(`/search?query=${query}&page=${page}&perPage=30`)
        if (res != null) {
            list.push(...this.formatList(res.results))
            if (res.lastPage < page) hasNextPage = true;
        }

        return { list, hasNextPage }
    }


    async getDetail(url) {
        var linkSlug = `${this.source.baseUrl}/watch/`
        if (url.includes(linkSlug)) url = url.replace(linkSlug, "");

        var anilistId = url
        var res = await this.gojoAPI(`/info/${anilistId}`)
        if (res == null) {
            throw new Error("Error on getDetail");
        }
        var name = this.getTitle(res.title)
        var imageUrl = res.coverImage.large
        var description = res.description;
        var link = `${linkSlug}${anilistId}`
        var genres = res.genres
        var status = (() => {
            switch (res.status) {
                case "RELEASING":
                    return 0;
                case "FINISHED":
                    return 1;
                case "HIATUS":
                    return 2;
                case "NOT_YET_RELEASED":
                    return 3;
                default:
                    return 5;
            }
        })();


        var chapters = [];

        var body = await this.gojoAPI(`/episodes/${anilistId}`)
        if (body != null && body.length > 0) {

            // Find the maximum episodes as some providers may not have all.
            var maxEpisodes = 0
            for (var prd of body) {
                if (prd['episodes'].length > maxEpisodes) {
                    maxEpisodes = prd['episodes'].length;
                }
            }

            for (var i = 0; i < maxEpisodes; i++) {
                var chapNum = -1
                var chapName = ""
                var chapLink = {}
                var chapScan = "Sub"

                for (var prd of body) {
                    var chap = prd.episodes[i];

                    // Check if the current provider episode is the same as the previous one.
                    // If not, break out of the loop.
                    var epNum = chap.number
                    if (chapNum == -1) {
                        chapNum = epNum
                    }

                    if (chapNum != epNum) continue;

                    // Episode Name is stored only once.
                    if (chapName.length == 0) {
                        chapName = `E${epNum}`
                        if (chap.hasOwnProperty("title")) {
                            if (chap.title != null) chapName += ": " + chap.title;
                        }
                    }

                    // If Dub is available, add it to the scanlator list.
                    if (chap.hasOwnProperty("hasDub")) {
                        if (!(chapScan.includes("Dub")) && chap.hasDub) {
                            chapScan += ", Dub"
                        }
                    }

                    // If isFiller is available, add it to the scanlator list.
                    if (chap.hasOwnProperty("isFiller")) {
                        if (!(chapScan.includes("Filler")) && chap.isFiller && this.getPreference("gojo_pref_mark_filler")) {
                            chapScan = "Filler, " + chapScan
                        }
                    }

                    // Delete unnecessary properties from the chapter object.
                    delete chap.image
                    delete chap.description
                    delete chap.isFiller
                    delete chap.title

                    var prdName = prd.providerId
                    chapLink[prdName] = chap

                }

                chapters.push({ name: chapName, url: `${anilistId}||` + JSON.stringify(chapLink), scanlator: chapScan })

            }

        }
        chapters.reverse()


        return { name, imageUrl, description, link, chapters, genres, status }
    }


    strixNzazaExtractor(res, prvd, type) {
        if(res == null) return {}

        var src = res.sources[0]
        var url = src.url
        var quality = `${prvd} - ${src.quality} - ${type.toUpperCase()}`
        return {
            url: url,
            quality,
            originalUrl: url
        }
    }

    paheExtractor(res, type) {
        var streams = []
        if (res != null) {
            var srcs = res.sources
            var hdr = this.getHeaders()
            for (var src of srcs) {
                var url = src.url
                var quality = `Pahe - ${src.quality} - ${type.toUpperCase()}`
                streams.push({
                    url: url,
                    headers: hdr,
                    quality,
                    originalUrl: url
                })
            }
        }
        return streams
    }


    async getStream(prvd, anilistId, epNum, subType, id, dub_id) {
        var slug = `/tiddies?provider=${prvd}&id=${anilistId}&num=${epNum}&subType=${subType}&watchId=${id}&dub_id=${dub_id}`
        return await this.gojoAPI(slug)
    }

    // For anime episode video list
    async getVideoList(url) {
        var split = url.split('||')
        var anilistId = split[0]
        var info = JSON.parse(split[1])
        var streams = []
        var extractDubs = this.getPreference("gojo_extract_dub_streams")

        for (var prvd in info) {
            var prd = info[prvd]
            var epNum = prd.number
            var subType = "sub"
            var id = prd.id
            var dub_id = null

            var res = await this.getStream(prvd, anilistId, epNum, subType, id, dub_id)
            if (prvd != "pahe") {
                streams.push(this.strixNzazaExtractor(res, prvd, subType))
            } else {
                streams.push(...this.paheExtractor(res, subType))
            }

            if(!extractDubs) continue
            subType = "dub"
            if (prd.hasOwnProperty("dub_id")) dub_id = prd.dub_id

            var res = await this.getStream(prvd, anilistId, epNum, subType, id, dub_id)
            if (prvd != "pahe") {
                streams.push(this.strixNzazaExtractor(res, prvd, subType))
            } else {
                streams.push(...this.paheExtractor(res, subType))
            }
        }
        return streams
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
            }, {
                key: "gojo_pref_mark_filler",
                switchPreferenceCompat: {
                    title: "Mark filler episodes",
                    summary: "",
                    value: true
                }
            }, {
                key: "gojo_extract_dub_streams",
                switchPreferenceCompat: {
                    title: 'Extract dub streams',
                    summary: "",
                    value: false
                }
            },
        ]
    }
}

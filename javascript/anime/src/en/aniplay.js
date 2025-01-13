const mangayomiSources = [{
    "name": "Aniplay",
    "lang": "en",
    "baseUrl": "https://aniplaynow.live",
    "apiUrl": "https://aniplaynow.live",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://aniplaynow.live/",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.0.3",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/en/aniplay.js"
}];

class DefaultExtension extends MProvider {

    constructor() {
        super();
        this.client = new Client();
    }

    getHeaders(url) {
        return {
            Referer: this.source.apiUrl
        }
    }

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }


    // code from torrentioanime.js
    anilistQuery() {
        return `
            query ($page: Int, $perPage: Int, $sort: [MediaSort], $search: String) {
                Page(page: $page, perPage: $perPage) {
                    pageInfo {
                        currentPage
                        hasNextPage
                    }
                    media(type: ANIME, sort: $sort, search: $search, status_in: [RELEASING, FINISHED, NOT_YET_RELEASED]) {
                        id
                        title {
                            romaji
                            english
                            native
                        }
                        coverImage {
                            extraLarge
                            large
                        }
                        description
                        status
                        tags {
                            name
                        }
                        genres
                        studios {
                            nodes {
                                name
                            }
                        }
                        countryOfOrigin
                        isAdult
                    }
                }
            }
        `.trim();
    }

    // code from torrentioanime.js
    anilistLatestQuery() {
        const currentTimeInSeconds = Math.floor(Date.now() / 1000);
        return `
            query ($page: Int, $perPage: Int, $sort: [AiringSort]) {
              Page(page: $page, perPage: $perPage) {
                pageInfo {
                  currentPage
                  hasNextPage
                }
                airingSchedules(
                  airingAt_greater: 0
                  airingAt_lesser: ${currentTimeInSeconds - 10000}
                  sort: $sort
                ) {
                  media {
                    id
                    title {
                      romaji
                      english
                      native
                    }
                    coverImage {
                      extraLarge
                      large
                    }
                    description
                    status
                    tags {
                      name
                    }
                    genres
                    studios {
                      nodes {
                        name
                      }
                    }
                    countryOfOrigin
                    isAdult
                  }
                }
              }
            }
        `.trim();
    }

    // code from torrentioanime.js
    async getAnimeDetails(anilistId) {
        const query = `
                query($id: Int){
                    Media(id: $id){
                        id
                        title {
                            romaji
                            english
                            native
                        }
                        coverImage {
                            extraLarge
                            large
                        }
                        description
                        status
                        tags {
                            name
                        }
                        genres
                        studios {
                            nodes {
                                name
                            }
                        }
                        countryOfOrigin
                        isAdult
                    }
                }
            `.trim();

        const variables = JSON.stringify({ id: anilistId });

        const res = await this.makeGraphQLRequest(query, variables);
        const media = JSON.parse(res.body).data.Media;
        const anime = {};
        anime.name = (() => {
            var preferenceTitle = this.getPreference("aniplay_pref_title");
            switch (preferenceTitle) {
                case "romaji":
                    return media?.title?.romaji || "";
                case "english":
                    return media?.title?.english?.trim() || media?.title?.romaji || "";
                case "native":
                    return media?.title?.native || "";
                default:
                    return "";
            }
        })();
        anime.imageUrl = media?.coverImage?.extraLarge || "";
        anime.description = (media?.description || "No Description")
            .replace(/<br><br>/g, "\n")
            .replace(/<.*?>/g, "");

        anime.status = (() => {
            switch (media?.status) {
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

        const tagsList = media?.tags?.map(tag => tag.name).filter(Boolean) || [];
        const genresList = media?.genres || [];
        anime.genre = [...new Set([...tagsList, ...genresList])].sort();
        const studiosList = media?.studios?.nodes?.map(node => node.name).filter(Boolean) || [];
        anime.author = studiosList.sort().join(", ");
        return anime;
    }

    // code from torrentioanime.js
    async makeGraphQLRequest(query, variables) {
        const res = await this.client.post("https://graphql.anilist.co", {},
            {
                query, variables
            });
        return res;
    }

    // code from torrentioanime.js
    parseSearchJson(jsonLine, isLatestQuery = false) {
        const jsonData = JSON.parse(jsonLine);
        jsonData.type = isLatestQuery ? "AnilistMetaLatest" : "AnilistMeta";
        const metaData = jsonData;

        const mediaList = metaData.type == "AnilistMeta"
            ? metaData.data?.Page?.media || []
            : metaData.data?.Page?.airingSchedules.map(schedule => schedule.media) || [];

        const hasNextPage = metaData.type == "AnilistMeta" || metaData.type == "AnilistMetaLatest"
            ? metaData.data?.Page?.pageInfo?.hasNextPage || false
            : false;

        const animeList = mediaList
            .filter(media => !((media?.countryOfOrigin === "CN" || media?.isAdult) && isLatestQuery))
            .map(media => {
                const anime = {};
                anime.link = media?.id?.toString() || "";
                anime.name = (() => {
                    var preferenceTitle = this.getPreference("aniplay_pref_title");
                    switch (preferenceTitle) {
                        case "romaji":
                            return media?.title?.romaji || "";
                        case "english":
                            return media?.title?.english?.trim() || media?.title?.romaji || "";
                        case "native":
                            return media?.title?.native || "";
                        default:
                            return "";
                    }
                })();
                anime.imageUrl = media?.coverImage?.extraLarge || "";

                return anime;
            });

        return { "list": animeList, "hasNextPage": hasNextPage };
    }

    async getPopular(page) {
        const variables = JSON.stringify({
            page: page,
            perPage: 30,
            sort: "TRENDING_DESC"
        });

        const res = await this.makeGraphQLRequest(this.anilistQuery(), variables);

        return this.parseSearchJson(res.body)
    }

    async getLatestUpdates(page) {
        const variables = JSON.stringify({
            page: page,
            perPage: 30,
            sort: "TIME_DESC"
        });

        const res = await this.makeGraphQLRequest(this.anilistLatestQuery(), variables);

        return this.parseSearchJson(res.body, true)
    }

    async search(query, page, filters) {
        const variables = JSON.stringify({
            page: page,
            perPage: 30,
            sort: "POPULARITY_DESC",
            search: query
        });

        const res = await this.makeGraphQLRequest(this.anilistQuery(), variables);

        return this.parseSearchJson(res.body)
    }

    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }

    async aniplayRequest(url, body) {
        var next_action = ""

        if (url.indexOf("/info/") > -1) {
            next_action = 'f3422af67c84852f5e63d50e1f51718f1c0225c4'
        } else if (url.indexOf("/watch/") > -1) {
            next_action = '5dbcd21c7c276c4d15f8de29d9ef27aef5ea4a5e'
        }

        var headers = {
            "referer": "https://aniplaynow.live",
            'next-action': next_action,
            "Content-Type": "application/json",
        }

        var response = await new Client().post(url, headers, body);

        if (response.statusCode != 200) {
            throw new Error("Error: " + response.statusText);
        }
        return JSON.parse(response.body.split('1:')[1])

    }

    async getDetail(url) {
        var anilistId = url
        var animeData = await this.getAnimeDetails(anilistId)


        var link = `${this.source.baseUrl}anime/info/${anilistId}`
        var body = [anilistId, true, false]
        var result = await this.aniplayRequest(link, body)
        if (result.length < 1) {
            throw new Error("Error: No data found for the given URL");
        }

        var user_provider = this.getPreference("aniplay_pref_provider");
        var choice = result[0]
        for (var ch of result) {
            if (ch["providerId"] == user_provider) {
                choice = ch
                break;
            }
        }
        var chapters = []
        var epList = choice.episodes
        for (var ep of epList) {
            var title = ep.title
            var num = ep.number
            var name = `E${num}: ${title}`
            var dateUpload = "createdAt" in ep ? new Date(ep.createdAt) : new Date().now()
            dateUpload = dateUpload.valueOf().toString();
            var epUrl = `${JSON.stringify(ep)}||${choice.providerId}`
            chapters.push({ name, url: epUrl, dateUpload })
        }
        animeData.link = link
        animeData.chapters = chapters.reverse()
        return animeData
    }
    // For anime episode video list
    async getVideoList(url) {
        throw new Error("getVideoList not implemented");
    }
    // For manga chapter pages
    async getPageList() {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    getSourcePreferences() {
        return [
            {
                "key": "aniplay_pref_title",
                "listPreference": {
                    "title": "Preferred Title",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": ["Romaji", "English", "Native"],
                    "entryValues": ["romaji", "english", "native"],
                }
            },
            {
                "key": "aniplay_pref_provider",
                "listPreference": {
                    "title": "Preferred provider",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": ["Anya", "Yuki", "Kuro"],
                    "entryValues": ["anya", "yuki", "kuro"],
                }
            },

        ]
    }
}

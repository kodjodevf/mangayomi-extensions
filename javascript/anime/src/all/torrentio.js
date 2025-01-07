const mangayomiSources = [{
    "name": "Torrentio (Torrent)",
    "lang": "all",
    "baseUrl": "https://torrentio.strem.fun",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.torrentio.png",
    "typeSource": "torrent",
    "isManga": false,
    "itemType": 1,
    "version": "0.0.25",
    "appMinVerReq": "0.3.8",
    "pkgPath": "anime/src/all/torrentio.js"
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    justWatchQuery() {
        return `
            query GetPopularTitles(
              $country: Country!,
              $first: Int!,
              $language: Language!,
              $offset: Int,
              $searchQuery: String,
              $packages: [String!]!,
              $objectTypes: [ObjectType!]!,
              $popularTitlesSortBy: PopularTitlesSorting!,
              $releaseYear: IntFilter
            ) {
              popularTitles(
                country: $country
                first: $first
                offset: $offset
                sortBy: $popularTitlesSortBy
                filter: {
                  objectTypes: $objectTypes,
                  searchQuery: $searchQuery,
                  packages: $packages,
                  genres: [],
                  excludeGenres: [],
                  releaseYear: $releaseYear
                }
              ) {
                edges {
                  node {
                    id
                    objectType
                    content(country: $country, language: $language) {
                      fullPath
                      title
                      shortDescription
                      externalIds {
                        imdbId
                      }
                      posterUrl
                      genres {
                        translation(language: $language)
                      }
                      credits {
                        name
                        role
                      }
                    }
                  }
                }
                pageInfo {
                  hasPreviousPage
                  hasNextPage
                }
              }
            }
        `.trim();
    }
    async makeGraphQLRequest(query, variables) {
        const res = await this.client.post("https://apis.justwatch.com/graphql", { "Content-Type": "application/json" },
            {
                query: query,
                variables
            });
        return res;
    }
    async searchAnimeRequest(page, query) {
        const preferences = new SharedPreferences();
        const country = preferences.get("jw_region1");
        const language = preferences.get("jw_lang");
        const perPage = 40;
        const year = 0;

        const searchQueryRegex = /[^a-zA-Z0-9 ]/g;
        const sanitizedQuery = query.replace(searchQueryRegex, "").trim();

        const variables = {
            first: perPage,
            offset: (page - 1) * perPage,
            platform: "WEB",
            country: country,
            language: language,
            searchQuery: sanitizedQuery,
            packages: [],
            objectTypes: [],
            popularTitlesSortBy: "TRENDING",
            releaseYear: {
                min: year,
                max: year
            }
        };

        return await this.makeGraphQLRequest(this.justWatchQuery(), variables);
    }
    parseSearchJson(jsonLine) {

        const popularTitlesResponse = JSON.parse(jsonLine);

        const edges = popularTitlesResponse?.data?.popularTitles?.edges || [];
        const hasNextPage = popularTitlesResponse?.data?.popularTitles?.pageInfo?.hasNextPage || false;

        const animeList = edges
            .map(edge => {
                const node = edge?.node;
                const content = node?.content;
                if (!node || !content) return null;
                return {
                    link: `${content.externalIds?.imdbId || ""},${node.objectType || ""},${content.fullPath || ""}`,
                    name: content.title || "",
                    imageUrl: `https://images.justwatch.com${content.posterUrl?.replace("{profile}", "s276")?.replace("{format}", "webp")}`,
                    description: content.shortDescription || "",
                    genre: content.genres?.map(genre => genre.translation).filter(Boolean) || [],
                    author: (content.credits?.filter(credit => credit.role === "DIRECTOR").map(credit => credit.name) || []).join(", "),
                    artist: (content.credits?.filter(credit => credit.role === "ACTOR").slice(0, 4).map(credit => credit.name) || []).join(", "),
                };
            })
            .filter(Boolean);

        return { "list": animeList, hasNextPage };
    }
    get supportsLatest() {
        return false;
    }
    async getPopular(page) {
        return this.parseSearchJson((await this.searchAnimeRequest(page, "")).body);
    }
    async getLatestUpdates(page) {

    }
    async search(query, page, filters) {
        return this.parseSearchJson((await this.searchAnimeRequest(page, query)).body);
    }
    async getDetail(url) {
        const anime = {};
        const parts = url.split(",");
        const type = parts[1].toLowerCase();
        const imdbId = parts[0];
        const response = await this.client.get(`https://cinemeta-live.strem.io/meta/${type}/${imdbId}.json`);
        const meta = JSON.parse(response.body).meta;
        if (!meta) return anime;
        anime.episodes = (() => {
            switch (meta.type) {
                case "show":
                    const videos = meta.videos || [];
                    return videos
                        .filter(video => (video.firstAired ? new Date(video.firstAired) : Date.now()) < Date.now())
                        .map(video => {
                            const firstAired = video.firstAired ? new Date(video.firstAired) : Date.now();

                            return {
                                url: `/stream/series/${video.id}.json`,
                                dateUpload: firstAired.valueOf().toString(),
                                name: `S${(video.season || "").toString().trim()}:E${(video.number || "").toString()} - ${video.name || ""}`,
                            };
                        })
                        .sort((a, b) => {
                            const seasonA = parseInt(a.name.substringAfter("S").substringBefore(":"), 10);
                            const seasonB = parseInt(b.name.substringAfter("S").substringBefore(":"), 10);
                            const episodeA = parseInt(a.name.substringAfter("E").substringBefore(" -"), 10);
                            const episodeB = parseInt(b.name.substringAfter("E").substringBefore(" -"), 10);

                            return seasonA - seasonB || episodeA - episodeB;
                        })
                        .reverse();

                case "movie":
                    return [
                        {
                            url: `/stream/movie/${meta.id}.json`,
                            name: "Movie"
                        }
                    ].reverse();

                default:
                    return [];
            }
        })();

        return anime;
    }

    appendQueryParam(key, values) {
        let url = "";
        if (values && values.length > 0) {
            const filteredValues = Array.from(values).filter(value => value.trim() !== "").join(",");
            url += `${key}=${filteredValues}|`;
        }
        return url;
    };
    async getVideoList(url) {
        const preferences = new SharedPreferences();

        let mainURL = `${this.source.baseUrl}/`;
        mainURL += this.appendQueryParam("providers", preferences.get("provider_selection1"));
        mainURL += this.appendQueryParam("language", preferences.get("lang_selection"));
        mainURL += this.appendQueryParam("qualityfilter", preferences.get("quality_selection"));
        mainURL += this.appendQueryParam("sort", new Set([preferences.get("sorting_link")]));
        mainURL += url;
        mainURL = mainURL.replace(/\|$/, "");
        const responseEpisodes = await this.client.get(mainURL);
        const streamList = JSON.parse(responseEpisodes.body);
        const animeTrackers = `
        http://nyaa.tracker.wf:7777/announce,
        http://anidex.moe:6969/announce,http://tracker.anirena.com:80/announce,
        udp://tracker.uw0.xyz:6969/announce,
        http://share.camoe.cn:8080/announce,
        http://t.nyaatracker.com:80/announce,
        udp://47.ip-51-68-199.eu:6969/announce,
        udp://9.rarbg.me:2940,
        udp://9.rarbg.to:2820,
        udp://exodus.desync.com:6969/announce,
        udp://explodie.org:6969/announce,
        udp://ipv4.tracker.harry.lu:80/announce,
        udp://open.stealth.si:80/announce,
        udp://opentor.org:2710/announce,
        udp://opentracker.i2p.rocks:6969/announce,
        udp://retracker.lanta-net.ru:2710/announce,
        udp://tracker.cyberia.is:6969/announce,
        udp://tracker.dler.org:6969/announce,
        udp://tracker.ds.is:6969/announce,
        udp://tracker.internetwarriors.net:1337,
        udp://tracker.openbittorrent.com:6969/announce,
        udp://tracker.opentrackr.org:1337/announce,
        udp://tracker.tiny-vps.com:6969/announce,
        udp://tracker.torrent.eu.org:451/announce,
        udp://valakas.rollo.dnsabr.com:2710/announce,
        udp://www.torrent.eu.org:451/announce
    `.split(",").map(tracker => tracker.trim()).filter(tracker => tracker);

        const videos = this.sortVideos((streamList.streams || []).map(stream => {
            const hash = `magnet:?xt=urn:btih:${stream.infoHash}&dn=${stream.infoHash}&tr=${animeTrackers.join("&tr=")}&index=${stream.fileIdx}`;
            const videoTitle = `${(stream.name || "").replace("Torrentio\n", "")}\n${stream.title || ""}`.trim();

            return {
                url: hash,
                originalUrl: hash,
                quality: videoTitle,
            };
        }));
        const numberOfLinks = preferences.get("number_of_links");
        if (numberOfLinks == "all") {
            return videos;
        }

        return videos.slice(0, parseInt(numberOfLinks))
    }

    sortVideos(videos) {
        const preferences = new SharedPreferences();

        const isDub = preferences.get("dubbed");
        const isEfficient = preferences.get("efficient");

        return videos.sort((a, b) => {
            const regexMatchA = /\[(.+?) download\]/.test(a.quality);
            const regexMatchB = /\[(.+?) download\]/.test(b.quality);

            const isDubA = isDub && !a.quality.toLowerCase().includes("dubbed");
            const isDubB = isDub && !b.quality.toLowerCase().includes("dubbed");

            const isEfficientA = isEfficient && !["hevc", "265", "av1"].some(q => a.quality.toLowerCase().includes(q));
            const isEfficientB = isEfficient && !["hevc", "265", "av1"].some(q => b.quality.toLowerCase().includes(q));


            return (
                regexMatchA - regexMatchB ||
                isDubA - isDubB ||
                isEfficientA - isEfficientB
            );
        });
    }



    getSourcePreferences() {
        return [
            {
                "key": "number_of_links",
                "listPreference": {
                    "title": "Number of links to load for video list",
                    "summary": "⚠️ Increasing the number of links will increase the loading time of the video list",
                    "valueIndex": 1,
                    "entries": [
                        "2",
                        "4",
                        "8",
                        "12",
                        "all"],
                    "entryValues": [
                        "2",
                        "4",
                        "8",
                        "12",
                        "all"],
                }
            },
            {
                "key": "provider_selection1",
                "multiSelectListPreference": {
                    "title": "Enable/Disable Providers",
                    "summary": "",
                    "entries": [
                        "YTS",
                        "EZTV",
                        "RARBG",
                        "1337x",
                        "ThePirateBay",
                        "KickassTorrents",
                        "TorrentGalaxy",
                        "MagnetDL",
                        "HorribleSubs",
                        "NyaaSi",
                        "TokyoTosho",
                        "AniDex",
                        "🇷🇺 Rutor",
                        "🇷🇺 Rutracker",
                        "🇵🇹 Comando",
                        "🇵🇹 BluDV",
                        "🇫🇷 Torrent9",
                        "🇪🇸 MejorTorrent",
                        "🇲🇽 Cinecalidad"],
                    "entryValues": [
                        "yts",
                        "eztv",
                        "rarbg",
                        "1337x",
                        "thepiratebay",
                        "kickasstorrents",
                        "torrentgalaxy",
                        "magnetdl",
                        "horriblesubs",
                        "nyaasi",
                        "tokyotosho",
                        "anidex",
                        "rutor",
                        "rutracker",
                        "comando",
                        "bludv",
                        "torrent9",
                        "mejortorrent",
                        "cinecalidad"],
                    "values": [
                        "yts",
                        "eztv",
                        "rarbg",
                        "1337x",
                        "thepiratebay",
                        "kickasstorrents",
                        "torrentgalaxy",
                        "magnetdl",
                        "horriblesubs",
                        "nyaasi",
                        "tokyotosho",
                        "anidex",
                        "rutor",
                        "rutracker",
                        "comando",
                        "bludv",
                        "torrent9",
                        "mejortorrent",
                        "cinecalidad"]
                }
            },
            {
                "key": "quality_selection",
                "multiSelectListPreference": {
                    "title": "Exclude Qualities/Resolutions",
                    "summary": "",
                    "entries": [
                        "BluRay REMUX",
                        "HDR/HDR10+/Dolby Vision",
                        "Dolby Vision",
                        "4k",
                        "1080p",
                        "720p",
                        "480p",
                        "Other (DVDRip/HDRip/BDRip...)",
                        "Screener",
                        "Cam",
                        "Unknown"],
                    "entryValues": [
                        "brremux",
                        "hdrall",
                        "dolbyvision",
                        "4k",
                        "1080p",
                        "720p",
                        "480p",
                        "other",
                        "scr",
                        "cam",
                        "unknown"],
                    "values": [
                        "720p",
                        "480p",
                        "other",
                        "scr",
                        "cam",
                        "unknown"]
                }
            },
            {
                "key": "lang_selection",
                "multiSelectListPreference": {
                    "title": "Priority foreign language",
                    "summary": "",
                    "entries": [
                        "🇯🇵 Japanese",
                        "🇷🇺 Russian",
                        "🇮🇹 Italian",
                        "🇵🇹 Portuguese",
                        "🇪🇸 Spanish",
                        "🇲🇽 Latino",
                        "🇰🇷 Korean",
                        "🇨🇳 Chinese",
                        "🇹🇼 Taiwanese",
                        "🇫🇷 French",
                        "🇩🇪 German",
                        "🇳🇱 Dutch",
                        "🇮🇳 Hindi",
                        "🇮🇳 Telugu",
                        "🇮🇳 Tamil",
                        "🇵🇱 Polish",
                        "🇱🇹 Lithuanian",
                        "🇱🇻 Latvian",
                        "🇪🇪 Estonian",
                        "🇨🇿 Czech",
                        "🇸🇰 Slovakian",
                        "🇸🇮 Slovenian",
                        "🇭🇺 Hungarian",
                        "🇷🇴 Romanian",
                        "🇧🇬 Bulgarian",
                        "🇷🇸 Serbian",
                        "🇭🇷 Croatian",
                        "🇺🇦 Ukrainian",
                        "🇬🇷 Greek",
                        "🇩🇰 Danish",
                        "🇫🇮 Finnish",
                        "🇸🇪 Swedish",
                        "🇳🇴 Norwegian",
                        "🇹🇷 Turkish",
                        "🇸🇦 Arabic",
                        "🇮🇷 Persian",
                        "🇮🇱 Hebrew",
                        "🇻🇳 Vietnamese",
                        "🇮🇩 Indonesian",
                        "🇲🇾 Malay",
                        "🇹🇭 Thai",],
                    "entryValues": [
                        "japanese",
                        "russian",
                        "italian",
                        "portuguese",
                        "spanish",
                        "latino",
                        "korean",
                        "chinese",
                        "taiwanese",
                        "french",
                        "german",
                        "dutch",
                        "hindi",
                        "telugu",
                        "tamil",
                        "polish",
                        "lithuanian",
                        "latvian",
                        "estonian",
                        "czech",
                        "slovakian",
                        "slovenian",
                        "hungarian",
                        "romanian",
                        "bulgarian",
                        "serbian",
                        "croatian",
                        "ukrainian",
                        "greek",
                        "danish",
                        "finnish",
                        "swedish",
                        "norwegian",
                        "turkish",
                        "arabic",
                        "persian",
                        "hebrew",
                        "vietnamese",
                        "indonesian",
                        "malay",
                        "thai"],
                    "values": []
                }
            },
            {
                "key": "sorting_link",
                "listPreference": {
                    "title": "Sorting",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": [
                        "By quality then seeders",
                        "By quality then size",
                        "By seeders",
                        "By size"],
                    "entryValues": [
                        "quality",
                        "qualitysize",
                        "seeders",
                        "size"],
                }
            },
            {
                "key": "dubbed",
                "switchPreferenceCompat": {
                    "title": "Dubbed Video Priority",
                    "summary": "",
                    "value": false
                }
            },
            {
                "key": "efficient",
                "switchPreferenceCompat": {
                    "title": "Efficient Video Priority",
                    "summary": "Codec: (HEVC / x265)  & AV1. High-quality video with less data usage.",
                    "value": false
                }
            },
            {
                "key": "jw_region1",
                "listPreference": {
                    "title": "Catalogue Region",
                    "summary": "Region based catalogue recommendation.",
                    "valueIndex": 132,
                    "entries": [
                        "Albania", "Algeria", "Androrra", "Angola", "Antigua and Barbuda", "Argentina", "Australia", "Austria", "Azerbaijan", "Bahamas", "Bahrain", "Barbados", "Belarus", "Belgium", "Belize", "Bermuda", "Bolivia", "Bosnia and Herzegovina", "Brazil", "Bulgaria", "Burkina Faso", "Cameroon", "Canada", "Cape Verde", "Chad", "Chile", "Colombia", "Costa Rica", "Croatia", "Cuba", "Cyprus", "Czech Republic", "DR Congo", "Denmark", "Dominican Republic", "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Estonia", "Fiji", "Finland", "France", "French Guiana", "French Polynesia", "Germany", "Ghana", "Gibraltar", "Greece", "Guatemala", "Guernsey", "Guyana", "Honduras", "Hong Kong", "Hungary", "Iceland", "India", "Indonesia", "Iraq", "Ireland", "Israel", "Italy", "Ivory Coast", "Jamaica", "Japan", "Jordan", "Kenya", "Kosovo", "Kuwait", "Latvia", "Lebanon", "Libya", "Liechtenstein", "Lithuania", "Luxembourg", "Macedonia", "Madagascar", "Malawi", "Malaysia", "Mali", "Malta", "Mauritius", "Mexico", "Moldova", "Monaco", "Montenegro", "Morocco", "Mozambique", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Norway", "Oman", "Pakistan", "Palestine", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Qatar", "Romania", "Russia", "Saint Lucia", "San Marino", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Singapore", "Slovakia", "Slovenia", "South Africa", "South Korea", "Spain", "Sweden", "Switzerland", "Taiwan", "Tanzania", "Thailand", "Trinidad and Tobago", "Tunisia", "Turkey", "Turks and Caicos Islands", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Vatican City", "Venezuela", "Yemen", "Zambia", "Zimbabwe"],
                    "entryValues": [
                        "AL", "DZ", "AD", "AO", "AG", "AR", "AU", "AT", "AZ", "BS", "BH", "BB", "BY", "BE", "BZ", "BM", "BO", "BA", "BR", "BG", "BF", "CM", "CA", "CV", "TD", "CL", "CO", "CR", "HR", "CU", "CY", "CZ", "CD", "DK", "DO", "EC", "EG", "SV", "GQ", "EE", "FJ", "FI", "FR", "GF", "PF", "DE", "GH", "GI", "GR", "GT", "GG", "GY", "HN", "HK", "HU", "IS", "IN", "ID", "IQ", "IE", "IL", "IT", "CI", "JM", "JP", "JO", "KE", "XK", "KW", "LV", "LB", "LY", "LI", "LT", "LU", "MK", "MG", "MW", "MY", "ML", "MT", "MU", "MX", "MD", "MC", "ME", "MA", "MZ", "NL", "NZ", "NI", "NE", "NG", "NO", "OM", "PK", "PS", "PA", "PG", "PY", "PE", "PH", "PL", "PT", "QA", "RO", "RU", "LC", "SM", "SA", "SN", "RS", "SC", "SG", "SK", "SI", "ZA", "KR", "ES", "SE", "CH", "TW", "TZ", "TH", "TT", "TN", "TR", "TC", "UG", "UA", "AE", "UK", "US", "UY", "VA", "VE", "YE", "ZM", "ZW"],
                }
            },
            {
                "key": "jw_lang",
                "listPreference": {
                    "title": "Poster and Titles Language",
                    "summary": "",
                    "valueIndex": 9,
                    "entries": [
                        "Arabic",
                        "Azerbaijani",
                        "Belarusian",
                        "Bulgarian",
                        "Bosnian",
                        "Catalan",
                        "Czech",
                        "German",
                        "Greek",
                        "English",
                        "English (U.S.A.)",
                        "Spanish",
                        "Spanish (Spain)",
                        "Spanish (Latinamerican)",
                        "Estonian",
                        "Finnish",
                        "French",
                        "French (Canada)",
                        "Hebrew",
                        "Croatian",
                        "Hungarian",
                        "Icelandic",
                        "Italian",
                        "Japanese",
                        "Korean",
                        "Lithuanian",
                        "Latvian",
                        "Macedonian",
                        "Maltese",
                        "Polish",
                        "Portuguese",
                        "Portuguese (Portugal)",
                        "Portuguese (Brazil)",
                        "Romanian",
                        "Russian",
                        "Slovakian",
                        "Slovenian",
                        "Albanian",
                        "Serbian",
                        "Swedish",
                        "Swahili",
                        "Turkish",
                        "Ukrainian",
                        "Urdu",
                        "Chinese"],
                    "entryValues": [
                        "ar",
                        "az",
                        "be",
                        "bg",
                        "bs",
                        "ca",
                        "cs",
                        "de",
                        "el",
                        "en",
                        "en-US",
                        "es",
                        "es-ES",
                        "es-LA",
                        "et",
                        "fi",
                        "fr",
                        "fr-CA",
                        "he",
                        "hr",
                        "hu",
                        "is",
                        "it",
                        "ja",
                        "ko",
                        "lt",
                        "lv",
                        "mk",
                        "mt",
                        "pl",
                        "pt",
                        "pt-PT",
                        "pt-BR",
                        "ro",
                        "ru",
                        "sk",
                        "sl",
                        "sq",
                        "sr",
                        "sv",
                        "sw",
                        "tr",
                        "uk",
                        "ur",
                        "zh"],
                }
            },
        ];
    }
}

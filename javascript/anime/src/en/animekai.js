const mangayomiSources = [{
    "name": "AnimeKai",
    "lang": "en",
    "baseUrl": "https://animekai.to",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://animekai.to/",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.1.0",
    "pkgPath": "anime/src/en/animekai.js"
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }


    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    getBaseUrl() {
        return this.getPreference("animekai_base_url");

    }

    async request(slug) {
        var url = this.getBaseUrl() + slug;
        var res = await this.client.get(url);
        return res.body
    }

    async getPage(slug) {
        var res = await this.request(slug);
        return new Document(res);
    }

    async searchPage({ query = "", type = [], genre = [], status = [], sort = "", season = [], year = [], rating = [], country = [], language = [], page = 1 } = {}) {

        function bundleSlug(category, items) {
            var rd = ""
            for (var item of items) {
                rd += `&${category}[]=${item}`;
            }
            return rd;
        }

        var slug = "/browser?"

        slug += "keyword=" + query;

        slug += bundleSlug("type", type);
        slug += bundleSlug("genre", genre);
        slug += bundleSlug("status", status);
        slug += "&sort=" + sort;

        slug += bundleSlug("status", status);
        slug += bundleSlug("season", season);
        slug += bundleSlug("year", year);
        slug += bundleSlug("rating", rating);
        slug += bundleSlug("country", country);
        slug += bundleSlug("language", language);
        slug += `&page=${page}`;

        var list = []

        var body = await this.getPage(slug);

        var paginations = body.select(".pagination > li")
        var hasNextPage = paginations.length > 0 ? !paginations[paginations.length - 1].className.includes("active") : false

        var titlePref = this.getPreference("animekai_title_lang")
        var animes = body.selectFirst(".aitem-wrapper").select(".aitem")
        animes.forEach(anime => {
            var link = anime.selectFirst("a").getHref
            var imageUrl = anime.selectFirst("img").attr("data-src")
            var name = anime.selectFirst("a.title").attr(titlePref)
            list.push({ name, link, imageUrl });
        })

        return { list, hasNextPage }
    }


    async getPopular(page) {
        var types = this.getPreference("animekai_popular_latest_type")
        return await this.searchPage({ sort: "trending", type: types, page: page });
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        var types = this.getPreference("animekai_popular_latest_type")
        return await this.searchPage({ sort: "updated_date", type: types, page: page });
    }
    async search(query, page, filters) {
        function getFilter(state) {
            var rd = []
            state.forEach(item => {
                if (item.state) {
                    rd.push(item.value)
                }
            })
            return rd

        }
        var type = getFilter(filters[0].state)
        var genre = getFilter(filters[1].state)
        var status = getFilter(filters[2].state)
        var sort = filters[3].values[filters[3].state].value
        var season = getFilter(filters[4].state)
        var year = getFilter(filters[5].state)
        var rating = getFilter(filters[6].state)
        var country = getFilter(filters[7].state)
        var language = getFilter(filters[8].state)
        return await this.searchPage({ query, type, genre, status, sort, season, year, rating, country, language, page });
    }

    async getDetail(url) {
        function statusCode(status) {
            return {
                "Releasing": 0,
                "Completed": 1,
                "Not Yet Aired": 4,
            }[status] ?? 5;
        }

        var slug = url
        var link = this.getBaseUrl() + slug
        var body = await this.getPage(slug)

        var mainSection = body.selectFirst(".watch-section")

        var imageUrl = mainSection.selectFirst("div.poster").selectFirst("img").getSrc

        var namePref = this.getPreference("animekai_title_lang")
        var nameSection = mainSection.selectFirst("div.title")
        var name = namePref.includes("jp") ? nameSection.attr(namePref) : nameSection.text

        var description = mainSection.selectFirst("div.desc").text

        var detailSection = mainSection.select("div.detail > div")

        var genre = []
        var status = 5
        detailSection.forEach(item => {
            var itemText = item.text.trim()

            if (itemText.includes("Genres")) {
                genre = itemText.replace("Genres:  ", "").split(", ")
            }
            if (itemText.includes("Status")) {
                var statusText = item.selectFirst("span").text
                status = statusCode(statusText)
            }
        })

        var chapters = []
        var animeId = body.selectFirst("#anime-rating").attr("data-id")

        var token = await this.generateToken(animeId)
        var res = await this.request(`/ajax/episodes/list?ani_id=${animeId}&_=${token}`)
        body = JSON.parse(res)
        if (body.status == 200) {
            var doc = new Document(body["result"])
            var episodes = doc.selectFirst("div.eplist.titles").select("li")
            var showUncenEp = this.getPreference("animekai_show_uncen_epsiodes")

            for (var item of episodes) {
                var aTag = item.selectFirst("a")

                var num = parseInt(aTag.attr("num"))
                var title = aTag.selectFirst("span").text
                title = title.includes("Episode") ? "" : `: ${title}`
                var epName = `Episode ${num}${title}`


                var langs = aTag.attr("langs")
                var scanlator = langs === "1" ? "SUB" : "SUB, DUB"

                var token = aTag.attr("token")

                var epData = {
                    name: epName,
                    url: token,
                    scanlator
                }

                // Check if the episode is uncensored
                var slug = aTag.attr("slug")
                if (slug.includes("uncen")) {

                    // if dont show uncensored episodes, skip this episode
                    if (!showUncenEp) continue

                    scanlator += ", UNCENSORED"
                    epName = `Episode ${num}: (Uncensored)`
                    // Build for uncensored episode
                    epData = {
                        name: epName,
                        url: token,
                        scanlator
                    }

                    // Check if the episode already exists as censored if so, add to existing data
                    var exData = chapters[num - 1]
                    if (exData) {
                        exData.url += "||" + epData.url
                        exData.scanlator += ", " + epData.scanlator
                        chapters[num - 1] = exData
                        continue

                    }
                }
                chapters.push(epData)
            }
        }
        chapters.reverse()
        return { name, imageUrl, link, description, genre, status, chapters }
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
        function formateState(type_name, items, values) {
            var state = [];
            for (var i = 0; i < items.length; i++) {
                state.push({ type_name: type_name, name: items[i], value: values[i] })
            }
            return state;
        }

        var filters = [];

        // Types
        var items = ["TV", "Special", "OVA", "ONA", "Music", "Movie"]
        var values = ["tv", "special", "ova", "ona", "music", "movie"]
        filters.push({
            type_name: "GroupFilter",
            name: "Types",
            state: formateState("CheckBox", items, values)
        })

        // Genre
        items = [
            "Action", "Adventure", "Avant Garde", "Boys Love", "Comedy", "Demons", "Drama", "Ecchi", "Fantasy",
            "Girls Love", "Gourmet", "Harem", "Horror", "Isekai", "Iyashikei", "Josei", "Kids", "Magic",
            "Mahou Shoujo", "Martial Arts", "Mecha", "Military", "Music", "Mystery", "Parody", "Psychological",
            "Reverse Harem", "Romance", "School", "Sci-Fi", "Seinen", "Shoujo", "Shounen", "Slice of Life",
            "Space", "Sports", "Super Power", "Supernatural", "Suspense", "Thriller", "Vampire"
        ];

        values = [
            "47", "1", "235", "184", "7", "127", "66", "8", "34", "926", "436", "196", "421", "77", "225",
            "555", "35", "78", "857", "92", "219", "134", "27", "48", "356", "240", "798", "145", "9", "36",
            "189", "183", "37", "125", "220", "10", "350", "49", "322", "241", "126"
        ];

        filters.push({
            type_name: "GroupFilter",
            name: "Genres",
            state: formateState("CheckBox", items, values)
        })

        // Status
        items = ["Not Yet Aired", "Releasing", "Completed"]
        values = ["info", "releasing", "completed"]
        filters.push({
            type_name: "GroupFilter",
            name: "Status",
            state: formateState("CheckBox", items, values)
        })

        // Sort
        items = [
            "All", "Updated date", "Released date", "End date", "Added date", "Trending",
            "Name A-Z", "Average score", "MAL score", "Total views", "Total bookmarks", "Total episodes"
        ];

        values = [
            "", "updated_date", "released_date", "end_date", "added_date", "trending",
            "title_az", "avg_score", "mal_score", "total_views", "total_bookmarks", "total_episodes"
        ];
        filters.push({
            type_name: "SelectFilter",
            name: "Sort by",
            state: 0,
            values: formateState("SelectOption", items, values)
        })

        // Season
        items = ["Fall", "Summer", "Spring", "Winter", "Unknown"];
        values = ["fall", "summer", "spring", "winter", "unknown"];
        filters.push({
            type_name: "GroupFilter",
            name: "Season",
            state: formateState("CheckBox", items, values)
        })

        // Years
        const currentYear = new Date().getFullYear();
        var years = Array.from({ length: currentYear - 1999 }, (_, i) => (2000 + i).toString()).reverse()
        items = [...years, "1990s", "1980s", "1970s", "1960s", "1950s", "1940s", "1930s", "1920s", "1910s", "1900s",]
        filters.push({
            type_name: "GroupFilter",
            name: "Years",
            state: formateState("CheckBox", items, items)
        })

        // Ratings
        items = [
            "G - All Ages",
            "PG - Children",
            "PG 13 - Teens 13 and Older",
            "R - 17+, Violence & Profanity",
            "R+ - Profanity & Mild Nudity",
            "Rx - Hentai"
        ];

        values = ["g", "pg", "pg_13", "r", "r+", "rx"];
        filters.push({
            type_name: "GroupFilter",
            name: "Ratings",
            state: formateState("CheckBox", items, items)
        })

        // Country
        items = ["Japan", "China"];
        values = ["11", "2"];
        filters.push({
            type_name: "GroupFilter",
            name: "Country",
            state: formateState("CheckBox", items, items)
        })

        // Language
        items = ["Hard Sub", "Soft Sub", "Dub", "Sub & Dub"];
        values = ["sub", "softsub", "dub", "subdub"];
        filters.push({
            type_name: "GroupFilter",
            name: "Language",
            state: formateState("CheckBox", items, items)
        })

        return filters;
    }
    getSourcePreferences() {
        return [
            {
                key: "animekai_base_url",
                editTextPreference: {
                    title: "Override base url",
                    summary: "",
                    value: "https://animekai.to",
                    dialogTitle: "Override base url",
                    dialogMessage: "",
                }
            }, {
                key: "animekai_popular_latest_type",
                multiSelectListPreference: {
                    title: 'Preferred type of anime to be shown in popular & latest section',
                    summary: 'Choose which type of anime you want to see in the popular &latest section',
                    values: ["tv", "special", "ova", "ona"],
                    entries: ["TV", "Special", "OVA", "ONA", "Music", "Movie"],
                    entryValues: ["tv", "special", "ova", "ona", "music", "movie"]
                }
            }, {
                key: "animekai_title_lang",
                listPreference: {
                    title: 'Preferred title language',
                    summary: 'Choose in which language anime title should be shown',
                    valueIndex: 1,
                    entries: ["English", "Romaji"],
                    entryValues: ["title", "data-jp"]
                }
            },
            {
                key: "animekai_show_uncen_epsiodes",
                switchPreferenceCompat: {
                    title: 'Show uncensored episodes',
                    summary: "",
                    value: true
                }
            },
        ]
    }

    //----------------AnimeKai Decoders----------------
    // Credits :- https://github.com/amarullz/kaicodex/

    base64Decoder(base64) {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        let binary = '';

        base64 = base64.replace(/=+$/, '');

        for (let i = 0; i < base64.length; i++) {
            const index = chars.indexOf(base64[i]);
            if (index === -1) continue; // skip invalid characters
            binary += index.toString(2).padStart(6, '0');
        }

        let decoded = '';
        for (let i = 0; i < binary.length; i += 8) {
            const byte = binary.substring(i, i + 8);
            if (byte.length < 8) continue;
            decoded += String.fromCharCode(parseInt(byte, 2));
        }

        return decoded;
    }
    base64Encoder(str) {
        const base64EncodeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        var out, i, len;
        var c1, c2, c3;
        len = str.length;
        i = 0;
        out = "";
        while (i < len) {
            c1 = str.charCodeAt(i++) & 0xff;
            if (i == len) {
                out += base64EncodeChars.charAt(c1 >> 2);
                out += base64EncodeChars.charAt((c1 & 0x3) << 4);
                out += "==";
                break;
            }
            c2 = str.charCodeAt(i++);
            if (i == len) {
                out += base64EncodeChars.charAt(c1 >> 2);
                out += base64EncodeChars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4));
                out += base64EncodeChars.charAt((c2 & 0xF) << 2);
                out += "=";
                break;
            }
            c3 = str.charCodeAt(i++);
            out += base64EncodeChars.charAt(c1 >> 2);
            out += base64EncodeChars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4));
            out += base64EncodeChars.charAt(((c2 & 0xF) << 2) | ((c3 & 0xC0) >> 6));
            out += base64EncodeChars.charAt(c3 & 0x3F);
        }
        return out;
    }

    transform(key, text) {
        const v = Array.from({ length: 256 }, (_, i) => i);
        let c = 0;
        const f = [];

        for (let w = 0; w < 256; w++) {
            c = (c + v[w] + key.charCodeAt(w % key.length)) % 256;
            [v[w], v[c]] = [v[c], v[w]];
        }

        let a = 0, w = 0, sum = 0;
        while (a < text.length) {
            w = (w + 1) % 256;
            sum = (sum + v[w]) % 256;
            [v[w], v[sum]] = [v[sum], v[w]];
            f.push(String.fromCharCode(text.charCodeAt(a) ^ v[(v[w] + v[sum]) % 256]));
            a++;
        }
        return f.join('');
    }

    reverseString(input) {
        return input.split('').reverse().join('');
    }

    substitute(input, keys, values) {
        const map = {};
        for (let i = 0; i < keys.length; i++) {
            map[keys[i]] = values[i] || keys[i];
        }
        return input.split('').map(char => map[char] || char).join('');
    }

    async getDecoderPattern() {
        const preferences = new SharedPreferences();
        let pattern = preferences.getString("anime_kai_decoder_pattern", "");
        var pattern_ts = parseInt(preferences.getString("anime_kai_decoder_pattern_ts", "0"));
        var now_ts = parseInt(new Date().getTime() / 1000);
        
        // pattern is checked from API every 30 minutes
        if (now_ts - pattern_ts > 30 * 60) {
            var res = await this.client.get("https://raw.githubusercontent.com/amarullz/kaicodex/refs/heads/main/generated/kai_codex.json")
            pattern = res.body
            preferences.setString("anime_kai_decoder_pattern", pattern);
            preferences.setString("anime_kai_decoder_pattern_ts", `${now_ts}`);
        }

        return JSON.parse(pattern);
    }
    
    async patternExecutor(key, type, id) {
        var result = id
        var pattern = await this.getDecoderPattern()
        var logic = pattern[key][type]
        logic.forEach(step => {
            var method = step[0]
            if (method == "urlencode") result = encodeURIComponent(result);
            else if (method == "rc4") result = this.transform(step[1], result);
            else if (method == "reverse") result = this.reverseString(result);
            else if (method == "substitute") result = this.substitute(result, step[1], step[2]);
            else if (method == "safeb64_decode") result = this.base64Decoder(result);
            else if (method == "safeb64_encode") result = this.base64Encoder(result);
        })
        return result
    }

    async generateToken(id) {
        var token = await this.patternExecutor("kai", "encrypt", id)
        return token;
    }

}

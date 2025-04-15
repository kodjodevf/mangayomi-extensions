const mangayomiSources = [{
    "name": "AnimeKai",
    "lang": "en",
    "baseUrl": "https://animekai.to",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://animekai.to/",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.0.1",
    "pkgPath": "anime/src/en/animekai.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }

    constructor() {
        super();
        this.client = new Client();
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

    async searchPage({ query = "", type = [], genre = [], status = [], sort = "", season = [], year = [], rating = [], country = [], subType = [], page = 1 } = {}) {

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
        slug += bundleSlug("subType", subType);
        slug += `&page=${page}`;

        var body = await this.getPage(slug);

        var paginations = body.select(".pagination > li")
        var hasNextPage = !paginations[paginations.length - 1].className.includes("active")
        var list = []

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
        throw new Error("search not implemented");
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
            }
        ]
    }
}

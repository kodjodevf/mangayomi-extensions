const mangayomiSources = [{
    "name": "ReadComicOnline",
    "lang": "en",
    "baseUrl": "https://readcomiconline.li",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://readcomiconline.li/",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.1",
    "pkgPath": ""
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    getHeaders() {
        return {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6832.64 Safari/537.36",
            "Referer": this.source.baseUrl,
            "Origin": this.source.baseUrl,
        }
    }

    async request(slug) {
        var url = slug
        var baseUrl = this.source.baseUrl
        if (!slug.includes(baseUrl)) url = baseUrl + slug;
        var res = await this.client.get(url, this.getHeaders());
        return new Document(res.body);
    }

    async getListPage(slug, page) {
        var url = `${slug}page=${page}`
        var doc = await this.request(url);
        var baseUrl = this.source.baseUrl
        var list = []

        var comicList = doc.select(".list-comic > .item")
        comicList.forEach(item => {
            var name = item.selectFirst(".title").text;
            var link = item.selectFirst("a").getHref
            var imageSlug = item.selectFirst("img").getSrc
            var imageUrl = `${baseUrl}${imageSlug}`;
            list.push({ name, link, imageUrl });
        });

        var pager = doc.select("ul.pager > li")

        var hasNextPage = false
        if (pager.length > 0) hasNextPage = pager[pager.length - 1].text.includes("Last") ? true : false;

        return { list, hasNextPage }

    }

    async getPopular(page) {
        return await this.getListPage("/ComicList/MostPopular?", page)
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        return await this.getListPage("/ComicList/LatestUpdate?", page)
    }
    async search(query, page, filters) {
        function getFilter(state) {
            var rd = ""
            state.forEach(item => {
                if (item.state) {
                    rd += `${item.value},`
                }
            })
            return rd.slice(0, -1)
        }

        var genre = getFilter(filters[0].state)
        var status = filters[1].values[filters[1].state].value
        var year = filters[2].values[filters[2].state].value


        var slug = `/AdvanceSearch?comicName=${query}&ig=${encodeURIComponent(genre)}&status=${status}&pubDate=${year}&`

        return await this.getListPage(slug, page)
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
        function formateState(type_name, items, values) {
            var state = [];
            for (var i = 0; i < items.length; i++) {
                state.push({ type_name: type_name, name: items[i], value: values[i] })
            }
            return state;
        }

        var filters = [];

        // Genre
        var items = [
            "Action", "Adventure", "Anthology", "Anthropomorphic", "Biography", "Children", "Comedy",
            "Crime", "Drama", "Family", "Fantasy", "Fighting", "Graphic Novels", "Historical", "Horror",
            "Leading Ladies", "LGBTQ", "Literature", "Manga", "Martial Arts", "Mature", "Military",
            "Mini-Series", "Movies & TV", "Music", "Mystery", "Mythology", "Personal", "Political",
            "Post-Apocalyptic", "Psychological", "Pulp", "Religious", "Robots", "Romance", "School Life",
            "Sci-Fi", "Slice of Life", "Sport", "Spy", "Superhero", "Supernatural", "Suspense", "Teen",
            "Thriller", "Vampires", "Video Games", "War", "Western", "Zombies"
        ];

        var values = [
            "1", "2", "38", "46", "41", "49", "3",
            "17", "19", "25", "20", "31", "5", "28", "15",
            "35", "51", "44", "40", "4", "8", "33",
            "56", "47", "55", "23", "21", "48", "42",
            "43", "27", "39", "53", "9", "32", "52",
            "16", "50", "54", "30", "22", "24", "29", "57",
            "18", "34", "37", "26", "45", "36"
        ];
        filters.push({
            type_name: "GroupFilter",
            name: "Genres",
            state: formateState("CheckBox", items, values)
        })

        // Status
        items = ["Any", "Ongoing", "Completed"];
        values = ["", "Ongoing", "Completed"];
        filters.push({
            type_name: "SelectFilter",
            name: "Status",
            state: 0,
            values: formateState("SelectOption", items, values)
        })

        // Years
        const currentYear = new Date().getFullYear();
        items = Array.from({ length: currentYear - 1919 }, (_, i) => (1920 + i).toString()).reverse()
        items = ["All", ...items]
        values = ["", ...items]
        filters.push({
            type_name: "SelectFilter",
            name: "Year",
            state: 0,
            values: formateState("SelectOption", items, values)
        })

        return filters;
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

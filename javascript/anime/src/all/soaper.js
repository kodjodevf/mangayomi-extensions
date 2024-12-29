const mangayomiSources = [{
    "name": "Soaper",
    "lang": "all",
    "baseUrl": "https://soaper.cc",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://soaper.cc/",
    "typeSource": "multi",
    "isManga": false,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": ""
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        return {
            "Referer": this.source.baseUrl,
            "Origin": this.source.baseUrl
        }
    }

    async getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }

    async request(slug) {
        const baseUrl = await this.getPreference("pref_override_base_url")
        var url = `${baseUrl}/${slug}`
        var res = await new Client().get(url, this.getHeaders());
        var doc = new Document(res.body);
        return doc
    }

    async formatList(slug, page) {
        const baseUrl = await this.getPreference("pref_override_base_url")
        var doc = await this.request(`${slug}?page=${page}`);
        var list = [];
        var movies = doc.select(".thumbnail.text-center")

        for (var movie of movies) {
            var linkSection = movie.selectFirst("div.img-group > a")
            var link = linkSection.getHref;
            var poster = linkSection.selectFirst("img").getSrc
            var imageUrl = `${baseUrl}${poster}`
            var name = movie.selectFirst("h5").text;

            list.push({ name, imageUrl, link });
        }

        var pagination = doc.select("ul.pagination > li")
        var last_page_num = parseInt(pagination[pagination.length - 2].text);
        var hasNextPage = page < last_page_num ? true : false;
        return { list, hasNextPage }
    }

    async filterList(year = "all", genre = "all", sort = "new", page = 1) {

        year = year == "all" ? "" : `/year/${year}`
        genre = genre == "all" ? "" : `/cat/${genre}`
        sort = sort == "new" ? "" : `/sort/${sort}`

        var slug = `${sort}${year}${genre}`
        var movieList = await this.formatList(`movielist${slug}`, page);
        var seriesList = await this.formatList(`tvlist${slug}`, page);

        var list = [];
        var priority = await this.getPreference("pref_content_priority");
        if (priority === "series") {
            list = [...seriesList.list, ...movieList.list];
        } else {
            list = [...movieList.list, ...seriesList.list];
        }

        var hasNextPage = seriesList.hasNextPage || movieList.hasNextPage;

        return { list, hasNextPage }
    }

    async getPopular(page) {
        return await this.filterList("all", "all", "hot", page);
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        return await this.filterList("all", "all", "new", page);
    }
    async search(query, page, filters) {
        throw new Error("search not implemented");
    }
    async getDetail(url) {
        throw new Error("getDetail not implemented");
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
        return [{
            "key": "pref_override_base_url",
            "editTextPreference": {
                "title": "Override base url",
                "summary": "",
                "value": "https://soaper.cc",
                "dialogTitle": "Default url: https://soaper.cc",
            }
        }, {
            key: 'pref_content_priority',
            listPreference: {
                title: 'Preferred content priority',
                summary: 'Choose which type of content to show first',
                valueIndex: 0,
                entries: ["Movies", "Series"],
                entryValues: ["movies", "series"]
            }
        },
        ];
    }
}

const mangayomiSources = [{
    "name": "Mangapill",
    "lang": "en",
    "baseUrl": "https://mangapill.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=64&domain=https://mangapill.com/",
    "typeSource": "single",
    "isManga": true,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": ""
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        return {
            "Referer": this.source.baseUrl
        }
    }
    async print(msg) { console.log(msg) }

    async getPreference(key) {
        const preferences = new SharedPreferences();
        return parseInt(preferences.get(key))
    }

    async getMangaList(slug) {
        var url = `${this.source.baseUrl}${slug}`
        var res = await new Client().get(url, this.getHeaders());
        var doc = new Document(res.body);
        var list = [];
        var mangaElements = doc.select("div.grid.gap-3.lg > div")
        for (var manga of mangaElements) {
            var details = manga.selectFirst('div').select('a');
            var detLen = details.length
            details = details[detLen - 1]

            var imageUrl = manga.selectFirst("img").getSrc;
            var link = details.getHref;
            var name = details.selectFirst('div').text;
            list.push({ name, imageUrl, link });
        }
        var hasNextPage = false;
        return { list, hasNextPage }
    }

    async getNavPage(prefKey) {
        var val = await this.getPreference(prefKey);
        var slug = ''
        switch (val) {
            case 1: {
                slug = 'mangas/new'
                break;
            }
            case 2: {
                slug = 'chapters'
                break;
            }
        }
        return await this.getMangaList(slug)
    }

    async getPopular(page) {
        return await this.getNavPage("pref_popular_content");
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        return await this.getNavPage("pref_latest_content");
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
            key: 'pref_popular_content',
            listPreference: {
                title: 'Preferred popular content',
                summary: '',
                valueIndex: 0,
                entries: ["New Mangas", "Recent Chapters"],
                entryValues: ["1", "2"]
            }
        }, {
            key: 'pref_latest_content',
            listPreference: {
                title: 'Preferred latest content',
                summary: '',
                valueIndex: 1,
                entries: ["New Mangas", "Recent Chapters"],
                entryValues: ["1", "2"]
            }
        },
        ];
    }
}

const mangayomiSources = [{
    "name": "Mangapill",
    "lang": "en",
    "baseUrl": "https://mangapill.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=64&domain=https://mangapill.com/",
    "typeSource": "single",
    "isManga": true,
    "version": "0.0.4",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/en/mangapill.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        return {
            "Referer": this.source.baseUrl
        }
    }
    print(msg) { console.log(msg) }

    statusCode(status) {
        return {
            "publishing": 0,
            "finished": 1,
            "on hiatus": 2,
            "discontinued": 3,
            "not yet published": 4,
        }[status] ?? 5;
    }

    async getPreference(key) {
        const preferences = new SharedPreferences();
        return parseInt(preferences.get(key))
    }

    async getMangaList(slug) {
        var lang = await this.getPreference("pref_title_lang");

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
            var nameSection = details.select('div');

            var name = (nameSection[1] && lang == 2) ? nameSection[1].text : nameSection[0].text

            list.push({ name, imageUrl, link });
        }
        var hasNextPage = false;
        if (slug.includes("search?q")) {
            hasNextPage = doc.selectFirst(".container.py-3 a.btn.btn-sm").className ? true : false
        }
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

    async searchManga(query, status, type, page) {
        var slug = `search?q=${query}&status=${status}&type=${type}&page=${page}`
        return await this.getMangaList(slug)
    }
    async search(query, page, filters) {
        return await this.searchManga(query, "", "", page);
    }

    async getMangaDetail(slug) {
        var lang = await this.getPreference("pref_title_lang");

        var link = `${this.source.baseUrl}${slug}`
        var res = await new Client().get(link, this.getHeaders());
        var doc = new Document(res.body);

        var mangaName = doc.selectFirst(".mb-3 .font-bold.text-lg").text
        if (doc.selectFirst(".mb-3 .text-sm.text-secondary") && lang == 2) mangaName = doc.selectFirst(".mb-3 .text-sm.text-secondary").text
        var description = doc.selectFirst("meta[name='description']").attr("content")
        var imageUrl = doc.selectFirst(".w-full.h-full").getSrc
        var statusText = doc.select(".grid.grid-cols-1 > div")[1].selectFirst("div").text
        var status = this.statusCode(statusText)

        var genre = []
        var genreList = doc.select("a.mr-1")
        for (var gen of genreList) { genre.push(gen.text) }

        var chapters = []
        var chapList = doc.select("div.my-3.grid > a")
        for (var chap of chapList) {
            var name = chap.text
            var url = chap.getHref
            chapters.push({ name, url })
        }
        return { name: mangaName, description, link, imageUrl, status, genre, chapters }
    }

    async getDetail(url) {
        return await this.getMangaDetail(url.substring(1,));

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
        }, {
            key: 'pref_title_lang',
            listPreference: {
                title: 'Preferred title language',
                summary: '',
                valueIndex: 0,
                entries: ["Romaji", "English"],
                entryValues: ["1", "2"]
            }
        }
        ];
    }
}

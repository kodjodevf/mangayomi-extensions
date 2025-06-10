const mangayomiSources = [{
    "name": "Mangafire",
    "langs": ["en", "ja", "fr", "es", "es-la", "pt", "pt-br"],
    "baseUrl": "https://mangafire.to",
    "apiUrl": "",
    "iconUrl": "https://mangafire.to/assets/sites/mangafire/favicon.png?v3",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.1.25",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/all/mangafire.js"
}];

class DefaultExtension extends MProvider {

    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    mangaListFromPage(res) {
        const doc = new Document(res.body);
        const elements = doc.select("div.unit");
        const list = [];

        for (const element of elements) {
            const name = element.selectFirst("div.info > a").text;
            const imageUrl = element.selectFirst("img").getSrc;
            const link = element.selectFirst("a").getHref;
            list.push({ name, imageUrl, link });
        }

        const hasNextPage = doc.selectFirst("li.page-item.active + li").text != "";
        return { "list": list, "hasNextPage": hasNextPage };
    }

    statusFromString(status) {
        return {
            "Releasing": 0,
            "Completed": 1,
            "On_Hiatus": 2,
            "Discontinued": 3,
            "Unrealeased": 4,
        }[status] ?? 5;
    }

    parseDate(date) {
        const months = {
            "jan": "01", "feb": "02", "mar": "03", "apr": "04", "may": "05", "jun": "06", "jul": "07", "aug": "08", "sep": "09", "oct": "10", "nov": "11", "dec": "12"
        };
        date = date.toLowerCase().replace(",", "").split(" ");

        if (!(date[0] in months)) {
            return String(new Date().valueOf())
        }

        date[0] = months[date[0]];
        date = [date[2], date[0], date[1]];
        date = date.join("-");
        return String(new Date(date).valueOf());
    }

    async getPopular(page) {
        console.log(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=trending&page=${page}`);
        const res = await new Client().get(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=trending&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getLatestUpdates(page) {
        const res = await new Client().get(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=recently_updated&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async search(query, page, filters) {
        query = query.trim().replaceAll(/\ +/g, "+");
        let url = `${this.source.baseUrl}/filter?keyword=${query}`;

        // Search sometimes failed because filters were empty. I experienced this mostly on android...
        if (!filters || filters.length == 0) {
            const res = await new Client().get(`${url}&language=${this.source.lang}&page=${page}`);
            return this.mangaListFromPage(res);
        }

        for (const filter of filters[0].state) {
            if (filter.state == true)
                url += `&type%5B%5D=${filter.value}`;
        }

        for (const filter of filters[1].state) {
            if (filter.state == 1)
                url += `&genre%5B%5D=${filter.value}`;
            else if (filter.state == 2)
                url += `&genre%5B%5D=-${filter.value}`;
        }

        // &genre_mode=and

        for (const filter of filters[2].state) {
            if (filter.state == true)
                url += `&status%5B%5D=${filter.value}`;
        }

        url += `&language=${this.source.lang}`;
        url += `&minchap=${filters[3].values[filters[3].state].value}`;
        url += `&sort=${filters[4].values[filters[4].state].value}`;

        const res = await new Client().get(`${url}&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getDetail(url) {
        url = url.replace(this.source.baseUrl,"")
        const viewType = this.getPreference("mangafire_pref_content_view")
        const id = url.split(".").pop();
        const detail = {};

        // extract info
        const infoUrl = this.source.baseUrl + url;
        const infoRes = await new Client().get(infoUrl);
        const infoDoc = new Document(infoRes.body);
        const info = infoDoc.selectFirst("div.info");
        const sidebar = infoDoc.select("aside.sidebar div.meta div");
        detail.name = info.selectFirst("h1").text;
        detail.status = this.statusFromString(info.selectFirst("p").text);
        detail.imageUrl = infoDoc.selectFirst("div.poster img").getSrc;
        detail.author = sidebar[0].selectFirst("a").text;
        detail.description = infoDoc.selectFirst("div#synopsis").text.trim();
        detail.genre = sidebar[2].select("a");
        detail.genre.forEach((e, i) => {
            detail.genre[i] = e.text;
        });

        // get chapter
        // /read/ is needed to get chapter details
        const chapterUrl = this.source.baseUrl + `/ajax/read/${id}/${viewType}/${this.source.lang}`;
        const idRes = await new Client().get(chapterUrl);
        const idDoc = new Document(JSON.parse(idRes.body).result.html);
        const ids = idDoc.select("a");

        var chapElements = null
        if (viewType == "chapter") { // upload date is not present in volumes
            // /manga/ is needed to get chapter upload date
            const chapRes = await new Client().get(this.source.baseUrl + `/ajax/manga/${id}/${viewType}/${this.source.lang}`);
            const chapDoc = new Document(JSON.parse(chapRes.body).result);
            chapElements = chapDoc.selectFirst(".scroll-sm").children;
        }
        detail.chapters = [];
        for (let i = 0; i < ids.length; i++) {
            const id = ids[i]
            const name = id.text;
            const mangaId = id.attr("data-id");

            var scanlator = null
            var dateUpload = null;
            if (viewType == "chapter") { // upload date is not present in volumes
                const chapElement = chapElements[i]
                var title = chapElement.selectFirst("a").attr("title").split(" - ");
                scanlator = title.length > 1 ? title[0] : "Vol 1"
                try {
                    dateUpload = this.parseDate(chapElement.selectFirst("span + span").text);
                } catch (_) {
                    dateUpload = null
                }
            }

            const url = this.source.baseUrl + `/ajax/read/${viewType}/${mangaId}`;
            detail.chapters.push({ name, url, dateUpload, scanlator });
        }
        return detail;
    }

    // For manga chapter pages
    async getPageList(url) {
        var res = await new Client().get(url);
        if(res.statusCode !=200){
            url = url.replace("/volume/","/chapter/")
            res = await new Client().get(url);
        }
        const data = JSON.parse(res.body);
        const pages = [];
        var hdr = { "Referer": this.source.baseUrl }
        data.result.images.forEach(img => {
            pages.push({ url: img[0], headers: hdr });
        });
        return pages;
    }

    getFilterList() {
        return [
            {
                type_name: "GroupFilter",
                name: "Type",
                state: [
                    ["Manga", "manga"],
                    ["One-Shot", "one_shot"],
                    ["Doujinshi", "doujinshi"],
                    ["Novel", "novel"],
                    ["Manhwa", "manhwa"],
                    ["Manhua", "manhua"]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                name: "Genre",
                state: [
                    ["Action", "1"],
                    ["Adventure", "78"],
                    ["Avant Garde", "3"],
                    ["Boys Love", "4"],
                    ["Comedy", "5"],
                    ["Demons", "77"],
                    ["Drama", "6"],
                    ["Ecchi", "7"],
                    ["Fantasy", "79"],
                    ["Girls Love", "9"],
                    ["Gourmet", "10"],
                    ["Harem", "11"],
                    ["Horror", "530"],
                    ["Isekai", "13"],
                    ["Iyashikei", "531"],
                    ["Josei", "15"],
                    ["Kids", "532"],
                    ["Magic", "539"],
                    ["Mahou Shoujo", "533"],
                    ["Martial Arts", "534"],
                    ["Mecha", "19"],
                    ["Military", "535"],
                    ["Music", "21"],
                    ["Mystery", "22"],
                    ["Parody", "23"],
                    ["Psychological", "536"],
                    ["Reverse Harem", "25"],
                    ["Romance", "26"],
                    ["School", "73"],
                    ["Sci-Fi", "28"],
                    ["Seinen", "537"],
                    ["Shoujo", "30"],
                    ["Shounen", "31"],
                    ["Slice of Life", "538"],
                    ["Space", "33"],
                    ["Sports", "34"],
                    ["SuperPower", "75"],
                    ["Supernatural", "76"],
                    ["Suspense", "37"],
                    ["Thriller", "38"],
                    ["Vampire", "39"]
                ].map(x => ({ type_name: 'TriState', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                name: "Status",
                state: [
                    ["Releasing", "releasing"],
                    ["Completed", "completed"],
                    ["Hiatus", "on_hiatus"],
                    ["Discontinued", "discontinued"],
                    ["Not Yet Published", "info"]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "length",
                name: "Length",
                values: [
                    [">= 1 chapters", "1"],
                    [">= 3 chapters", "3"],
                    [">= 5 chapters", "5"],
                    [">= 10 chapters", "10"],
                    [">= 20 chapters", "20"],
                    [">= 30 chapters", "30"],
                    [">= 50 chapters", "50"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "sort",
                name: "Sort",
                state: 3,
                values: [
                    ["Added", "recently_added"],
                    ["Updated", "recently_updated"],
                    ["Trending", "trending"],
                    ["Most Relevance", "most_relevance"],
                    ["Name", "title_az"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            }
        ];
    }

    getSourcePreferences() {
        return [{
            key: 'mangafire_pref_content_view',
            listPreference: {
                title: 'View manga as',
                summary: '',
                valueIndex: 0,
                entries: ["Chapters", "Volumes"],
                entryValues: ["chapter", "volume"]
            }
        }]
    }
}

const mangayomiSources = [{
    "name": "Weebcentral",
    "lang": "en",
    "baseUrl": "https://weebcentral.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://weebcentral.com",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.5",
    "pkgPath": "manga/src/en/weebcentral.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }

    async request(slug) {
        var url = `${this.source.baseUrl}/${slug}`
        var res = await new Client().get(url);
        return new Document(res.body);
    }

    async getMangaList(slug, page = 0) {
        var page = parseInt(page)

        slug = page > 0 ? `${slug}/${page}` : slug

        var doc = await this.request(slug);
        var list = [];
        var mangaElements = doc.select("article.bg-base-100")
        for (var manga of mangaElements) {
            var details = manga.selectFirst('a')
            if (details.getHref.indexOf("/series/") < 0) continue;

            details = details.selectFirst("img");

            var imageUrl = details.getSrc;
            var urlSplits = imageUrl.split("/")

            var link = urlSplits[urlSplits.length - 1].split(".")[0]
            var name = details.attr("alt")

            list.push({ name, imageUrl, link });
        }
        var hasNextPage = page < 142 ? true : false;
        return { list, hasNextPage }
    }

    async getPopular(page) {
        return await this.getMangaList("hot-updates")
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        return await this.getMangaList("latest-updates", page)
    }

    getImageUrl(id) { return `https://temp.compsci88.com/cover/normal/${id}.webp`; }

    async search(query, page, filters) {
        var offset = 32 * (parseInt(page) - 1)
        var sort = filters[0].values[filters[0].state].value
        var order = filters[1].values[filters[1].state].value
        var translation = filters[2].values[filters[2].state].value
        var status = ""
        for (var filter of filters[3].state) {
            if (filter.state == true)
                status += `&included_status=${filter.value}`
        }
        var type = ""
        for (var filter of filters[4].state) {
            if (filter.state == true)
                type += `&included_type=${filter.value}`
        }
        var tags = ""
        for (var filter of filters[5].state) {
            if (filter.state == true)
                tags += `&included_tag=${filter.value}`
        }

        var slug = `search/data?limit=32&offset=${offset}&author=&text=${query}&sort=${sort}&order=${order}&official=${translation}${status}${type}${tags}&display_mode=Minimal%20Display`
        var doc = await this.request(slug);
        var list = []
        var mangaElements = doc.select("article.bg-base-300")
        for (var manga of mangaElements) {
            var details = manga.selectFirst('a')

            var mangaLink = details.getHref;
            var urlSplits = mangaLink.split("/")

            var link = urlSplits[urlSplits.length - 2]
            var name = details.selectFirst("h2").text
            var imageUrl = this.getImageUrl(link)

            list.push({ name, imageUrl, link });
        }

        var hasNextPage = doc.selectFirst("button").text.length > 0;
        return { list, hasNextPage }

    }

    statusCode(status) {
        return {
            "Ongoing": 0,
            "Complete": 1,
            "Hiatus": 2,
            "Canceled": 3,
        }[status] ?? 5;
    }

    async getDetail(url) {
        var slug = `series/${url}`
        var link = `${this.source.baseUrl}/${slug}`
        var doc = await this.request(slug);
        var imageUrl = this.getImageUrl(url)
        var title = doc.selectFirst("h1").text
        var description = doc.selectFirst("p.whitespace-pre-wrap.break-words").text

        var chapters = []
        var ul = doc.select("ul.flex.flex-col.gap-4 > li")
        var author = ""
        var genre = []
        var status = 5
        for (var li of ul) {
            var strongTxt = li.selectFirst("strong").text
            if (strongTxt.indexOf("Author(s):") != -1) {
                author = li.selectFirst("a").text
            } else if (strongTxt.indexOf("Tags(s):") != -1) {
                li.select("a").forEach(a => genre.push(a.text))
            } else if (strongTxt.indexOf("Status:") != -1) {
                status = this.statusCode(li.selectFirst("a").text)
            }

        }

        var chapSlug = `${slug}/full-chapter-list`
        doc = await this.request(chapSlug);
        var chapList = doc.select("div.flex.items-center");
        for (var chap of chapList) {
            var name = chap.selectFirst("span.grow.flex.items-center.gap-2").selectFirst("span").text
            var dateUpload = new Date(chap.selectFirst("time.text-datetime").text).valueOf().toString()
            var url = chap.selectFirst("input").attr("value")
            chapters.push({ name, url, dateUpload })
        }
        return { name: title, description, link, imageUrl, author, genre, status, chapters }

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
        var slug = `chapters/${url}/images?current_page=1&reading_style=long_strip`
        var doc = await this.request(slug);

        var urls = [];

        doc.select("section > img").forEach(page => urls.push(page.attr("src")))

        return urls
    }

    getFilterList() {
        return [
            {
                type_name: "SelectFilter",
                name: "Sort",
                state: 0,
                values: [
                    ["Best Match", "Best Match"],
                    ["Alphabet", "Alphabet"],
                    ["Popularity", "Popularity"],
                    ["Subscribers", "Subscribers"],
                    ["Recently Added", "Recently Added"],
                    ["Latest Updates", "Latest Updates"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            }, {
                type_name: "SelectFilter",
                name: "Order",
                state: 0,
                values: [
                    ["Ascending", "Ascending"],
                    ["Descending", "Descending"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            }, {
                type_name: "SelectFilter",
                name: "Official Translation",
                state: 0,
                values: [
                    ["Any", "Any"],
                    ["True", "True"],
                    ["False", "False"],
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            }, {
                type_name: "GroupFilter",
                name: "Series Status",
                state: [
                    ["Ongoing", "Ongoing"],
                    ["Complete", "Complete"],
                    ["Hiatus", "Hiatus"],
                    ["Canceled", "Canceled"],
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            }, {
                type_name: "GroupFilter",
                name: "Series Type",
                state: [
                    ["Manga", "Manga"],
                    ["Manhwa", "Manhwa"],
                    ["Manhua", "Manhua"],
                    ["OEL", "OEL"],
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            }, {
                type_name: "GroupFilter",
                name: "Tags",
                state: [
                    ["Action", "Action"],
                    ["Adventure", "Adventure"],
                    ["Adult", "Adult"],
                    ["Comedy", "Comedy"],
                    ["Doujinshi", "Doujinshi"],
                    ["Drama", "Drama"],
                    ["Ecchi", "Ecchi"],
                    ["Fantasy", "Fantasy"],
                    ["Gender Bender", "Gender Bender"],
                    ["Harem", "Harem"],
                    ["Hentai", "Hentai"],
                    ["Historical", "Historical"],
                    ["Horror", "Horror"],
                    ["Isekai", "Isekai"],
                    ["Josei", "Josei"],
                    ["Lolicon", "Lolicon"],
                    ["Martial Arts", "Martial Arts"],
                    ["Mature", "Mature"],
                    ["Mecha", "Mecha"],
                    ["Mystery", "Mystery"],
                    ["Psychological", "Psychological"],
                    ["Romance", "Romance"],
                    ["School Life", "School Life"],
                    ["Sci-Fi", "Sci-Fi"],
                    ["Seinen", "Seinen"],
                    ["Shotacon", "Shotacon"],
                    ["Shoujo", "Shoujo"],
                    ["Shoujo Ai", "Shoujo Ai"],
                    ["Shounen", "Shounen"],
                    ["Slice of Life", "Slice of Life"],
                    ["Smut", "Smut"],
                    ["Sports", "Sports"],
                    ["Supernatural", "Supernatural"],
                    ["Tragedy", "Tragedy"],
                    ["Yaoi", "Yaoi"],
                    ["Yuri", "Yuri"],
                    ["Other", "Other"]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            }
        ]
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

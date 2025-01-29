const mangayomiSources = [{
    "name": "Weebcentral",
    "lang": "en",
    "baseUrl": "https://weebcentral.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://weebcentral.com",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.3",
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
    async search(query, page, filters) {
        throw new Error("search not implemented");
    }

    getImageUrl(id) { return `https://temp.compsci88.com/cover/normal/${id}.webp`; }

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
        var slug = `/chapters/${url}/images?current_page=1&reading_style=long_strip`
        var doc = await this.request(slug);

        var urls = [];

        doc.select("section > img").forEach(page=>urls.push(page.attr("src")))

        return urls
    }
    
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

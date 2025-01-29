const mangayomiSources = [{
    "name": "Weebcentral",
    "lang": "en",
    "baseUrl": "https://weebcentral.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://weebcentral.com",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.1",
    "pkgPath": "manga/src/en/weebcentral.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }

    async getMangaList(slug,page=0) {
        var page = parseInt(page)
        var url = `${this.source.baseUrl}/${slug}`
        url = page>0?url+`/${page}`:url

        var res = await new Client().get(url);
        var doc = new Document(res.body);
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
        var hasNextPage = page < 142? true : false;
        return { list, hasNextPage }
    }

    async getPopular(page) {
        return await this.getMangaList("hot-updates")
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        return await this.getMangaList("latest-updates",page)
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
        throw new Error("getSourcePreferences not implemented");
    }
}

const mangayomiSources = [{
    "name": "Dramacool",
    "lang": "all",
    "baseUrl": "https://dramacool.com.tr",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://dramacool.com.tr",
    "typeSource": "multi",
    "itemType": 1,
    "version": "0.0.1",
    "pkgPath": "anime/src/all/dramacool.js"
}];

class DefaultExtension extends MProvider {

    getHeaders(url) {
        return {
            Referer: url
        }
    }

    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    getBaseUrl() {
        return this.source.baseUrl;
    }

    async request(slug) {
        const baseUrl = this.getBaseUrl()
        var url = `${baseUrl}${slug}`
        var res = await new Client().get(url, this.getHeaders(baseUrl));
        var doc = new Document(res.body);
        return doc
    }

    async getList(slug) {
        var body = await this.request(slug);
        var list = []
        var hasNextPage = body.selectFirst("a.next.page-numbers").text.length > 0 ? true : false;
        var items = body.select(".switch-block.list-episode-item > li")
        items.forEach(item => {
            var a = item.selectFirst("a")
            var link = a.getHref.replace(this.getBaseUrl(), "")
            var imageUrl = a.selectFirst("img").getSrc
            var name = a.selectFirst("h3").text

            list.push({ name, link, imageUrl })

        })

        return { list, hasNextPage };
    }

    async getPopular(page) {
        var slug = "/most-popular-drama"
        return await this.getList(`${slug}/page/${page}/`)
    }

    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        var slug = this.getPreference("dramacool_latest_list")
        return await this.getList(`${slug}/page/${page}/`)
    }
    async search(query, page, filters) {
        var slug = `/page/${page}/?type=movies&s=${query}`
        return await this.getList(slug)
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
                key: 'dramacool_latest_list',
                listPreference: {
                    title: 'Preferred latest list',
                    summary: 'Choose which type of content to be shown "Lastest"',
                    valueIndex: 0,
                    entries: ["Drama", "Movie", "KShow"],
                    entryValues: ["recently-added-drama", "recently-added-movie", "recently-added-kshow"]
                }
            }
        ]
    }
}

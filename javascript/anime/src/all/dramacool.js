const mangayomiSources = [{
    "name": "Dramacool",
    "lang": "all",
    "baseUrl": "https://dramacool.com.tr",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://dramacool.com.tr",
    "typeSource": "multi",
    "itemType": 1,
    "version": "0.0.2",
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
        return await this.getList(`/${slug}/page/${page}/`)
    }

    statusFromString(status) {
        return {
            "Ongoing": 0,
            "Completed": 1,
        }[status] ?? 5;
    }

    async search(query, page, filters) {
        var slug = `/page/${page}/?type=movies&s=${query}`
        return await this.getList(slug)
    }

    formatReleaseDate(str) {
        var timeSplit = str.split(" ")
        var t = parseInt(timeSplit[0])
        var unit = timeSplit[1]

        var mins = 0
        var mons = 0
        if(unit.includes('minute')){
            mins = t;
        }else if(unit.includes('hour')){
            mins = t * 60;
        }else if(unit.includes('day')){
            mins = t * 60 * 24;
        }else if(unit.includes('week')){
            mins = t * 60 * 24 * 7;
        }else if(unit.includes('month')){
            mons = t;
        }
        var now = new Date();
        now.setMinutes(now.getMinutes() - mins)
        now.setMinutes(now.getMonth() - mons)
        var pastDate = new Date(now);
        return ""+pastDate.valueOf();
    }

    async getDetail(url) {
        if (url.includes("-episode")) {
            url = '/series' + url.split("-episode")[0] + "/"
        } else if (url.includes("-full-movie")) {
            url = '/series' + url.split("-full-movie")[0] + "/"
        }

        var body = await this.request(url);
        var infos = body.select(".info > p")

        var name = body.selectFirst("h1").text.trim()
        var imageUrl = body.selectFirst(".img").selectFirst("img").getSrc
        var isDescription = infos[1].text.includes("Description")
        var description = isDescription ? infos[2].text.trim() : ""
        var link = `${this.getBaseUrl()}${url}`
        var statusIndex = infos.at(-3).text.includes("Status:") ? -3 : -2
        var status = this.statusFromString(infos.at(statusIndex).selectFirst("a").text)
        var genre = []
        infos.at(-1).select("a").forEach(a => genre.push(a.text.trim()))

        var chapters = []
        var epLists = body.select("ul.list-episode-item-2.all-episode > li")
        for (var ep of epLists) {
            var a = ep.selectFirst('a')
            var epLink = a.getHref.replace(this.getBaseUrl(), "")
            var epName = a.selectFirst("h3").text.replace(name + " ", "")
            var scanlator = a.selectFirst("span.type").text
            var dateUpload = this.formatReleaseDate(a.selectFirst("span.time").text)
            chapters.push({
                name: epName,
                url: epLink,
                scanlator,
                dateUpload
            })

        }

        return { name, imageUrl, description, link, status, genre, chapters }
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

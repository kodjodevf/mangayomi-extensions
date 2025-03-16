const mangayomiSources = [{
    "name": "AnimeGG",
    "lang": "en",
    "baseUrl": "https://www.animegg.org",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://www.animegg.org/",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.0.3",
    "pkgPath": "anime/src/en/animegg.js"
}];

class DefaultExtension extends MProvider {

    constructor() {
        super();
        this.client = new Client();
    }

    getHeaders(url) {
        return {
            Referer: this.getSourcePreferences.baseUrl,
            Origin: this.getSourcePreferences.baseUrl
        }
    }

    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    async request(slug) {
        var url = `${this.source.baseUrl}${slug}`
        var res = await this.client.get(url, this.getHeaders());
        return new Document(res.body);
    }
    
    async fetchPopularnLatest(slug) {
        var body = await this.request(slug)
        var items = body.select("li.fea")
        var list = []
        var hasNextPage = true
        if (items.length > 0) {
            for (var item of items) {
                var imageUrl = item.selectFirst('img').getSrc
                var link = item.selectFirst('a').getHref
                var name = item.selectFirst(".rightpop").text
                list.push({
                    name,
                    imageUrl,
                    link
                });

            }
        }
        else {
            hasNextPage = false
        }
        return { list, hasNextPage }
    }

    async getPopular(page) {
        var start = (page - 1) * 25;
        var limit = start + 25;

        var category = ""
        var pop = parseInt(this.getPreference("animegg_popular_category"))
        switch (pop) {
            case 1: {
                category = "sortBy=createdAt&sortDirection=DESC&";
                break;
            }
            case 2: {
                category = "ongoing=true&";
                break;
            }
            case 3: {
                category = "ongoing=false&";
                break;
            }
            case 4: {
                category = "sortBy=sortLetter&sortDirection=ASC&";
                break;
            }

        }
        var slug = `/popular-series?${category}start=${start}&limit=${limit}`
        return await this.fetchPopularnLatest(slug)
        

    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        var start = (page - 1) * 25;
        var limit = start + 25;

        var slug = `/releases?start=${start}&limit=${limit}`
        return await this.fetchPopularnLatest(slug)

    }
    async search(query, page, filters) {
        var slug = `/search?q=${query}`
        var body = await this.request(slug)
        var items = body.select(".moose.page > a")
        var list = []
            for (var item of items) {
                var imageUrl = item.selectFirst('img').getSrc
                var link = item.getHref
                var name = item.selectFirst("h2").text
                list.push({
                    name,
                    imageUrl,
                    link
                });

            }
       
        return { list, hasNextPage:false }
    }

    statusCode(status) {
        return {
            "Ongoing": 0,
            "Completed": 1,
        }[status] ?? 5;
    }

    async getDetail(url) {
        var link = this.source.baseUrl + url;

        var body = await this.request(url)

        var media = body.selectFirst(".media")
        var title = media.selectFirst("h1").text
        var spans = media.selectFirst("p.infoami").select("span")
        var statusText = spans[spans.length - 1].text.replace("Status: ",'')
        var status = this.statusCode(statusText)


        var tagscat = media.select(".tagscat > li")
        var genre = []
        tagscat.forEach(tag => genre.push(tag.text))
        var description = body.selectFirst("p.ptext").text
        var chapters = []

        var episodesList = body.select(".newmanga > li")
        episodesList.forEach(ep => {
            var epTitle = ep.selectFirst('i.anititle').text
            var epNumber = ep.selectFirst('strong').text.replace(title,"Episode")
            var epName = epNumber == epTitle?epNumber:`${epNumber} - ${epTitle}`
            var epUrl = ep.selectFirst("a").getHref

            var scanlator = "";
            var type = ep.select("span.btn-xs")
            type.forEach(t => {
                scanlator += t.text + ", ";

            })
            scanlator = scanlator.slice(0, -2);

            chapters.push({ name: epName, url: epUrl,scanlator})
        })


        return { description, status,  genre, chapters, link }



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
                key: "animegg_popular_category",
                listPreference: {
                    title: 'Preferred popular category',
                    summary: '',
                    valueIndex: 0,
                    entries: ["Popular", "Newest", "Ongoing", "Completed", "Alphabetical"],
                    entryValues: ["0", "1", "2", "3", "4"]
                }
            }
        ]
    }
}

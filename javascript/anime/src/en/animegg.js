const mangayomiSources = [{
    "name": "AnimeGG",
    "lang": "en",
    "baseUrl": "https://www.animegg.org",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://www.animegg.org/",
    "typeSource": "single",
    "itemType": 1,
    "version": "1.0.2",
    "pkgPath": "anime/src/en/animegg.js"
}];

class DefaultExtension extends MProvider {

    constructor() {
        super();
        this.client = new Client();
    }

    getHeaders(url) {
        return {
            "Referer": this.source.baseUrl,
            "Origin": this.source.baseUrl
        }
    }

    getPreference(key) {
        return parseInt(new SharedPreferences().get(key));
    }

    async requestText(slug) {
        var url = `${this.source.baseUrl}${slug}`
        var res = await this.client.get(url, this.getHeaders());
        return res.body;
    }
    async request(slug) {
        return new Document(await this.requestText(slug));
    }

    async fetchPopularnLatest(slug) {
        var body = await this.request(slug)
        var items = body.select("li.fea")
        var list = []
        var hasNextPage = true
        if (items.length > 0) {
            for (var item of items) {
                var imageUrl = item.selectFirst('img').getSrc
                var linkSection = item.selectFirst('.rightpop').selectFirst('a')
                var link = linkSection.getHref
                var name = linkSection.text
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
        var pop = this.getPreference("animegg_popular_category")
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

        return { list, hasNextPage: false }
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
        var statusText = spans[spans.length - 1].text.replace("Status: ", '')
        var status = this.statusCode(statusText)


        var tagscat = media.select(".tagscat > li")
        var genre = []
        tagscat.forEach(tag => genre.push(tag.text))
        var description = body.selectFirst("p.ptext").text
        var chapters = []

        var episodesList = body.select(".newmanga > li")
        episodesList.forEach(ep => {
            var epTitle = ep.selectFirst('i.anititle').text
            var epNumber = ep.selectFirst('strong').text.replace(title, "Episode")
            var epName = epNumber == epTitle ? epNumber : `${epNumber} - ${epTitle}`
            var epUrl = ep.selectFirst("a").getHref

            var scanlator = "";
            var type = ep.select("span.btn-xs")
            type.forEach(t => {
                scanlator += t.text + ", ";

            })
            scanlator = scanlator.slice(0, -2);

            chapters.push({ name: epName, url: epUrl, scanlator })
        })


        return { description, status, genre, chapters, link }



    }

    async exxtractStreams(div,audio){
    
        var slug = div.selectFirst("iframe").getSrc
        var streams = []
        if(slug.length < 1){
            return streams;
        }
        var body = await this.requestText(slug)
        var sKey = "var videoSources = "
        var eKey = "var httpProtocol"
        var start = body.indexOf(sKey) + sKey.length
        var end = body.indexOf(eKey) - 8
        var videoSourcesStr = body.substring(start, end)
        let videoSources = eval("(" + videoSourcesStr + ")");
        var headers = this.getHeaders();
        videoSources.forEach(videoSource => {
            var url = this.source.baseUrl +videoSource.file
            var quality = `${videoSource.label} - ${audio}`

            streams.push({
                url,
                originalUrl: url,
                quality,
                headers
            });
        });
        return streams.reverse();
    }

    // For anime episode video list
    async getVideoList(url) {
        var body = await this.request(url)
        
        var sub = body.selectFirst("#subbed-Animegg")
        var subStreams = await this.exxtractStreams(sub,"Sub")

        var dub = body.selectFirst("#dubbed-Animegg")
        var dubStreams = await this.exxtractStreams(dub,"Dub")

        var raw = body.selectFirst("#raw-Animegg")
        var rawStreams = await this.exxtractStreams(raw,"Raw")



        var pref = this.getPreference("animegg_stream_type_1")
        var streams = [];
        if(pref == 0){
            streams = [...subStreams,...dubStreams, ...rawStreams]
        }else if(pref == 1){
            streams = [...dubStreams,...subStreams, ...rawStreams]
        }else{
            streams = [...rawStreams,...subStreams, ...dubStreams]
        }
       
        return streams

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
            },
            {
                key: "animegg_stream_type_1",
                listPreference: {
                    title: 'Preferred stream type',
                    summary: '',
                    valueIndex: 0,
                    entries: ["Sub","Dub","Raw"],
                    entryValues: ["0", "1", "2"]
                }
            }
        ]
    }
}

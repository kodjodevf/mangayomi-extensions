const mangayomiSources = [{
    "name": "Dramacool",
    "lang": "all",
    "baseUrl": "https://dramacool.com.tr",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://dramacool.com.tr",
    "typeSource": "multi",
    "itemType": 1,
    "version": "1.0.0",
    "pkgPath": "anime/src/all/dramacool.js"
}];

class DefaultExtension extends MProvider {

    getHeaders(url) {
        return {
            'Referer': url,
            'User-Agent': "Mozilla/5.0 (Windows NT 10.0; WOW64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.6788.76 Safari/537.36"
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
        if (unit.includes('minute')) {
            mins = t;
        } else if (unit.includes('hour')) {
            mins = t * 60;
        } else if (unit.includes('day')) {
            mins = t * 60 * 24;
        } else if (unit.includes('week')) {
            mins = t * 60 * 24 * 7;
        } else if (unit.includes('month')) {
            mons = t;
        }
        var now = new Date();
        now.setMinutes(now.getMinutes() - mins)
        now.setMinutes(now.getMonth() - mons)
        var pastDate = new Date(now);
        return "" + pastDate.valueOf();
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

    async splitStreams(streams, server) {
        var pref = this.getPreference("dramacool_split_stream_quality");
        if (!pref) return streams
        var autoStream = streams[0]
        var autoStreamUrl = autoStream.url
        var hdr = autoStream.headers
        var hostUrl = ""
        if (server == "Asianload") {
            hostUrl = autoStreamUrl.substring(0, autoStreamUrl.indexOf("/media"))
        } else {
            hostUrl = autoStreamUrl.substring(0, autoStreamUrl.indexOf("master.m3u8"))
        }


        var response = await new Client().get(autoStreamUrl, hdr)
        var body = response.body;
        var lines = body.split('\n');

        for (let i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('#EXT-X-STREAM-INF:')) {
                var resolution = lines[i].match(/RESOLUTION=(\d+x\d+)/)[1];
                resolution = `${server} - ${resolution}`
                var m3u8Url = lines[i + 1].trim();
                m3u8Url = hostUrl + m3u8Url
                streams.push({
                    url: m3u8Url,
                    originalUrl: m3u8Url,
                    quality: resolution,
                    headers: hdr
                });
            }
        }


        return streams
    }

    decodeBase64(f) {
        var g = {},
            b = 65,
            d = 0,
            a, c = 0,
            h, e = "",
            k = String.fromCharCode,
            l = f.length;
        for (a = ""; 91 > b;) a += k(b++);
        a += a.toLowerCase() + "0123456789+/";
        for (b = 0; 64 > b; b++) g[a.charAt(b)] = b;
        for (a = 0; a < l; a++)
            for (b = g[f.charAt(a)], d = (d << 6) + b, c += 6; 8 <= c;)((h = d >>> (c -= 8) & 255) || a < l - 2) && (e += k(h));
        return e
    };

    async extractDramacoolEmbed(doc) {
        var streams = []
        var script = doc.select('script').at(-2)
        var unpack = unpackJs(script.text)

        var skey = 'hls2":"'
        var eKey = '"};jwplayer'
        var start = unpack.indexOf(skey) + skey.length
        var end = unpack.indexOf(eKey, start)
        var track = unpack.substring(start, end)

        streams.push({
            url: track,
            originalUrl: track,
            quality: "Dramacool - Auto",
            headers: this.getHeaders("https://dramacool.men/")
        });

        streams = await this.splitStreams(streams, "Dramacool")

        return streams
    }

    async extractAsianLoadEmbed(doc) {
        var streams = []
        var script = doc.select('script').at(-2)
        var unpack = script.text

        // tracks
        var skey = '|image|'
        var eKey = '|'
        var start = unpack.indexOf(skey) + skey.length
        var end = unpack.indexOf(eKey, start)
        var track = unpack.substring(start, end)
        var streamUrl = this.decodeBase64(track)

        // subs
        eKey = "|default|"
        var end = unpack.indexOf(eKey)
        var subs = []
        if (end != -1) {
            skey = "|type|"
            var start = unpack.indexOf(skey) + skey.length
            var subTracks = unpack.substring(start, end).split("|")
            subs.push({
                file: this.decodeBase64(subTracks[1]),
                label: subTracks[0]
            })

        }

        streams.push({
            url: streamUrl,
            originalUrl: streamUrl,
            quality: "Asianload - Auto",
            subtitles: subs,
            headers: this.getHeaders("https://asianload.cfd/")
        });

        // Download url
        skey = '|_blank|'
        eKey = '|'
        start = unpack.indexOf(skey) + skey.length
        end = unpack.indexOf(eKey, start)
        track = unpack.substring(start, end)
        var downUrl = this.decodeBase64(track)

        streams.push({
            url: downUrl,
            originalUrl: downUrl,
            quality: "Asianload - Direct download",
            headers: this.getHeaders("https://asianload.cfd/")
        });


        streams = await this.splitStreams(streams, "Asianload")

        return streams
    }

    // Sorts streams based on user preference.
    async sortStreams(streams) {
        var sortedStreams = [];

        var copyStreams = streams.slice()
        var pref = this.getPreference("dramacool_video_resolution");
        for (var i in streams) {
            var stream = streams[i];
            if (stream.quality.indexOf(pref) > -1) {
                sortedStreams.push(stream);
                var index = copyStreams.indexOf(stream);
                if (index > -1) {
                    copyStreams.splice(index, 1);
                }
                break;
            }
        }
        return [...sortedStreams, ...copyStreams]
    }

    // For anime episode video list
    async getVideoList(url) {
        var res = await this.request(url)
        var iframe = res.selectFirst("iframe").attr("src").trim()
        if (iframe == "") {
            throw new Error("No iframe found")
        }

        var streams = []

        res = await new Client().get(iframe)
        var doc = new Document(res.body);

        if (iframe.includes("//dramacool")) {
            streams = await this.extractDramacoolEmbed(doc)
        } else if (iframe.includes("//asianload")) {
            streams = await this.extractAsianLoadEmbed(doc)
        }

        return this.sortStreams(streams)

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
            },
            {
                key: 'dramacool_split_stream_quality',
                switchPreferenceCompat: {
                    title: 'Split stream into different quality streams',
                    summary: "Split stream Auto into 360p/720p/1080p",
                    value: true
                }
            }, {
                key: 'dramacool_video_resolution',
                listPreference: {
                    title: 'Preferred video resolution',
                    summary: '',
                    valueIndex: 0,
                    entries: ["Auto", "Direct download", "720p", "480", "360p"],
                    entryValues: ["Auto", "download", "720", "480", "360"]
                }
            },
        ]
    }
}

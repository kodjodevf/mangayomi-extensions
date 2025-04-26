const mangayomiSources = [{
    "name": "NetMirror",
    "id": 446414301,
    "lang": "all",
    "baseUrl": "https://iosmirror.cc",
    "apiUrl": "https://pcmirror.cc",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.netflixmirror.png",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.3.2",
    "pkgPath": "anime/src/all/netflixmirror.js"
}];

class DefaultExtension extends MProvider {

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }

    getTVBaseUrl() {
        return this.getPreference("netmirror_override_tv_base_url");
    }

    getServiceDetails() {
        return this.getPreference("netmirror_pref_service");
    }

    getPoster(id, service) {
        if (service === "nf")
            return `https://imgcdn.media/poster/v/${id}.jpg`
        if (service === "pv")
            return `https://imgcdn.media/pv/480/${id}.jpg`
    }

    async getCookie(service) {
        const preferences = new SharedPreferences();
        let cookie = preferences.getString("cookie", "");
        var cookie_ts = parseInt(preferences.getString("cookie_ts", "0"));
        var now_ts = parseInt(new Date().getTime() / 1000);

        // Cookie lasts for 24hrs but still checking for 12hrs
        if (now_ts - cookie_ts > 60 * 60 * 12) {
            var baseUrl = this.getTVBaseUrl()
            const check = await new Client().get(baseUrl + `/mobile/home`, { "cookie": cookie });
            const hDocBody = new Document(check.body).selectFirst("body")

            const addhash = hDocBody.attr("data-addhash");
            const data_time = hDocBody.attr("data-time");

            var res = await new Client().post(`${baseUrl}/tv/p.php`, { "cookie": "" }, { "hash": addhash });
            cookie = res.headers["set-cookie"];
            preferences.setString("cookie", cookie);
            preferences.setString("cookie_ts", data_time);
        }

        service = service ?? this.getServiceDetails();

        return `ott=${service}; ${cookie}`;
    }

    async request(slug, service=null, cookie = null) {
        var service = service ?? this.getServiceDetails();
        var cookie = cookie ?? await this.getCookie();

        var srv = ""
        if (service === "pv") srv = "/" + service
        var url = this.getTVBaseUrl() + "/tv" + srv + slug
        return (await new Client().get(url, { "cookie": cookie })).body;
    }


    async getHome(body) {
        var service = this.getServiceDetails();
        var list = []
        if (service === "nf") {
            var body = await this.request("/home", service)
            var elements = new Document(body).select("a.slider-item.boxart-container.open-modal.focusme");

            elements.forEach(item => {
                var id = item.attr("data-post")
                if (id.length > 0) {
                    var imageUrl = this.getPoster(id, service)
                    // Having no name breaks the script so having "id" as name 
                    var name = `\n${id}`
                    list.push({ name, imageUrl, link: id })
                }
            })
        } else {
            var body = await this.request("/homepage.php", service)
            var elements = JSON.parse(body).post

            elements.forEach(item => {
                var ids = item.ids
                ids.split(",").forEach(id => {
                    var imageUrl = this.getPoster(id, service)
                    // Having no name breaks the script so having "id" as name 
                    var name = `\n${id}`
                    list.push({ name, imageUrl, link: id })
                })
            })
        }
        return {
            list: list,
            hasNextPage: false
        }
    }

    async getPopular(page) {
        return await this.getHome()
    }
    async getLatestUpdates(page) {
        return await this.getHome()
    }

    async search(query, page, filters) {
        var service = this.getServiceDetails();
        const data = JSON.parse(await this.request(`/search.php?s=${query}`, service));
        const list = [];
        data.searchResult.map(async (res) => {
            const id = res.id;
            list.push({ name: res.t, imageUrl: this.getPoster(id, service), link: id });
        })

        return {
            list: list,
            hasNextPage: false
        }
    }

    async getDetail(url) {
        var service = this.getServiceDetails();
        var cookie = await this.getCookie(service);
        var linkSlug = "https://netflix.com/title/"
        if (service === "pv") linkSlug = `https://www.primevideo.com/detail/`

        // Check needed while refreshing existing data
        var vidId = url
        if (url.includes(linkSlug)) vidId = url.replaceAll(linkSlug, '')

        const data = JSON.parse(await this.request(`/post.php?id=${vidId}`));
        const name = data.title;
        const genre = [data.ua, ...(data.genre || '').split(',').map(g => g.trim())];
        const description = data.desc;
        let episodes = [];

        var seasons = data.season
        if (seasons) {
            let newEpisodes = [];
            await Promise.all(seasons.map(async (season) => {
                const eps = await this.getEpisodes(name, vidId, season.id, 1, service, cookie);
                newEpisodes.push(...eps);
            }));
            episodes.push(...newEpisodes);

        } else {
            // For movies aka if there are no seasons and episodes
            episodes.push({
                name: `Movie`,
                url: vidId
            });
        }
        var link = `${linkSlug}${vidId}`

        return {
            name, imageUrl: this.getPoster(vidId, service), link, description, status: 1, genre, episodes
        };
    }

    async getEpisodes(name, eid, sid, page, service, cookie) {
        const episodes = [];
        let pg = page;
        while (true) {
            try {
                const data = JSON.parse(await this.request(`/episodes.php?s=${sid}&series=${eid}&page=${pg}`, service, cookie));

                data.episodes?.forEach(ep => {
                    var season = ep.s.replace('S', 'Season ')
                    var epNum = ep.ep.replace("E", "")
                    var epText = `Episode ${epNum}`
                    var title = ep.t
                    title = title == epNum ? title : `${epText}: ${title}`

                    episodes.push({
                        name: `${season} ${title}`,
                        url: ep.id
                    });
                });

                if (data.nextPageShow === 0) break;
                pg++;
            } catch (_) {
                break;
            }
        }

        return episodes.reverse();
    }

    // Sorts streams based on user preference.
    async sortStreams(streams) {
        var sortedStreams = [];

        var copyStreams = streams.slice()
        var pref = this.getPreference("netmirror_pref_video_resolution");
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

    async getVideoList(url) {

        var baseUrl = this.getTVBaseUrl()
        var url = `/playlist.php?id=${url}`
        const data = JSON.parse(await this.request(url));


        let videoList = [];
        let subtitles = [];
        let audios = [];
        var playlist = data[0]
        var source = playlist.sources[0]

        var link = baseUrl + source.file;
        var headers =
        {
            'Origin': baseUrl,
            'Referer': `${baseUrl}/`
        };

        // Auto
        videoList.push({ url: link, quality: "Auto", "originalUrl": link, headers });

        var resp = await new Client().get(link, headers);

        if (resp.statusCode === 200) {
            const masterPlaylist = resp.body;

            if (masterPlaylist.indexOf("#EXT-X-STREAM-INF:") > 1) {

                masterPlaylist.substringAfter('#EXT-X-MEDIA:').split('#EXT-X-MEDIA:').forEach(it => {
                    if (it.includes('TYPE=AUDIO')) {
                        const audioInfo = it.substringAfter('TYPE=AUDIO').substringBefore('\n');
                        const language = audioInfo.substringAfter('NAME="').substringBefore('"');
                        const url = audioInfo.substringAfter('URI="').substringBefore('"');
                        audios.push({ file: url, label: language });
                    }
                });


                masterPlaylist.substringAfter('#EXT-X-STREAM-INF:').split('#EXT-X-STREAM-INF:').forEach(it => {
                    var quality = `${it.substringAfter('RESOLUTION=').substringAfter('x').substringBefore(',')}p`;
                    let videoUrl = it.substringAfter('\n').substringBefore('\n');

                    if (!videoUrl.startsWith('http')) {
                        videoUrl = resp.request.url.substringBeforeLast('/') + `/${videoUrl}`;
                    }
                    var headers =
                    {
                        'Host': videoUrl.match(/^(?:https?:\/\/)?(?:www\.)?([^\/]+)/)[1],
                        'Origin': baseUrl,
                        'Referer': `${baseUrl}/`
                    };
                    videoList.push({ url: videoUrl, quality, originalUrl: videoUrl, headers });

                });
            }


            if ("tracks" in playlist) {
                playlist.tracks.filter(track => track.kind === 'captions').forEach(track => {
                    var subUrl = track.file
                    subUrl = subUrl.startsWith("//") ? `https:${subUrl}` : subUrl;

                    subtitles.push({
                        label: track.label,
                        file: subUrl
                    });
                });
            }
        }



        videoList[0].audios = audios;
        videoList[0].subtitles = subtitles;
        return this.sortStreams(videoList);
    }

    getSourcePreferences() {
        return [{
            key: "netmirror_override_tv_base_url",
            editTextPreference: {
                title: "Override tv base url",
                summary: "",
                value: "https://pcmirror.cc",
                dialogTitle: "Override base url",
                dialogMessage: "",
            }
        }, {
            key: 'netmirror_pref_service',
            listPreference: {
                title: 'Preferred OTT service',
                summary: '',
                valueIndex: 0,
                entries: ["Net mirror", "Prime mirror"],
                entryValues: ["nf", "pv",]
            }
        }, {
            key: 'netmirror_pref_video_resolution',
            listPreference: {
                title: 'Preferred video resolution',
                summary: '',
                valueIndex: 0,
                entries: ["1080p", "720p", "480p"],
                entryValues: ["1080", "720", "480"]
            }
        }
        ];
    }

}

const mangayomiSources = [{
    "name": "NetMirror",
    "id": 446414301,
    "lang": "all",
    "baseUrl": "https://iosmirror.cc",
    "apiUrl": "https://pcmirror.cc",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.netflixmirror.png",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.3.0",
    "pkgPath": "anime/src/all/netflixmirror.js"
}];

class DefaultExtension extends MProvider {

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }

    getMobileBaseUrl() {
        return this.getPreference("netmirror_override_mobile_base_url");
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

    getCookie() {

        return `ott=${service};`;
    }

    async request(slug, service) {
        var service = service ?? this.getServiceDetails();
        var srv = ""
        if (service === "pv") srv = "/" + service
        var url = this.getTVBaseUrl() + "/tv" + srv + slug
        return (await new Client().get(url)).body;
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
        const data = JSON.parse(await this.request(`/search.php?s=${query}`,service));
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
        const cookie = await this.getCookie();

        const data = JSON.parse(await this.request(`/post.php?id=${url}`, cookie));
        const name = data.title;
        const genre = [data.ua, ...(data.genre || '').split(',').map(g => g.trim())];
        const description = data.desc;
        let episodes = [];
        if (data.episodes[0] === null) {
            episodes.push({ name, url: url });
        } else {
            episodes = data.episodes.map(ep => ({
                name: `${ep.s.replace('S', 'Season ')} ${ep.ep.replace('E', 'Episode ')} : ${ep.t}`,
                url: ep.id
            }));
        }
        if (data.nextPageShow === 1) {
            const eps = await this.getEpisodes(name, url, data.nextPageSeason, 2, cookie);
            episodes.push(...eps);
        }
        episodes.reverse();
        if (data.season && data.season.length > 1) {
            let newEpisodes = [];
            const seasonsToProcess = data.season.slice(0, -1);
            await Promise.all(seasonsToProcess.map(async (season) => {
                const eps = await this.getEpisodes(name, url, season.id, 1, cookie);
                newEpisodes.push(...eps);
            }));
            newEpisodes.reverse();
            episodes.push(...newEpisodes);

        }
        var service = this.getServiceDetails();
        var link = `https://netflix.com/title/${url}`
        if (service === "pv") link = `https://www.primevideo.com/detail/${url}`

        return {
            name, imageUrl: this.getPoster(url, service), link, description, status: 1, genre, episodes
        };
    }
    async getEpisodes(name, eid, sid, page, cookie) {
        const episodes = [];
        let pg = page;
        while (true) {
            try {
                const data = JSON.parse(await this.request(`/episodes.php?s=${sid}&series=${eid}&page=${pg}`, cookie));

                data.episodes?.forEach(ep => {
                    episodes.push({
                        name: `${ep.s.replace('S', 'Season ')} ${ep.ep.replace('E', 'Episode ')} : ${ep.t}`,
                        url: ep.id
                    });
                });

                if (data.nextPageShow === 0) break;
                pg++;
            } catch (_) {
                break;
            }
        }

        return episodes;
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
        var slug = ""
        var src = this.getPreference("netmirror_pref_stream_extraction");
        var service = this.getServiceDetails();

        // prime extracton works only in mobile
        if (service == "pv") {
            slug = "/pv"
            src = "mobile"
        }

        var device = "/mobile"
        if (src == 'tv') device = "/tv";

        var baseUrl = src === 'tv' ? this.getTVBaseUrl() : this.getMobileBaseUrl()
        url = baseUrl + device + slug + `/playlist.php?id=${url}`
        const data = JSON.parse(await this.request(url));
        let videoList = [];
        let subtitles = [];
        let audios = [];
        for (const playlist of data) {
            var source = playlist.sources[0]
            var link = baseUrl + source.file;
            var headers =
            {
                'Origin': baseUrl,
                'Referer': `${baseUrl}/`
            };

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
                        var quality = `${it.substringAfter('RESOLUTION=').substringAfter('x').substringBefore(',')}p (${source.label})`;
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
        }


        videoList[0].audios = audios;
        videoList[0].subtitles = subtitles;
        return this.sortStreams(videoList);
    }

    getSourcePreferences() {
        return [
            {
                key: "netmirror_override_mobile_base_url",
                editTextPreference: {
                    title: "Override mobile base url",
                    summary: "",
                    value: "https://netfree.cc",
                    dialogTitle: "Override base url",
                    dialogMessage: "",
                }
            }, {
                key: "netmirror_override_tv_base_url",
                editTextPreference: {
                    title: "Override tv base url",
                    summary: "",
                    value: "https://pcmirror.cc",
                    dialogTitle: "Override base url",
                    dialogMessage: "",
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
            }, {
                "key": "netmirror_pref_display_name_1",
                "switchPreferenceCompat": {
                    "title": "Display media name on home page",
                    "summary": "Homepage loads faster by not calling details API",
                    "value": true
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
                key: 'netmirror_pref_stream_extraction',
                listPreference: {
                    title: 'Preferred stream extraction source',
                    summary: 'Extract stream from which source (if one source fails choose another)',
                    valueIndex: 0,
                    entries: ["TV", "Mobile"],
                    entryValues: ["tv", "mobile"]
                }
            },
        ];
    }

}

const mangayomiSources = [{
    "name": "NetflixMirror",
    "lang": "all",
    "baseUrl": "https://iosmirror.cc",
    "apiUrl": "https://pcmirror.cc",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.netflixmirror.png",
    "typeSource": "single",
    "isManga": false,
    "itemType": 1,
    "version": "0.0.7",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/all/netflixmirror.js"
}];

class DefaultExtension extends MProvider {

    getTVApi() {
        return "https://pcmirror.cc"
    }

    async getCookie() {
        const preferences = new SharedPreferences();
        let cookie;
        cookie = preferences.getString("cookie", "");
        const check = await new Client().get(`${this.source.baseUrl}/home`, { "cookie": cookie });
        const hDocBody = new Document(check.body).selectFirst("body")
        const elements = hDocBody.select(".tray-container, #top10");
        if (elements && elements.length > 0) {
            return cookie;
        }

        const addhash = hDocBody.attr("data-addhash");
        var res = await new Client().post(`${this.getTVApi()}/tv/p.php`, { "cookie": "" }, { "hash": addhash });
        cookie = res.headers["set-cookie"];
        preferences.setString("cookie", cookie);
        return cookie;
    }
    async request(url, cookie, tvApi = false) {
        cookie = cookie ?? await this.getCookie();
        var api = tvApi ? this.getTVApi() : this.source.baseUrl;
        return (await new Client().get(api + url, { "cookie": cookie })).body;
    }
    async getPopular(page) {
        return await this.getPages(await this.request("/home"), ".tray-container, #top10")
    }
    async getLatestUpdates(page) {
        return await this.getPages(await this.request("/home"), ".inner-mob-tray-container")
    }
    async getPages(body, selector) {
        const elements = new Document(body).select(selector);
        const cookie = await this.getCookie();
        const list = [];
        for (const element of elements) {
            const linkElement = element.selectFirst("article, .top10-post");
            const id = linkElement.selectFirst("a").attr("data-post");
            if (id.length > 0) {
                const imageUrl = linkElement.selectFirst(".card-img-container img, .top10-img img").attr("data-src");
                list.push({ name: JSON.parse(await this.request(`/post.php?id=${id}`, cookie)).title, imageUrl, link: id });
            }
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    async search(query, page, filters) {
        const data = JSON.parse(await this.request(`/search.php?s=${query}`));
        const list = [];
        data.searchResult.map(async (res) => {
            const id = res.id;
            list.push({ name: res.t, imageUrl: `https://img.nfmirrorcdn.top/poster/v/${id}.jpg`, link: id });
        })

        return {
            list: list,
            hasNextPage: false
        }
    }
    async getDetail(url) {
        const cookie = await this.getCookie();
        const data = JSON.parse(await this.request(`/post.php?id=${url}`, cookie));
        const name = data.title;
        const genre = [data.ua, ...(data.genre || '').split(',').map(g => g.trim())];
        const description = data.desc;
        let episodes = [];
        if (data.episodes[0] === null) {
            episodes.push({ name, url: JSON.stringify({ id: url, name }) });
        } else {
            episodes = data.episodes.map(ep => ({
                name: `${ep.s.replace('S', 'Season ')} ${ep.ep.replace('E', 'Episode ')} : ${ep.t}`,
                url: JSON.stringify({ id: ep.id, name })
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

        return {
            description, status: 1, genre, episodes
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
                        url: JSON.stringify({ id: ep.id, name })
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

    async getVideoList(url) {
        const baseUrl = this.getTVApi();
        const urlData = JSON.parse(url);
        const data = JSON.parse(await this.request(`/tv/playlist.php?id=${urlData.id}&t=${urlData.name}`, null, true));
        let videoList = [];
        let subtitles = [];
        let audios = [];
        for (const playlist of data) {
            var source = playlist.sources[0]
            var link = baseUrl + source.file;
            

            var resp = await new Client().get(link);

            if (resp.statusCode === 200) {
                const masterPlaylist = resp.body;
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



            playlist.tracks.filter(track => track.kind === 'captions').forEach(track => {
                subtitles.push({
                    label: track.label,
                    file: track.file
                });
            });
        }


        videoList[0].audios = audios;
        videoList[0].subtitles = subtitles;
        return videoList;
    }

}

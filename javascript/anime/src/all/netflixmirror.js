const mangayomiSources = [{
    "name": "NetflixMirror",
    "lang": "all",
    "baseUrl": "https://iosmirror.cc",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.netflixmirror.png",
    "typeSource": "single",
    "isManga": false,
    "version": "0.0.35",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/all/netflixmirror.js"
}];

class DefaultExtension extends MProvider {
    async getCookie() {
        const addhash = new Document((await new Client().get(`${this.source.baseUrl}/home`, { "cookie": "" })).body).selectFirst("body").attr("data-addhash");
        await new Client().get(`${this.source.baseUrl}/v.php?hash=${addhash}`);
        const res = (await new Client().post(`${this.source.baseUrl}/verify2.php`, { "cookie": "" }, { "verify": addhash }));
        return res.headers["set-cookie"];
    }
    async request(url, cookie) {
        cookie = cookie ?? await this.getCookie();
        return (await new Client().get(this.source.baseUrl + url, { "cookie": `ott=nf; hd=on; ${cookie}` })).body;
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
        const baseUrl = this.source.baseUrl;
        const urlData = JSON.parse(url);
        const data = JSON.parse(await this.request(`/playlist.php?id=${urlData.id}&t=${urlData.name}`));
        const videoList = [];
        for (const playlist of data) {
            for (const source of playlist.sources) {
                try {
                    const subtitles = [];
                    playlist.tracks.filter(track => track.kind === 'captions').forEach(track => {
                        subtitles.push({
                            label: track.label,
                            file: track.file
                        });
                    });
                    const link = baseUrl + source.file;
                    const headers =
                    {
                        'Host': link.match(/^(?:https?:\/\/)?(?:www\.)?([^\/]+)/)[1],
                        'Origin': baseUrl,
                        'Referer': `${baseUrl}/`
                    };
                    const resp = await new Client().get(link, headers);

                    if (resp.statusCode === 200) {
                        const masterPlaylist = resp.body;
                        const audios = [];
                        masterPlaylist.substringAfter('#EXT-X-MEDIA:').split('#EXT-X-MEDIA:').forEach(it => {
                            if (it.includes('TYPE=AUDIO')) {
                                const audioInfo = it.substringAfter('TYPE=AUDIO').substringBefore('\n');
                                const language = audioInfo.substringAfter('NAME="').substringBefore('"');
                                const url = audioInfo.substringAfter('URI="').substringBefore('"');
                                audios.push({ file: url, label: language });
                            }
                        });

                        if (!masterPlaylist.includes('#EXT-X-STREAM-INF:')) {
                            if (audios.length === 0) {
                                videoList.push({ url: link, quality: source.label, originalUrl: link, subtitles, headers });
                            } else {
                                videoList.push({ url: link, quality: source.label, originalUrl: link, subtitles, audios, headers });
                            }
                        } else {
                            masterPlaylist.substringAfter('#EXT-X-STREAM-INF:').split('#EXT-X-STREAM-INF:').forEach(it => {

                                const quality = `${it.substringAfter('RESOLUTION=').substringAfter('x').substringBefore(',')}p (${source.label})`;
                                let videoUrl = it.substringAfter('\n').substringBefore('\n');

                                if (!videoUrl.startsWith('http')) {
                                    videoUrl = resp.request.url.substringBeforeLast('/') + `/${videoUrl}`;
                                }
                                const headers =
                                {
                                    'Host': videoUrl.match(/^(?:https?:\/\/)?(?:www\.)?([^\/]+)/)[1],
                                    'Origin': baseUrl,
                                    'Referer': `${baseUrl}/`
                                };
                                if (audios.length === 0) {
                                    videoList.push({ url: videoUrl, quality, originalUrl: videoUrl, subtitles, headers });
                                } else {
                                    videoList.push({ url: videoUrl, quality, originalUrl: videoUrl, subtitles, audios, headers });
                                }

                            });
                        }
                    }
                } catch (_) {

                }
            }
        }
        return videoList;
    }

}
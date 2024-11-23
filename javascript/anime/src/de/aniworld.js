const mangayomiSources = [{
    "name": "AniWorld",
    "lang": "de",
    "baseUrl": "https://aniworld.to",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/de.aniworld.png",
    "typeSource": "single",
    "isManga": false,
    "isNsfw": false,
    "version": "0.0.28",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/de/aniworld.js"
}];

class DefaultExtension extends MProvider {
    constructor () {
        super();
        this.client = new Client();
    }
    async getPopular(page) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/beliebte-animes`);
        const elements = new Document(res.body).select("div.seriesListContainer div");
        const list = [];
        for (const element of elements) {
            const linkElement = element.selectFirst("a");
            const name = element.selectFirst("h3").text;
            const imageUrl = baseUrl + linkElement.selectFirst("img").attr("data-src");
            const link = linkElement.attr("href");
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    async getLatestUpdates(page) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/neu`);
        const elements = new Document(res.body).select("div.seriesListContainer div");
        const list = [];
        for (const element of elements) {
            const linkElement = element.selectFirst("a");
            const name = element.selectFirst("h3").text;
            const imageUrl = baseUrl + linkElement.selectFirst("img").attr("data-src");
            const link = linkElement.attr("href");
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    async search(query, page, filters) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/animes`);
        const elements = new Document(res.body).select("#seriesContainer > div > ul > li > a").filter(e => e.attr("title").toLowerCase().includes(query.toLowerCase()));
        const list = [];
        for (const element of elements) {
            const name = element.text;
            const link = element.attr("href");
            const img = new Document((await this.client.get(baseUrl + link)).body).selectFirst("div.seriesCoverBox img").attr("data-src");
            const imageUrl = baseUrl + img;
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    async getDetail(url) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(baseUrl + url);
        const document = new Document(res.body);
        const imageUrl = baseUrl +
            document.selectFirst("div.seriesCoverBox img").attr("data-src");
        const name = document.selectFirst("div.series-title h1 span").text;
        const genre = document.select("div.genres ul li").map(e => e.text);
        const description = document.selectFirst("p.seri_des").attr("data-full-description");
        const produzent = document.select("div.cast li")
            .filter(e => e.outerHtml.includes("Produzent:"));
        let author = "";
        if (produzent.length > 0) {
            author = produzent[0].select("li").map(e => e.text).join(", ");
        }
        const seasonsElements = document.select("#stream > ul:nth-child(1) > li > a");

        const promises = [];
        const episodes = [];
        for (const element of seasonsElements) {
            promises.push(this.parseEpisodesFromSeries(element));
        }
        for (const p of (await Promise.allSettled(promises))) {
            if (p.status == 'fulfilled') {
                episodes.push(...p.value);
            }
        }
        episodes.reverse();
        return { name, imageUrl, description, author, status: 5, genre, episodes };
    }
    async parseEpisodesFromSeries(element) {
        const seasonId = element.getHref;
        const res = await this.client.get(this.source.baseUrl + seasonId);
        const episodeElements = new Document(res.body).select("table.seasonEpisodesList tbody tr");
        const list = [];
        for (const episodeElement of episodeElements) {
            list.push(this.episodeFromElement(episodeElement));
        }
        return list;
    }
    episodeFromElement(element) {
        const titleAnchor = element.selectFirst("td.seasonEpisodeTitle a");
        const episodeSpan = titleAnchor.selectFirst("span");
        const url = titleAnchor.attr("href");
        const episodeSeasonId = element.attr("data-episode-season-id");
        let episode = episodeSpan.text.replace(/&#039;/g, "'");
        let name = "";
        if (url.includes("/film")) {
            name = `Film ${episodeSeasonId} : ${episode}`;
        } else {
            const seasonMatch = url.match(/staffel-(\d+)\/episode/);
            name = `Staffel ${seasonMatch[1]} Folge ${episodeSeasonId} : ${episode}`;
        }
        return name && url ? { name, url } : {};
    }
    async getVideoList(url) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(baseUrl + url, {
            'Accept': '*/*',
            'Referer': baseUrl + url,
            'Priority': 'u=0, i',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0'
        });
        const document = new Document(res.body);
        let promises = [];
        const videos = [];

        const redirectsElements = document.select("ul.row li");
        const hosterSelection = new SharedPreferences().get("hoster_selection_new");
        const dartClient = new Client({ 'useDartHttpClient': true, "followRedirects": false });

        for (const element of redirectsElements) {
            const host = element.selectFirst("a h4").text;

            if (hosterSelection.includes(host)) {
                const langkey = element.attr("data-lang-key");
                const lang = (langkey == 1 || langkey == 3) ? 'Deutscher' : 'Englischer';
                const type = (langkey == 1) ? 'Dub' : 'Sub';
                const redirect = baseUrl + element.selectFirst("a.watchEpisode").attr("href");
                promises.push((async (redirect, lang, type, host) => {
                    const location = (await dartClient.get(redirect)).headers.location;
                    return await extractAny(location, host.toLowerCase(), lang, type, host);
                })(redirect, lang, type, host));
            }
        }
        for (const p of (await Promise.allSettled(promises))) {
            if (p.status == 'fulfilled') {
                videos.push.apply(videos, p.value);
            }
        }
        return this.sortVideos(videos);
    }
    sortVideos(videos) {
        const preference = new SharedPreferences();
        const hoster = RegExp(preference.get("preferred_hoster_new"));
        const lang = RegExp(preference.get("preferred_lang"));
        videos.sort((a, b) => {
            let qualityMatchA = hoster.test(a.quality) * lang.test(a.quality);
            let qualityMatchB = hoster.test(b.quality) * lang.test(b.quality);
            return qualityMatchB - qualityMatchA;
        });
        return videos;
    }
    getSourcePreferences() {
        return [
            {
                "key": "preferred_lang",
                "listPreference": {
                    "title": "Bevorzugte Sprache",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": [
                        "Deutscher Sub",
                        "Deutscher Dub",
                        "Englischer Sub"
                    ],
                    "entryValues": [
                        "Deutscher Sub",
                        "Deutscher Dub",
                        "Englischer Sub"
                    ]
                }
            },
            {
                "key": "preferred_hoster_new",
                "listPreference": {
                    "title": "Standard-Hoster",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": [
                        "Streamtape",
                        "VOE",
                        "Vidoza",
                        "Doodstream"
                    ],
                    "entryValues": [
                        "Streamtape",
                        "Voe",
                        "Vidoza",
                        "Doodstream"
                    ]
                }
            },
            {
                "key": "hoster_selection_new",
                "multiSelectListPreference": {
                    "title": "Hoster auswählen",
                    "summary": "",
                    "entries": [
                        "Streamtape",
                        "VOE",
                        "Vidoza",
                        "Doodstream"
                    ],
                    "entryValues": [
                        "Streamtape",
                        "VOE",
                        "Vidoza",
                        "Doodstream"
                    ],
                    "values": [
                        "Streamtape",
                        "VOE",
                        "Vidoza",
                        "Doodstream"
                    ]
                }
            }
        ];
    }
}

async function doodExtractor(url) {
    const dartClient = new Client({ 'useDartHttpClient': true, "followRedirects": false });
    let response = await dartClient.get(url);
    while ("location" in response.headers) {
        response = await dartClient.get(response.headers.location);
    }
    const newUrl = response.request.url;
    const doodhost = newUrl.match(/https:\/\/(.*?)\//, newUrl)[0].slice(8, -1);
    const md5 = response.body.match(/'\/pass_md5\/(.*?)',/, newUrl)[0].slice(11, -2);
    const token = md5.substring(md5.lastIndexOf("/") + 1);
    const expiry = new Date().valueOf();
    const randomString = getRandomString(10);

    response = await new Client().get(`https://${doodhost}/pass_md5/${md5}`, { "Referer": newUrl });
    const videoUrl = `${response.body}${randomString}?token=${token}&expiry=${expiry}`;
    const headers = { "User-Agent": "Mangayomi", "Referer": doodhost };
    return [{ url: videoUrl, originalUrl: videoUrl, headers: headers, quality: '' }];
}

async function vidozaExtractor(url) {
    let response = await new Client({ 'useDartHttpClient': true, "followRedirects": true }).get(url);
    const videoUrl = response.body.match(/https:\/\/\S*\.mp4/)[0];
    return [{ url: videoUrl, originalUrl: videoUrl, quality: '' }];
}

_streamTapeExtractor = streamTapeExtractor;
streamTapeExtractor = async (url) => {
    return await _streamTapeExtractor(url, '');
}

_voeExtractor = voeExtractor;
voeExtractor = async (url) => {
    return (await _voeExtractor(url, '')).map(v => {
        v.quality = v.quality.replace(/Voe: (\d+p?)/i, '$1');
        return v;
    });
}

async function extractAny(link, method, lang, type, host) {
    const m = extractAny.methods[method];
    return (!m) ? [] : (await m(link)).map(v => {
        v.quality = v.quality ? `${lang} ${type} ${v.quality} ${host}` : `${lang} ${type} ${host}`;
        return v;
    });
};

extractAny.methods = {
    'doodstream': doodExtractor,
    'streamtape': streamTapeExtractor,
    'vidoza': vidozaExtractor,
    'voe': voeExtractor
};

function getRandomString(length) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
    let result = "";
    for (let i = 0; i < length; i++) {
        const random = Math.floor(Math.random() * 61);
        result += chars[random];
    }
    return result;
}

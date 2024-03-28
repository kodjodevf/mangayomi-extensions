const mangayomiSources = [{
    "name": "AniWorld",
    "lang": "de",
    "baseUrl": "https://aniworld.to",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/de.aniworld.png",
    "typeSource": "single",
    "isManga": false,
    "isNsfw": false,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/de/aniworld.js"
}];

class DefaultExtension extends MProvider {
    async getPopular(page) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(`${baseUrl}/beliebte-animes`);
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
        const res = await new Client().get(`${baseUrl}/neu`);
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
        const res = await new Client().get(`${baseUrl}/animes`);
        const elements = new Document(res.body).select("#seriesContainer > div > ul > li > a").filter(e => e.attr("title").toLowerCase().includes(query.toLowerCase()));
        const list = [];
        for (const element of elements) {
            const name = element.text;
            const link = element.attr("href");
            const img = new Document((await new Client().get(baseUrl + link)).body).selectFirst("div.seriesCoverBox img").attr("data-src");
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
        const res = await new Client().get(baseUrl + url);
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
        let episodes = [];
        for (const element of seasonsElements) {
            const eps = await this.parseEpisodesFromSeries(element);
            for (const ep of eps) {
                episodes.push(ep);
            }
        }
        episodes.reverse();

        return {
            name, imageUrl, description, author, status: 5, genre, episodes
        };
    }
    async parseEpisodesFromSeries(element) {
        const seasonId = element.getHref;
        const res = await new Client().get(this.source.baseUrl + seasonId);
        const episodeElements = new Document(res.body).select("table.seasonEpisodesList tbody tr");
        const list = [];
        for (const episodeElement of episodeElements) {
            list.push(this.episodeFromElement(episodeElement));
        }
        return list;
    }
    episodeFromElement(element) {
        let name = "";
        let url = "";
        if (element.selectFirst("td.seasonEpisodeTitle a").attr("href").includes("/film")) {
            const num = element.attr("data-episode-season-id");
            name = `Film ${num}` + " : " + element.selectFirst("td.seasonEpisodeTitle a span").text;
            url = element.selectFirst("td.seasonEpisodeTitle a").attr("href");
        } else {
            const season =
                element.selectFirst("td.seasonEpisodeTitle a").attr("href").substringAfter("staffel-").substringBefore("/episode");;
            const num = element.attr("data-episode-season-id");
            name = `Staffel ${season} Folge ${num}` + " : " + element.selectFirst("td.seasonEpisodeTitle a span").text;
            url = element.selectFirst("td.seasonEpisodeTitle a").attr("href");
        }
        if (name.length > 0 && url.length > 0) {
            return { name, url }
        }
        return {}
    }
    async getVideoList(url) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(baseUrl + url);
        const document = new Document(res.body);
        const redirectlink = document.select("ul.row li");
        const preference = new SharedPreferences();
        const hosterSelection = preference.get("hoster_selection");
        const videos = [];
        for (const element of redirectlink) {
            const langkey = element.attr("data-lang-key");
            let language = "";
            if (langkey.includes("3")) {
                language = "Deutscher Sub";
            } else if (langkey.includes("1")) {
                language = "Deutscher Dub";
            } else if (langkey.includes("2")) {
                language = "Englischer Sub";
            }
            const redirectgs = baseUrl + element.selectFirst("a.watchEpisode").attr("href");
            const hoster = element.selectFirst("a h4").text;
            if (hoster == "Streamtape" && hosterSelection.includes("Streamtape")) {
                const body = (await new Client().get(redirectgs)).body;
                const quality = `Streamtape ${language}`;
                const vids = await streamTapeExtractor(body.match(/https:\/\/streamtape\.com\/e\/[a-zA-Z0-9]+/g)[0], quality);
                for (const vid of vids) {
                    videos.push(vid);
                }
            } else if (hoster == "VOE" && hosterSelection.includes("VOE")) {
                const body = (await new Client().get(redirectgs)).body;
                const quality = `VOE ${language}`;
                const vids = await voeExtractor(body.match(/https:\/\/voe\.sx\/e\/[a-zA-Z0-9]+/g)[0], quality);
                for (const vid of vids) {
                    videos.push(vid);
                }
            } else if (hoster == "Vidoza" && hosterSelection.includes("Vidoza")) {
                const body = (await new Client().get(redirectgs)).body;
                const quality = `Vidoza ${language}`;
                const match = body.match(/https:\/\/[^\s]*\.vidoza\.net\/[^\s]*\.mp4/g);
                if (match.length > 0) {
                    videos.push({ url: match[0], originalUrl: match[0], quality });
                }
            }
        }
        return this.sortVideos(videos);
    }
    sortVideos(videos) {
        const preference = new SharedPreferences();
        const hoster = preference.get("preferred_hoster");
        const subPreference = preference.get("preferred_lang");
        videos.sort((a, b) => {
            let qualityMatchA = 0;
            if (a.quality.includes(hoster) &&
                a.quality.includes(subPreference)) {
                qualityMatchA = 1;
            }
            let qualityMatchB = 0;
            if (b.quality.includes(hoster) &&
                b.quality.includes(subPreference)) {
                qualityMatchB = 1;
            }
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
                "key": "preferred_hoster",
                "listPreference": {
                    "title": "Standard-Hoster",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": [
                        "Streamtape",
                        "VOE",
                        "Vidoza"
                    ],
                    "entryValues": [
                        "Streamtape",
                        "VOE",
                        "Vidoza"
                    ]
                }
            },
            {
                "key": "hoster_selection",
                "multiSelectListPreference": {
                    "title": "Hoster auswählen",
                    "summary": "",
                    "entries": [
                        "Streamtape",
                        "VOE",
                        "Vidoza"
                    ],
                    "entryValues": [
                        "Streamtape",
                        "VOE",
                        "Vidoza"
                    ],
                    "values": [
                        "Streamtape",
                        "VOE",
                        "Vidoza"
                    ]
                }
            }
        ];
    }
}

const mangayomiSources = [{
    "name": "AnimeFLV",
    "lang": "es",
    "baseUrl": "https://www3.animeflv.net",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/es.animeflv.png",
    "typeSource": "single",
    "isManga": false,
    "isNsfw": false,
    "version": "0.0.2",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": ""
}];

class DefaultExtension extends MProvider {
    async getPopular(page) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(`${baseUrl}/browse?order=rating&page=${page}`);

        return this.animeFromElement(res.body);
    }
    async getLatestUpdates(page) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(`${baseUrl}/browse?order=added&page=${page}`);

        return this.animeFromElement(res.body);
    }
    async search(query, page, filters) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(`${baseUrl}/browse?&q=${query}&page=${page}`);

        return this.animeFromElement(res.body);
    }
    async getDetail(url) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(baseUrl + url);
        const document = new Document(res.body);
        const genre = document.select("nav.Nvgnrs a").map(e => e.text);
        const description = document.selectFirst("div.Description").text.trim();
        const status = this.parseStatus(document.selectFirst("span.fa-tv").text);
        const episodeList = [];

        for (const script of document.select("script")) {
            if (script.text.includes("var anime_info =")) {
                const animeInfo = script.text.substringAfter("var anime_info = [").substringBefore("];");
                const arrInfo = JSON.parse(`[${animeInfo}]`);
                const animeUri = arrInfo[2].replace(/"/g, "");
                const episodes = script.text.substringAfter("var episodes = [").substringBefore("];").trim();
                const arrEpisodes = episodes.split("],[");
                for (const arrEp of arrEpisodes) {
                    const noEpisode = arrEp.replace("[", "").replace("]", "").split(",")[0];
                    const url = `${baseUrl}/ver/${animeUri}-${noEpisode}`;
                    const name = `Episodio ${noEpisode}`;
                    episodeList.push({ name, url });
                }

            }
        }

        return {
            description, status: status, genre, episodes: episodeList
        };
    }

    async getVideoList(url) {
        const res = await new Client().get(url);
        const document = new Document(res.body);
        const script = document.selectFirst("script:contains('var videos = {')");
        if (!script) return [];
        const jsonString = script.text;
        const responseString = jsonString.substringAfter("var videos =").substringBefore(";").trim();
        const serverModel = JSON.parse(responseString);
        const videos = [];

        for (const item of serverModel.SUB) {
            let videoList = [];
            switch (item.title) {
                case "Stape":
                    videoList = await streamTapeExtractor(item.url || item.code);
                    break;
                case "Okru":
                    videoList = await okruExtractor(item.url || item.code);
                    break;
                case "YourUpload":
                    videoList = await yourUploadExtractor(item.url || item.code);
                    break;
                case "SW":
                    videoList = await streamWishExtractor(item.url || item.code, "StreamWish:");
                    break;
                default:
                    videoList = [];
            }
            videos.push(...videoList);
        }

        return this.sortVideos(videos);
    }
    sortVideos(videos) {
        const preferences = new SharedPreferences();
        const server = preferences.get("preferred_server");
        const quality = preferences.get("preferred_quality");
        videos.sort((a, b) => {
            let qualityMatchA = 0;
            if (a.quality.includes(server) &&
                a.quality.includes(quality)) {
                qualityMatchA = 1;
            }
            let qualityMatchB = 0;
            if (b.quality.includes(server) &&
                b.quality.includes(quality)) {
                qualityMatchB = 1;
            }
            return qualityMatchB - qualityMatchA;
        });
        return videos;
    }
    animeFromElement(body) {
        const elements = new Document(body).select("div.Container ul.ListAnimes li article");
        const list = [];

        for (const element of elements) {
            const name = element.selectFirst("a h3").text;
            const thumbnailUrl = element.selectFirst("a div.Image figure img").attr("src");
            const imageUrl = thumbnailUrl ? thumbnailUrl : element.selectFirst("a div.Image figure img").attr("data-cfsrc");
            const link = element.selectFirst("div.Description a.Button").attr("href");
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: new Document(body).select("div.Container ul.ListAnimes li article").length > 0
        }
    }

    parseStatus(statusString) {
        if (statusString.includes("En emision")) {
            return 0;
        } else if (statusString.includes("Finalizado")) {
            return 1;
        } else {
            return 5;
        }
    }

    getSourcePreferences() {
        return [

            {
                "key": "preferred_quality",
                "listPreference": {
                    "title": "Preferred quality",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": [
                        "1080p",
                        "720p",
                        "480p",
                        "360p",
                    ],
                    "entryValues": [
                        "1080",
                        "720",
                        "480",
                        "360",
                    ]
                }
            },
            {
                "key": "preferred_server",
                "listPreference": {
                    "title": "Preferred server",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": ["StreamWish", "YourUpload", "Okru", "Streamtape"],
                    "entryValues": ["StreamWish", "YourUpload", "Okru", "Streamtape"]
                }
            }
        ];
    }

}

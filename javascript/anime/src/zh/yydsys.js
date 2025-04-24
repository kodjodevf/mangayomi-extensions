const mangayomiSources = [{
    "name": "多多影音",
    "lang": "zh",
    "baseUrl": "https://tv.yydsys.top",
    "apiUrl": "",
    "iconUrl": "https://tv.yydsys.top/template/DYXS2/static/picture/logo.png",
    "typeSource": "single",
    "itemType": 1,
    "isNsfw": false,
    "version": "0.0.3",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/zh/yydsys.js"
}];
class DefaultExtension extends MProvider {
    patternQuark = /(https:\/\/pan\.quark\.cn\/s\/[^"]+)/;
    patternUc = /(https:\/\/drive\.uc\.cn\/s\/[^"]+)/;
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }
    async getPopular(page) {
        const baseUrl = new SharedPreferences().get("url");
        const response = await new Client({ 'useDartHttpClient': true }).get(baseUrl, { "Referer": baseUrl });
        const elements = new Document(response.body).select("div.module-item");
        const list = [];
        for (const element of elements) {
            let oneA = element.selectFirst('.module-item-cover .module-item-pic a');
            const name = oneA.attr("title");
            const imageUrl = element.selectFirst(".module-item-cover .module-item-pic img").attr("data-src");
            const link = oneA.attr("href");
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    async getLatestUpdates(page) {
        const baseUrl = new SharedPreferences().get("url");
        const response = await new Client({ 'useDartHttpClient': true }).get(baseUrl + `/index.php/vod/show/id/1/page/${page}.html`, { "Referer": baseUrl });
        const elements = new Document(response.body).select("div.module-item");
        const list = [];
        for (const element of elements) {
            let oneA = element.selectFirst('.module-item-cover .module-item-pic a');
            const name = oneA.attr("title");
            const imageUrl = element.selectFirst(".module-item-cover .module-item-pic img").attr("data-src");
            const link = oneA.attr("href");
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: true
        }
    }
    async search(query, page, filters) {
        const baseUrl = new SharedPreferences().get("url");
        if (query == "") {
            var categories;
            for (const filter of filters) {
                if (filter["type"] == "categories") {
                    categories = filter["values"][filter["state"]]["value"];
                }
            }
            const response = await new Client({ 'useDartHttpClient': true }).get(baseUrl + `/index.php/vod/show/id/${categories}/page/${page}.html`, { "Referer": baseUrl });
            const elements = new Document(response.body).select("div.module-item");
            const list = [];
            for (const element of elements) {
                let oneA = element.selectFirst('.module-item-cover .module-item-pic a');
                const name = oneA.attr("title");
                const imageUrl = element.selectFirst(".module-item-cover .module-item-pic img").attr("data-src");
                const link = oneA.attr("href");
                list.push({ name, imageUrl, link });
            }
            return {
                list: list,
                hasNextPage: true
            }
        } else {
            const response = await new Client({ 'useDartHttpClient': true }).get(baseUrl + `/index.php/vod/search/page/${page}/wd/${query}.html`, { "Referer": baseUrl });
            const elements = new Document(response.body).select(".module-search-item");
            const list = [];
            for (const element of elements) {
                let oneA = element.selectFirst('.video-info .video-info-header a');
                const name = oneA.attr("title");
                const imageUrl = element.selectFirst(".video-cover .module-item-cover .module-item-pic img").attr("data-src");
                const link = oneA.attr("href");
                list.push({ name, imageUrl, link });
            }
            return {
                list: list,
                hasNextPage: true
            }
        }
    }
    async getDetail(url) {
        const baseUrl = new SharedPreferences().get("url");
        const response = await new Client({ 'useDartHttpClient': true }).get(baseUrl + url, { "Referer": baseUrl });
        const document = new Document(response.body);
        const imageUrl = document.selectFirst("div.video-cover .module-item-cover .module-item-pic img").attr("data-src");
        const name = document.selectFirst("div.video-info .video-info-header h1").text;
        const description = document.selectFirst("div.video-info .video-info-content").text.replace("[收起部分]", "").replace("[展开全部]", "");
        const type_name = "电影";
        let quark_share_url_list = [], uc_share_url_list = []
        const share_url_list = document.select("div.module-row-one .module-row-info")
            .map(e => {
                const url = e.selectFirst(".module-row-title p").text;
                const quarkMatches = url.match(this.patternQuark);

                if (quarkMatches && quarkMatches[1]) {
                    quark_share_url_list.push(quarkMatches[1]);
                }
                const ucMatches = url.match(this.patternUc);
                if (ucMatches && ucMatches[1]) {
                    uc_share_url_list.push(ucMatches[1]);
                }
                return null;
            })
            .filter(url => url !== null);
        let quark_episodes = await quarkFilesExtractor(quark_share_url_list, new SharedPreferences().get("quarkCookie"));
        let uc_episodes = await ucFilesExtractor(uc_share_url_list, new SharedPreferences().get("ucCookie"));
        let episodes = [...quark_episodes, ...uc_episodes];
        return {
            name, imageUrl, description, episodes
        };
    }
    // For anime episode video list
    async getVideoList(url) {
        const videos = [];
        const parts = url.split('++');
        const type = parts[0].toLowerCase();

        let vids;
        if (type === 'quark') {
            let cookie = new SharedPreferences().get("quarkCookie");
            if (cookie == "") {
                throw new Error("请先在本扩展设置中填写夸克Cookies, 需要夸克VIP账号 \n Please fill in the Quark Cookies in this extension settings first, you need a Quark VIP account");
            } else {
                vids = await quarkVideosExtractor(url, cookie);
            }
        } else if (type === 'uc') {
            let cookie = new SharedPreferences().get("ucCookie");
            if (cookie == "") {
                throw new Error("请先在本扩展设置中填写UC云盘Cookies \n Please fill in the UC Cloud Cookies in this extension settings first");
            } else {
                vids = await ucVideosExtractor(url, cookie);
            }
        } else {
            throw new Error("不支持的链接类型");
        }

        for (const vid of vids) {
            videos.push(vid);
        }
        return videos;
    }
    getFilterList() {
        return [{
            type: "categories",
            name: "影片類型",
            type_name: "SelectFilter",
            values: [
                { type_name: "SelectOption", value: "1", name: "电影" },
                { type_name: "SelectOption", value: "2", name: "剧集" },
                { type_name: "SelectOption", value: "4", name: "动漫" },
                { type_name: "SelectOption", value: "3", name: "综艺" },
                { type_name: "SelectOption", value: "5", name: "短剧" },
                { type_name: "SelectOption", value: "20", name: "纪录片" }
            ]
        }];
    }
    getSourcePreferences() {
        return [
            {
                "key": "quarkCookie",
                "editTextPreference": {
                    "title": "夸克Cookies",
                    "summary": "填写获取到的夸克Cookies",
                    "value": "",
                    "dialogTitle": "Cookies",
                    "dialogMessage": "",
                }
            },
            {
                "key": "ucCookie",
                "editTextPreference": {
                    "title": "UC云盘Cookies",
                    "summary": "填写获取到的UC云盘Cookies",
                    "value": "",
                    "dialogTitle": "Cookies",
                    "dialogMessage": "",
                }
            },
            {
                "key": "url",
                "listPreference": {
                    "title": "Website Url",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": [
                        "https://tv.yydsys.top",
                        "https://tv.yydsys.cc",
                        "https://tv.214521.xyz"
                    ],
                    "entryValues": [
                        "https://tv.yydsys.top",
                        "https://tv.yydsys.cc",
                        "https://tv.214521.xyz"
                    ],
                }
            }
        ];
    }
}

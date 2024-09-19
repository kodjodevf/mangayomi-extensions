const mangayomiSources = [{
    "name": "奥斯卡资源站",
    "lang": "zh",
    "baseUrl": "https://aosikazy1.com",
    "apiUrl": "",
    "iconUrl": "https://aosikazy1.com/template/m1938pc3/image/favicon.ico",
    "typeSource": "single",
    "isManga": false,
    "isNsfw": true,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/zh/aosikazy.js"
}];

class DefaultExtension extends MProvider {
    dict = new Map([
        ["&nbsp;", " "],
        ["&quot;", '"'],
        ["&lt;", "<"],
        ["&gt;", ">"],
        ["&amp;", "&"],
        ["&sdot;", "·"],
    ]);
    text(content) {
        if (!content) return "";
        const str =
            [...content.matchAll(/>([^<]+?)</g)]
                .map((m) => m[1])
                .join("")
                .trim() || content;
        return str.replace(/&[a-z]+;/g, (c) => this.dict.get(c) || c);
    }
    async request(url) {
        const preference = new SharedPreferences();
        return (await new Client({ 'useDartHttpClient': true }).get(preference.get("url") + "/api.php/provide/vod?ac=detail" + url, { "Referer": preference.get("url") })).body;
    }
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }
    async getPopular(page) {
        // let genres = [];
        // const gen = JSON.parse(await this.request("&ac=list"));
        // gen.class.forEach((e) => {
        //     genres.push({
        //         type_name: "SelectOption",
        //         value: e.type_id,
        //         name: e.type_name
        //     });
        // });
        // console.log(genres)
        const res = JSON.parse(await this.request(`&pg=${page}`));
        return {
            list: res.list.map((e) => ({
                link: "&ids=" + e.vod_id,
                imageUrl: e.vod_pic,
                name: e.vod_name
            })),
            hasNextPage: true
        };
    }
    async getLatestUpdates(page) {
        const h = (new Date().getUTCHours() + 9) % 24;
        const res = JSON.parse(await this.request(`&pg=${page}&h=${h || 24}`));
        return {
            list: res.list.map((e) => ({
                link: "&ids=" + e.vod_id,
                imageUrl: e.vod_pic,
                name: e.vod_name
            })),
            hasNextPage: true
        };
    }
    async search(query, page, filters) {
        var categories;
        for (const filter of filters) {
            if (filter["type"] == "categories") {
                categories = filter["values"][filter["state"]]["value"];
            }
        }
        const res = JSON.parse(await this.request(`&wd=${query}&t=${categories ?? ""}&pg=${page}`));
        return {
            list: res.list.map((e) => ({
                link: "&ids=" + e.vod_id,
                imageUrl: e.vod_pic,
                name: e.vod_name
            })),
            hasNextPage: true
        };
    }
    async getDetail(url) {
        let desc = "无";
        const anime = JSON.parse(await this.request(url)).list[0];
        const blurb = this.text(anime.vod_blurb);
        const content = this.text(anime.vod_content);
        desc = desc.length < blurb?.length ? blurb : desc;
        desc = desc.length < content.length ? content : desc;
        const urls = anime.vod_play_url
            .split("#")
            .filter((e) => e)
            .map((e) => {
                const s = e.split("$");
                return { name: s[0], url: s[1] };
            });
        return {
            name: anime.vod_name,
            imageUrl: anime.vod_pic,
            description: desc,
            episodes: urls
        };
    }
    // For anime episode video list
    async getVideoList(url) {
        return [{
            url: url,
            originalUrl: url,
            quality: "HLS"
        }];
    }
    // For manga chapter pages
    async getPageList() {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        return [{
            type: "categories",
            name: "影片類型",
            type_name: "SelectFilter",
            values: [
                // { type_name: "SelectOption", value: "1", name: "电影" },
                // { type_name: "SelectOption", value: "2", name: "连续剧" },
                // { type_name: "SelectOption", value: "3", name: "综艺" },
                { type_name: "SelectOption", value: "", name: "全部" },
                { type_name: "SelectOption", value: "20", name: "国产视频" },
                { type_name: "SelectOption", value: "21", name: "中文字幕" },
                { type_name: "SelectOption", value: "22", name: "国产传媒" },
                { type_name: "SelectOption", value: "23", name: "日本有码" },
                { type_name: "SelectOption", value: "24", name: "日本无码" },
                { type_name: "SelectOption", value: "25", name: "欧美无码" },
                { type_name: "SelectOption", value: "26", name: "强奸乱伦" },
                { type_name: "SelectOption", value: "27", name: "制服诱惑" },
                { type_name: "SelectOption", value: "28", name: "国产主播" },
                { type_name: "SelectOption", value: "29", name: "激情动漫" },
                { type_name: "SelectOption", value: "30", name: "明星换脸" },
                { type_name: "SelectOption", value: "31", name: "抖阴视频" },
                { type_name: "SelectOption", value: "32", name: "女优明星" },
                { type_name: "SelectOption", value: "33", name: "视频一区" },
                { type_name: "SelectOption", value: "34", name: "视频二区" },
                { type_name: "SelectOption", value: "35", name: "网曝黑料" },
                { type_name: "SelectOption", value: "36", name: "视频三区" },
                { type_name: "SelectOption", value: "37", name: "伦理三级" },
                { type_name: "SelectOption", value: "38", name: "AV解说" },
                { type_name: "SelectOption", value: "39", name: "SM调教" },
                { type_name: "SelectOption", value: "40", name: "萝莉少女" },
                { type_name: "SelectOption", value: "41", name: "极品媚黑" },
                { type_name: "SelectOption", value: "42", name: "女同性恋" },
                { type_name: "SelectOption", value: "43", name: "网红头条" },
                { type_name: "SelectOption", value: "44", name: "视频四区" },
                { type_name: "SelectOption", value: "45", name: "人妖系列" },
                { type_name: "SelectOption", value: "46", name: "韩国主播" },
                { type_name: "SelectOption", value: "47", name: "VR视角" }
            ]
        }];
    }
    getSourcePreferences() {
        return [
            {
                "key": "url",
                "listPreference": {
                    "title": "Website Url",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": ["aosikazy1", "aosikazy2", "aosikazy3", "aosikazy4", "aosikazy5", "aosikazy6", "aosikazy7", "aosikazy8", "aosikazy9", "aosikazy10"],
                    "entryValues": ["https://aosikazy1.com", "https://aosikazy2.com", "https://aosikazy3.com", "https://aosikazy4.com", "https://aosikazy5.com", "https://aosikazy6.com", "https://aosikazy7.com", "https://aosikazy8.com", "https://aosikazy9.com", "https://aosikazy10.com"],
                }
            }
        ];
    }
}

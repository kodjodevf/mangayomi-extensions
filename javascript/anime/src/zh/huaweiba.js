const mangayomiSources = [{
    "name": "华为吧资源",
    "lang": "zh",
    "baseUrl": "https://huaweiba.live",
    "apiUrl": "",
    "iconUrl": "https://huaweiba.live/template/ziyuan/images/logo2.png",
    "typeSource": "single",
    "isManga": false,
    "isNsfw": false,
    "version": "0.0.2",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/zh/huaweiba.js"
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
        return (await new Client({ 'useDartHttpClient': true }).get(this.source.baseUrl + "/api.php/provide/vod?ac=detail" + url, { "Referer": this.source.baseUrl })).body;
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
        const proxyUrl = await getProxyUrl();
        return [
            {
                url: url,
                originalUrl: url,
                quality: "HLS"
            },
            {
                url: `${proxyUrl}/proxy?url=${encodeURIComponent(url)}`,
                originalUrl: url,
                quality: "去广告"
            }
        ];
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
                { type_name: "SelectOption", value: "", name: "全部" },
                { type_name: "SelectOption", value: "20", name: "电影" },
                { type_name: "SelectOption", value: "22", name: "冒险片" },
                { type_name: "SelectOption", value: "24", name: "剧情片" },
                { type_name: "SelectOption", value: "26", name: "动作片" },
                { type_name: "SelectOption", value: "28", name: "动画电影" },
                { type_name: "SelectOption", value: "30", name: "同性片" },
                { type_name: "SelectOption", value: "32", name: "喜剧片" },
                { type_name: "SelectOption", value: "34", name: "奇幻片" },
                { type_name: "SelectOption", value: "36", name: "恐怖片" },
                { type_name: "SelectOption", value: "38", name: "悬疑片" },
                { type_name: "SelectOption", value: "40", name: "惊悚片" },
                { type_name: "SelectOption", value: "42", name: "歌舞片" },
                { type_name: "SelectOption", value: "44", name: "灾难片" },
                { type_name: "SelectOption", value: "46", name: "爱情片" },
                { type_name: "SelectOption", value: "48", name: "科幻片" },
                { type_name: "SelectOption", value: "50", name: "犯罪片" },
                { type_name: "SelectOption", value: "52", name: "经典片" },
                { type_name: "SelectOption", value: "54", name: "网络电影" },
                { type_name: "SelectOption", value: "56", name: "战争片" },
                { type_name: "SelectOption", value: "58", name: "伦理片" },
                { type_name: "SelectOption", value: "60", name: "电视剧" },
                { type_name: "SelectOption", value: "62", name: "欧美剧" },
                { type_name: "SelectOption", value: "64", name: "日剧" },
                { type_name: "SelectOption", value: "66", name: "韩剧" },
                { type_name: "SelectOption", value: "68", name: "台剧" },
                { type_name: "SelectOption", value: "70", name: "泰剧" },
                { type_name: "SelectOption", value: "72", name: "国产剧" },
                { type_name: "SelectOption", value: "74", name: "港剧" },
                { type_name: "SelectOption", value: "76", name: "新马剧" },
                { type_name: "SelectOption", value: "78", name: "其他剧" },
                { type_name: "SelectOption", value: "80", name: "动漫" },
                { type_name: "SelectOption", value: "82", name: "综艺" },
                { type_name: "SelectOption", value: "84", name: "体育" },
                { type_name: "SelectOption", value: "86", name: "纪录片" },
                { type_name: "SelectOption", value: "88", name: "篮球" },
                { type_name: "SelectOption", value: "90", name: "足球" },
                { type_name: "SelectOption", value: "92", name: "网球" },
                { type_name: "SelectOption", value: "94", name: "斯诺克" },
                { type_name: "SelectOption", value: "96", name: "欧美动漫" },
                { type_name: "SelectOption", value: "98", name: "日韩动漫" },
                { type_name: "SelectOption", value: "100", name: "国产动漫" },
                { type_name: "SelectOption", value: "102", name: "新马泰动漫" },
                { type_name: "SelectOption", value: "104", name: "港台动漫" },
                { type_name: "SelectOption", value: "106", name: "其他动漫" },
                { type_name: "SelectOption", value: "108", name: "国产综艺" },
                { type_name: "SelectOption", value: "110", name: "日韩综艺" },
                { type_name: "SelectOption", value: "112", name: "欧美综艺" },
                { type_name: "SelectOption", value: "114", name: "新马泰综艺" },
                { type_name: "SelectOption", value: "116", name: "港台综艺" },
                { type_name: "SelectOption", value: "118", name: "其他综艺" },
                { type_name: "SelectOption", value: "120", name: "短剧" },
                { type_name: "SelectOption", value: "122", name: "预告片" }
            ]
        }];
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

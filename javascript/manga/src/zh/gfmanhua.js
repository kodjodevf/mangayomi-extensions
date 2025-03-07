const mangayomiSources = [{
    "name": "古风漫画",
    "lang": "zh",
    "baseUrl": "https://www.gufengmh.com",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/zh.gfmanhua.png",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.1",
    "pkgPath": "manga/src/zh/gfmanhua.js"
}];

class DefaultExtension extends MProvider {
    stringUTF8(text) {
        var bytes = [];
        for (var i = 0; i < text.length; i++) {
            bytes.push(text.charCodeAt(i));
        }
        var charCodes = [];
        var i = 0;
        while (i < bytes.length) {
            var byte1 = bytes[i];
            var charCode;

            if (byte1 < 0x80) {
                charCode = byte1;
                i += 1;
            } else if (byte1 < 0xE0) {
                var byte2 = bytes[i + 1];
                charCode = ((byte1 & 0x1F) << 6) | (byte2 & 0x3F);
                i += 2;
            } else if (byte1 < 0xF0) {
                var byte2 = bytes[i + 1];
                var byte3 = bytes[i + 2];
                charCode = ((byte1 & 0x0F) << 12) | ((byte2 & 0x3F) << 6) | (byte3 & 0x3F);
                i += 3;
            } else {
                var byte2 = bytes[i + 1];
                var byte3 = bytes[i + 2];
                var byte4 = bytes[i + 3];
                charCode = ((byte1 & 0x07) << 18) | ((byte2 & 0x3F) << 12) | ((byte3 & 0x3F) << 6) | (byte4 & 0x3F);
                i += 4;
            }

            charCodes.push(charCode);
        }
        return String.fromCharCode.apply(null, charCodes);
    }
    baseURL() {
        const preference = new SharedPreferences();
        var base_url = preference.get("domain_url");
        if (base_url.endsWith("/")) {
            base_url = base_url.slice(0, -1);
        }
        return base_url;
    }
    async request(url) {
        const base_url = this.baseURL();
        return await new Client().get(base_url + url, {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
        });
    }
    async getItems(url, trans_str, tag_class) {
        const res = await this.request(url);
        const doc = new Document(res.body);
        const elements = doc.select("li." + tag_class);
        const manga = [];
        for (let element of elements) {
            const info = element.selectFirst("a");
            let title = info.attr("title");
            if (trans_str) {
                title = this.stringUTF8(title);
            }
            manga.push({
                name: title,
                link: info.attr("href").replace(this.baseURL(), ""),
                imageUrl: element.selectFirst("img").attr("src")
            })
        }
        return {
            list: manga,
            hasNextPage: true
        };
    }
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }
    async getPopular(page) {
        const results = await this.getItems("/rank/", false, "item-sm");
        results.hasNextPage = false;
        return results;
    }
    async getLatestUpdates(page) {
        return await this.getItems(`/update/${page}/`, true, "item-lg");
    }
    async search(query, page, filters) {
        let url = null;
        if (query != "") {
            url = `/search/?keywords=${query}&page=${page}`;
        } else {
            let querys = [filters[0]["values"][filters[0]["state"]]["value"],
            filters[1]["values"][filters[1]["state"]]["value"],
            filters[2]["values"][filters[2]["state"]]["value"],
            filters[3]["values"][filters[3]["state"]]["value"]];
            querys = querys.filter(item => item !== "");
            url = querys.join("-");
            if (url.length > 0) {
                url = "/" + url;
            }
            url = `/list${url}/${page}/`;
        }
        return await this.getItems(url, false, "item-lg");
    }
    async getDetail(url) {
        const res = await this.request(url);
        const doc = new Document(res.body);
        const cover = doc.selectFirst("img.pic").attr("src");
        const title = doc.selectFirst("div.book-title h1 span").text;
        const infos = doc.select("ul.detail-list span");
        let status = 0;
        if (this.stringUTF8(infos[0].selectFirst("a").text.search("连载中")) == -1) {
            status = 1;
        }
        const genre = [this.stringUTF8(infos[2].selectFirst("a").text)];
        const author = infos[3].selectFirst("a").text;
        const description = doc.selectFirst("div#intro-cut p").text;
        const chapters = [];
        const elements = doc.select("ul#chapter-list-1 li");
        for (let element of elements) {
            chapters.push({
                name: this.stringUTF8(element.selectFirst("span").text),
                url: element.selectFirst("a").attr("href")
            })
        }
        chapters.reverse();
        return {
            name: this.stringUTF8(title),
            imageUrl: cover,
            description: this.stringUTF8(description),
            genre: genre,
            author: this.stringUTF8(author),
            status: status,
            chapters: chapters,
        };
    }
    async getPageList(url) {
        const res = await this.request(url);
        const doc = new Document(res.body);
        const script = doc.select("script")[2].text;
        const chapterImagesMatch = script.match(/var chapterImages = (\[.*?\]);/);
        const chapterImages = chapterImagesMatch ? JSON.parse(chapterImagesMatch[1]) : [];
        const pageImageMatch = script.match(/var chapterPath = "(.*?)";/);
        const pageImage = pageImageMatch ? pageImageMatch[1] : "";
        for (let i = 0; i < chapterImages.length; i++) {
            chapterImages[i] = "https://res.xiaoqinre.com/" + pageImage + chapterImages[i];
        }
        return chapterImages;
    }
    getFilterList() {
        return [
            {
                type: "category",
                name: "类型",
                type_name: "SelectFilter",
                values: [{
                    type_name: "SelectOption",
                    name: "全部",
                    value: ""
                },
                {
                    type_name: "SelectOption",
                    name: "少年漫画",
                    value: "shaonian"
                },
                {
                    type_name: "SelectOption",
                    name: "少女漫画",
                    value: "shaonv"
                },
                {
                    type_name: "SelectOption",
                    name: "青年漫画",
                    value: "qingnian"
                },
                {
                    type_name: "SelectOption",
                    name: "真人漫画",
                    value: "zhenrenmanhua"
                },
                ],
            },
            {
                type: "region",
                name: "地区",
                type_name: "SelectFilter",
                values: [{
                    type_name: "SelectOption",
                    name: "全部",
                    value: ""
                },
                {
                    type_name: "SelectOption",
                    name: "日本漫画",
                    value: "ribenmanhua"
                },
                {
                    type_name: "SelectOption",
                    name: "国产漫画",
                    value: "guochanmanhua"
                },
                {
                    type_name: "SelectOption",
                    name: "港台漫画",
                    value: "gangtaimanhua"
                },
                {
                    type_name: "SelectOption",
                    name: "欧美漫画",
                    value: "oumeimanhua"
                },
                {
                    type_name: "SelectOption",
                    name: "韩国漫画",
                    value: "hanguomanhua"
                },
                ],
            },
            {
                type: "type",
                name: "剧情",
                type_name: "SelectFilter",
                values: [{
                    type_name: "SelectOption",
                    name: "全部",
                    value: ""
                }, {
                    type_name: "SelectOption",
                    name: "冒险",
                    value: "maoxian"
                }, {
                    type_name: "SelectOption",
                    name: "魔法",
                    value: "mofa"
                }, {
                    type_name: "SelectOption",
                    name: "科幻",
                    value: "kehuan"
                }, {
                    type_name: "SelectOption",
                    name: "恐怖",
                    value: "kongbu"
                }, {
                    type_name: "SelectOption",
                    name: "历史",
                    value: "lishi"
                }, {
                    type_name: "SelectOption",
                    name: "竞技",
                    value: "jingji"
                }, {
                    type_name: "SelectOption",
                    name: "欢乐向",
                    value: "huanlexiang"
                }, {
                    type_name: "SelectOption",
                    name: "西方魔幻",
                    value: "xifangmohuan"
                }, {
                    type_name: "SelectOption",
                    name: "爱情",
                    value: "aiqing"
                }, {
                    type_name: "SelectOption",
                    name: "悬疑",
                    value: "xuanyi"
                }, {
                    type_name: "SelectOption",
                    name: "奇幻",
                    value: "qihuan"
                }, {
                    type_name: "SelectOption",
                    name: "轻小说",
                    value: "qingxiaoshuo"
                }, {
                    type_name: "SelectOption",
                    name: "四格",
                    value: "sige"
                }, {
                    type_name: "SelectOption",
                    name: "神鬼",
                    value: "shengui"
                }, {
                    type_name: "SelectOption",
                    name: "治愈",
                    value: "zhiyu"
                }, {
                    type_name: "SelectOption",
                    name: "校园",
                    value: "xiaoyuan"
                }, {
                    type_name: "SelectOption",
                    name: "伪娘",
                    value: "weiniang"
                }, {
                    type_name: "SelectOption",
                    name: "耽美",
                    value: "danmei"
                }, {
                    type_name: "SelectOption",
                    name: "后宫",
                    value: "hougong"
                }, {
                    type_name: "SelectOption",
                    name: "魔幻",
                    value: "mohuan"
                }, {
                    type_name: "SelectOption",
                    name: "武侠",
                    value: "wuxia"
                }, {
                    type_name: "SelectOption",
                    name: "职场",
                    value: "zhichang"
                }, {
                    type_name: "SelectOption",
                    name: "侦探",
                    value: "zhentan"
                }, {
                    type_name: "SelectOption",
                    name: "美食",
                    value: "meishi"
                }, {
                    type_name: "SelectOption",
                    name: "格斗",
                    value: "gedou"
                }, {
                    type_name: "SelectOption",
                    name: "励志",
                    value: "lizhi"
                }, {
                    type_name: "SelectOption",
                    name: "音乐舞蹈",
                    value: "yinyuewudao"
                }, {
                    type_name: "SelectOption",
                    name: "热血",
                    value: "rexue"
                }, {
                    type_name: "SelectOption",
                    name: "战争",
                    value: "zhanzheng"
                }, {
                    type_name: "SelectOption",
                    name: "搞笑",
                    value: "gaoxiao"
                }, {
                    type_name: "SelectOption",
                    name: "生活",
                    value: "shenghuo"
                }, {
                    type_name: "SelectOption",
                    name: "百合",
                    value: "baihe"
                }, {
                    type_name: "SelectOption",
                    name: "萌系",
                    value: "mengji"
                }, {
                    type_name: "SelectOption",
                    name: "节操",
                    value: "jiecao"
                }, {
                    type_name: "SelectOption",
                    name: "性转换",
                    value: "xingzhuanhuan"
                }, {
                    type_name: "SelectOption",
                    name: "颜艺",
                    value: "yanyi"
                }, {
                    type_name: "SelectOption",
                    name: "古风",
                    value: "gufeng"
                }, {
                    type_name: "SelectOption",
                    name: "仙侠",
                    value: "xianxia"
                }, {
                    type_name: "SelectOption",
                    name: "宅系",
                    value: "zhaiji"
                }, {
                    type_name: "SelectOption",
                    name: "剧情",
                    value: "juqing"
                }, {
                    type_name: "SelectOption",
                    name: "神魔",
                    value: "shenmo"
                }, {
                    type_name: "SelectOption",
                    name: "玄幻",
                    value: "xuanhuan"
                }, {
                    type_name: "SelectOption",
                    name: "穿越",
                    value: "chuanyue"
                }, {
                    type_name: "SelectOption",
                    name: "其他",
                    value: "qita"
                }, {
                    type_name: "SelectOption",
                    name: "幻想",
                    value: "huanxiang"
                }, {
                    type_name: "SelectOption",
                    name: "墨瞳",
                    value: "motong"
                }, {
                    type_name: "SelectOption",
                    name: "麦萌",
                    value: "maimeng"
                }, {
                    type_name: "SelectOption",
                    name: "漫漫",
                    value: "manman"
                }, {
                    type_name: "SelectOption",
                    name: "漫画岛",
                    value: "manhuadao"
                }, {
                    type_name: "SelectOption",
                    name: "推理",
                    value: "tuili"
                }, {
                    type_name: "SelectOption",
                    name: "东方",
                    value: "dongfang"
                }, {
                    type_name: "SelectOption",
                    name: "快看",
                    value: "kuaikan"
                }, {
                    type_name: "SelectOption",
                    name: "机战",
                    value: "jizhan"
                }, {
                    type_name: "SelectOption",
                    name: "高清单行",
                    value: "gaoqingdanxing"
                }, {
                    type_name: "SelectOption",
                    name: "新作",
                    value: "xinzuo"
                }, {
                    type_name: "SelectOption",
                    name: "投稿",
                    value: "tougao"
                }, {
                    type_name: "SelectOption",
                    name: "日常",
                    value: "richang"
                }, {
                    type_name: "SelectOption",
                    name: "手工",
                    value: "shougong"
                }, {
                    type_name: "SelectOption",
                    name: "运动",
                    value: "yundong"
                }, {
                    type_name: "SelectOption",
                    name: "唯美",
                    value: "weimei"
                }, {
                    type_name: "SelectOption",
                    name: "都市",
                    value: "dushi"
                }, {
                    type_name: "SelectOption",
                    name: "惊险",
                    value: "jingxian"
                }, {
                    type_name: "SelectOption",
                    name: "僵尸",
                    value: "jiangshi"
                }, {
                    type_name: "SelectOption",
                    name: "恋爱",
                    value: "lianai"
                }, {
                    type_name: "SelectOption",
                    name: "虐心",
                    value: "nuexin"
                }, {
                    type_name: "SelectOption",
                    name: "纯爱",
                    value: "chunai"
                }, {
                    type_name: "SelectOption",
                    name: "复仇",
                    value: "fuchou"
                }, {
                    type_name: "SelectOption",
                    name: "动作",
                    value: "dongzuo"
                }, {
                    type_name: "SelectOption",
                    name: "其它",
                    value: "qita2"
                }, {
                    type_name: "SelectOption",
                    name: "恶搞",
                    value: "egao"
                }, {
                    type_name: "SelectOption",
                    name: "明星",
                    value: "mingxing"
                }, {
                    type_name: "SelectOption",
                    name: "震撼",
                    value: "zhenhan"
                }, {
                    type_name: "SelectOption",
                    name: "暗黑",
                    value: "anhei"
                }, {
                    type_name: "SelectOption",
                    name: "脑洞",
                    value: "naodong"
                }, {
                    type_name: "SelectOption",
                    name: "血腥",
                    value: "xuexing"
                }, {
                    type_name: "SelectOption",
                    name: "有妖气",
                    value: "youyaoqi"
                }, {
                    type_name: "SelectOption",
                    name: "机甲",
                    value: "jijia"
                }, {
                    type_name: "SelectOption",
                    name: "青春",
                    value: "qingchun"
                }, {
                    type_name: "SelectOption",
                    name: "灵异",
                    value: "lingyi"
                }, {
                    type_name: "SelectOption",
                    name: "同人",
                    value: "tongren"
                }, {
                    type_name: "SelectOption",
                    name: "浪漫",
                    value: "langman"
                }, {
                    type_name: "SelectOption",
                    name: "权谋",
                    value: "quanmou"
                }, {
                    type_name: "SelectOption",
                    name: "社会",
                    value: "shehui"
                }, {
                    type_name: "SelectOption",
                    name: "宫斗",
                    value: "gongdou"
                }, {
                    type_name: "SelectOption",
                    name: "爆笑",
                    value: "baoxiao"
                }, {
                    type_name: "SelectOption",
                    name: "体育",
                    value: "tiyu"
                }, {
                    type_name: "SelectOption",
                    name: "栏目",
                    value: "lanmu"
                }, {
                    type_name: "SelectOption",
                    name: "彩虹",
                    value: "caihong"
                }, {
                    type_name: "SelectOption",
                    name: "侦探推理",
                    value: "zhentantuili"
                }, {
                    type_name: "SelectOption",
                    name: "少女爱情",
                    value: "shaonuaiqing"
                }, {
                    type_name: "SelectOption",
                    name: "搞笑喜剧",
                    value: "gaoxiaoxiju"
                }, {
                    type_name: "SelectOption",
                    name: "恐怖灵异",
                    value: "kongbulingyi"
                }, {
                    type_name: "SelectOption",
                    name: "科幻魔幻",
                    value: "kehuanmohuan"
                }, {
                    type_name: "SelectOption",
                    name: "竞技体育",
                    value: "jingjitiyu"
                }, {
                    type_name: "SelectOption",
                    name: "武侠格斗",
                    value: "wuxiagedou"
                }, {
                    type_name: "SelectOption",
                    name: "舰娘",
                    value: "jianniang"
                }, {
                    type_name: "SelectOption",
                    name: "耽美BL",
                    value: "danmeiBL"
                }, {
                    type_name: "SelectOption",
                    name: "邪恶",
                    value: "xiee"
                }, {
                    type_name: "SelectOption",
                    name: "综合其它",
                    value: "zongheqita"
                }, {
                    type_name: "SelectOption",
                    name: "青年",
                    value: "qingnian"
                }, {
                    type_name: "SelectOption",
                    name: "宅男",
                    value: "zhainan"
                }, {
                    type_name: "SelectOption",
                    name: "杂志",
                    value: "zazhi"
                }, {
                    type_name: "SelectOption",
                    name: "音乐",
                    value: "yinyue"
                }, {
                    type_name: "SelectOption",
                    name: "全彩",
                    value: "quancai"
                }, {
                    type_name: "SelectOption",
                    name: "黑道",
                    value: "heidao"
                }, {
                    type_name: "SelectOption",
                    name: "恋爱耽美",
                    value: "lianaidanmei"
                }, {
                    type_name: "SelectOption",
                    name: "热血冒险",
                    value: "rexuemaoxian"
                }, {
                    type_name: "SelectOption",
                    name: "腐女",
                    value: "funv"
                }, {
                    type_name: "SelectOption",
                    name: "故事",
                    value: "gushi"
                }, {
                    type_name: "SelectOption",
                    name: "少女",
                    value: "shaonv"
                }, {
                    type_name: "SelectOption",
                    name: "总裁",
                    value: "zongcai"
                }, {
                    type_name: "SelectOption",
                    name: "爆笑喜剧",
                    value: "baoxiaoxiju"
                }, {
                    type_name: "SelectOption",
                    name: "其他漫画",
                    value: "qitamanhua"
                }, {
                    type_name: "SelectOption",
                    name: "恋爱生活",
                    value: "lianaishenghuo"
                }, {
                    type_name: "SelectOption",
                    name: "恐怖悬疑",
                    value: "kongbuxuanyi"
                }, {
                    type_name: "SelectOption",
                    name: "耽美人生",
                    value: "danmeirensheng"
                }, {
                    type_name: "SelectOption",
                    name: "宠物",
                    value: "chongwu"
                }, {
                    type_name: "SelectOption",
                    name: "战斗",
                    value: "zhandou"
                }, {
                    type_name: "SelectOption",
                    name: "召唤兽",
                    value: "zhaohuanshou"
                }, {
                    type_name: "SelectOption",
                    name: "异能",
                    value: "yineng"
                }, {
                    type_name: "SelectOption",
                    name: "装逼",
                    value: "zhuangbi"
                }, {
                    type_name: "SelectOption",
                    name: "异世界",
                    value: "yishijie"
                }, {
                    type_name: "SelectOption",
                    name: "正剧",
                    value: "zhengju"
                }, {
                    type_name: "SelectOption",
                    name: "温馨",
                    value: "wenxin"
                }, {
                    type_name: "SelectOption",
                    name: "惊奇",
                    value: "jingqi"
                }, {
                    type_name: "SelectOption",
                    name: "架空",
                    value: "jiakong"
                }, {
                    type_name: "SelectOption",
                    name: "轻松",
                    value: "qingsong"
                }, {
                    type_name: "SelectOption",
                    name: "未来",
                    value: "weilai"
                }, {
                    type_name: "SelectOption",
                    name: "科技",
                    value: "keji"
                }, {
                    type_name: "SelectOption",
                    name: "烧脑",
                    value: "shaonao"
                }, {
                    type_name: "SelectOption",
                    name: "搞笑恶搞",
                    value: "gaoxiaoegao"
                }, {
                    type_name: "SelectOption",
                    name: "mhuaquan",
                    value: "mhuaquan"
                }, {
                    type_name: "SelectOption",
                    name: "少年",
                    value: "shaonian"
                }, {
                    type_name: "SelectOption",
                    name: "四格多格",
                    value: "sigeduoge"
                }, {
                    type_name: "SelectOption",
                    name: "霸总",
                    value: "bazong"
                }, {
                    type_name: "SelectOption",
                    name: "修真",
                    value: "xiuzhen"
                }, {
                    type_name: "SelectOption",
                    name: "故事漫画",
                    value: "gushimanhua"
                }, {
                    type_name: "SelectOption",
                    name: "绘本",
                    value: "huiben"
                }, {
                    type_name: "SelectOption",
                    name: "游戏",
                    value: "youxi"
                }, {
                    type_name: "SelectOption",
                    name: "真人",
                    value: "zhenren"
                }, {
                    type_name: "SelectOption",
                    name: "惊悚",
                    value: "jingsong"
                }, {
                    type_name: "SelectOption",
                    name: "漫画",
                    value: "manhua"
                }, {
                    type_name: "SelectOption",
                    name: "微众圈",
                    value: "weizhongquan"
                }, {
                    type_name: "SelectOption",
                    name: "御姐",
                    value: "yujie"
                }, {
                    type_name: "SelectOption",
                    name: "小说改编",
                    value: "xiaoshuogaibian"
                }, {
                    type_name: "SelectOption",
                    name: "萝莉",
                    value: "luoli"
                }, {
                    type_name: "SelectOption",
                    name: "1024manhua",
                    value: "1024manhua"
                }, {
                    type_name: "SelectOption",
                    name: "家庭",
                    value: "jiating"
                }, {
                    type_name: "SelectOption",
                    name: "神话",
                    value: "shenhua"
                }, {
                    type_name: "SelectOption",
                    name: "史诗",
                    value: "shishi"
                }, {
                    type_name: "SelectOption",
                    name: "末世",
                    value: "moshi"
                }, {
                    type_name: "SelectOption",
                    name: "娱乐圈",
                    value: "yulequan"
                }, {
                    type_name: "SelectOption",
                    name: "感动",
                    value: "gandong"
                }, {
                    type_name: "SelectOption",
                    name: "伦理",
                    value: "lunli"
                }, {
                    type_name: "SelectOption",
                    name: "杂志全本",
                    value: "zazhiquanben"
                }, {
                    type_name: "SelectOption",
                    name: "致郁",
                    value: "zhiyu2"
                }, {
                    type_name: "SelectOption",
                    name: "商战",
                    value: "shangzhan"
                }, {
                    type_name: "SelectOption",
                    name: "主仆",
                    value: "zhupu"
                }, {
                    type_name: "SelectOption",
                    name: "漫画圈",
                    value: "manhuaquan"
                }, {
                    type_name: "SelectOption",
                    name: "恋爱、剧情漫画",
                    value: "lianaijuqingmanhua"
                }, {
                    type_name: "SelectOption",
                    name: "婚爱",
                    value: "hunai"
                }, {
                    type_name: "SelectOption",
                    name: "豪门",
                    value: "haomen"
                }, {
                    type_name: "SelectOption",
                    name: "内涵",
                    value: "neihan"
                }, {
                    type_name: "SelectOption",
                    name: "性转",
                    value: "xingzhuan"
                }, {
                    type_name: "SelectOption",
                    name: "乡村",
                    value: "xiangcun"
                }, {
                    type_name: "SelectOption",
                    name: "宫廷",
                    value: "gongting"
                }, {
                    type_name: "SelectOption",
                    name: "段子",
                    value: "duanzi"
                }, {
                    type_name: "SelectOption",
                    name: "纯爱漫画",
                    value: "chunaimanhua"
                }, {
                    type_name: "SelectOption",
                    name: "逆袭",
                    value: "nixi"
                }, {
                    type_name: "SelectOption",
                    name: "婚姻",
                    value: "hunyin"
                }, {
                    type_name: "SelectOption",
                    name: "百合女性",
                    value: "baihenvxing"
                }, {
                    type_name: "SelectOption",
                    name: "生活漫画",
                    value: "shenghuomanhua"
                }, {
                    type_name: "SelectOption",
                    name: "儿童",
                    value: "ertong"
                }, {
                    type_name: "SelectOption",
                    name: "舞蹈",
                    value: "wudao"
                }, {
                    type_name: "SelectOption",
                    name: "甜宠",
                    value: "tianchong"
                }, {
                    type_name: "SelectOption",
                    name: "文改",
                    value: "wengai"
                }, {
                    type_name: "SelectOption",
                    name: "独家",
                    value: "dujia"
                }, {
                    type_name: "SelectOption",
                    name: "标签",
                    value: "biaoqian"
                }, {
                    type_name: "SelectOption",
                    name: "宅腐漫画",
                    value: "zhaifumanhua"
                }, {
                    type_name: "SelectOption",
                    name: "情感",
                    value: "qinggan"
                }, {
                    type_name: "SelectOption",
                    name: "茗卡通",
                    value: "mingkatong"
                }, {
                    type_name: "SelectOption",
                    name: "纠结",
                    value: "jiujie"
                }, {
                    type_name: "SelectOption",
                    name: "恋爱冒险搞笑",
                    value: "lianaimaoxiangaoxiao"
                }, {
                    type_name: "SelectOption",
                    name: "修真恋爱架空",
                    value: "xiuzhenlianaijiakong"
                }, {
                    type_name: "SelectOption",
                    name: "恋爱搞笑后宫",
                    value: "lianaigaoxiaohougong"
                }, {
                    type_name: "SelectOption",
                    name: "悬疑恐怖",
                    value: "xuanyikongbu"
                }, {
                    type_name: "SelectOption",
                    name: "恋爱校园生活",
                    value: "lianaixiaoyuanshenghuo"
                }, {
                    type_name: "SelectOption",
                    name: "修真恋爱古风",
                    value: "xiuzhenlianaigufeng"
                }, {
                    type_name: "SelectOption",
                    name: "生活悬疑灵异",
                    value: "shenghuoxuanyilingyi"
                }, {
                    type_name: "SelectOption",
                    name: "青年漫画",
                    value: "qingnianmanhua"
                }, {
                    type_name: "SelectOption",
                    name: "历史漫画",
                    value: "lishimanhua"
                }, {
                    type_name: "SelectOption",
                    name: "美少女",
                    value: "meishaonv"
                }, {
                    type_name: "SelectOption",
                    name: "爽流",
                    value: "shuangliu"
                }, {
                    type_name: "SelectOption",
                    name: "蔷薇",
                    value: "qiangwei"
                }, {
                    type_name: "SelectOption",
                    name: "高智商",
                    value: "gaozhishang"
                }, {
                    type_name: "SelectOption",
                    name: "悬疑推理",
                    value: "xuanyituili"
                }, {
                    type_name: "SelectOption",
                    name: "机智",
                    value: "jizhi"
                }, {
                    type_name: "SelectOption",
                    name: "动画",
                    value: "donghua"
                }, {
                    type_name: "SelectOption",
                    name: "热血动作",
                    value: "rexuedongzuo"
                }, {
                    type_name: "SelectOption",
                    name: "秀吉",
                    value: "xiuji"
                }, {
                    type_name: "SelectOption",
                    name: "AA",
                    value: "AA"
                }, {
                    type_name: "SelectOption",
                    name: "改编",
                    value: "gaibian"
                }, {
                    type_name: "SelectOption",
                    name: "橘味",
                    value: "juwei"
                }, {
                    type_name: "SelectOption",
                    name: "乙女",
                    value: "yinv"
                }, {
                    type_name: "SelectOption",
                    name: "猎奇",
                    value: "lieqi"
                }, {
                    type_name: "SelectOption",
                    name: "智斗",
                    value: "zhidou"
                }, {
                    type_name: "SelectOption",
                    name: "正能量",
                    value: "zhengnengliang"
                }, {
                    type_name: "SelectOption",
                    name: "大女主",
                    value: "danvzhu"
                }, {
                    type_name: "SelectOption",
                    name: "末日",
                    value: "mori"
                }, {
                    type_name: "SelectOption",
                    name: "重生",
                    value: "zhongsheng"
                }, {
                    type_name: "SelectOption",
                    name: "修仙",
                    value: "xiuxian"
                }, {
                    type_name: "SelectOption",
                    name: "系统",
                    value: "xitong"
                }, {
                    type_name: "SelectOption",
                    name: "神仙",
                    value: "shenxian"
                }, {
                    type_name: "SelectOption",
                    name: "怪物",
                    value: "guaiwu"
                }, {
                    type_name: "SelectOption",
                    name: "宅斗",
                    value: "zhaidou"
                }, {
                    type_name: "SelectOption",
                    name: "妖怪",
                    value: "yaoguai"
                }, {
                    type_name: "SelectOption",
                    name: "神豪",
                    value: "shenhao"
                }, {
                    type_name: "SelectOption",
                    name: "高甜",
                    value: "gaotian"
                }, {
                    type_name: "SelectOption",
                    name: "电竞",
                    value: "dianjing"
                }, {
                    type_name: "SelectOption",
                    name: "ゆり",
                    value: "unknown"
                }, {
                    type_name: "SelectOption",
                    name: "豪快",
                    value: "haokuai"
                }, {
                    type_name: "SelectOption",
                    name: "女生",
                    value: "nvsheng"
                }, {
                    type_name: "SelectOption",
                    name: "男生",
                    value: "nansheng"
                }, {
                    type_name: "SelectOption",
                    name: "丧尸",
                    value: "sangshi"
                }, {
                    type_name: "SelectOption",
                    name: "扶她",
                    value: "futa"
                }, {
                    type_name: "SelectOption",
                    name: "基腐",
                    value: "jifu"
                }, {
                    type_name: "SelectOption",
                    name: "TS",
                    value: "TS"
                }, {
                    type_name: "SelectOption",
                    name: "氪金",
                    value: "kejin"
                }, {
                    type_name: "SelectOption",
                    name: "福瑞",
                    value: "furui"
                }, {
                    type_name: "SelectOption",
                    name: "宫廷东方",
                    value: "gongtingdongfang"
                }, {
                    type_name: "SelectOption",
                    name: "泛爱",
                    value: "fanai"
                }, {
                    type_name: "SelectOption",
                    name: "生存",
                    value: "shengcun"
                }, {
                    type_name: "SelectOption",
                    name: "2021大赛",
                    value: "2021dasai"
                }, {
                    type_name: "SelectOption",
                    name: "现代",
                    value: "xiandai"
                }, {
                    type_name: "SelectOption",
                    name: "西幻",
                    value: "xihuan"
                }, {
                    type_name: "SelectOption",
                    name: "游戏竞技",
                    value: "youxijingji"
                }, {
                    type_name: "SelectOption",
                    name: "女神",
                    value: "nvshen"
                }, {
                    type_name: "SelectOption",
                    name: "悬疑灵异",
                    value: "xuanyilingyi"
                }, {
                    type_name: "SelectOption",
                    name: "未来漫画家",
                    value: "weilaimanhuajia"
                }, {
                    type_name: "SelectOption",
                    name: "武侠仙侠",
                    value: "wuxiaxianxia"
                }, {
                    type_name: "SelectOption",
                    name: "架空世界",
                    value: "jiakongshijie"
                }, {
                    type_name: "SelectOption",
                    name: "金手指",
                    value: "jinshouzhi"
                }, {
                    type_name: "SelectOption",
                    name: "萌娃",
                    value: "mengwa"
                }, {
                    type_name: "SelectOption",
                    name: "快穿",
                    value: "kuaichuan"
                }, {
                    type_name: "SelectOption",
                    name: "撒糖",
                    value: "satang"
                }, {
                    type_name: "SelectOption",
                    name: "韩漫",
                    value: "hanman"
                }, {
                    type_name: "SelectOption",
                    name: "BL",
                    value: "BL"
                }, {
                    type_name: "SelectOption",
                    name: "古代言情",
                    value: "gudaiyanqing"
                }, {
                    type_name: "SelectOption",
                    name: "古言脑洞",
                    value: "guyannaodong"
                }, {
                    type_name: "SelectOption",
                    name: "现代言情",
                    value: "xiandaiyanqing"
                }, {
                    type_name: "SelectOption",
                    name: "现言甜宠",
                    value: "xianyantianchong"
                }, {
                    type_name: "SelectOption",
                    name: "奇幻冒险",
                    value: "qihuanmaoxian"
                }, {
                    type_name: "SelectOption",
                    name: "欧风",
                    value: "oufeng"
                }, {
                    type_name: "SelectOption",
                    name: "古言萌宝",
                    value: "guyanmengbao"
                }, {
                    type_name: "SelectOption",
                    name: "团宠",
                    value: "tuanchong"
                }, {
                    type_name: "SelectOption",
                    name: "欧式宫廷",
                    value: "oushigongting"
                }, {
                    type_name: "SelectOption",
                    name: "玄幻言情",
                    value: "xuanhuanyanqing"
                }, {
                    type_name: "SelectOption",
                    name: "虐渣",
                    value: "nuezha"
                }, {
                    type_name: "SelectOption",
                    name: "豪门总裁",
                    value: "haomenzongcai"
                }, {
                    type_name: "SelectOption",
                    name: "现言萌宝",
                    value: "xianyanmengbao"
                }, {
                    type_name: "SelectOption",
                    name: "迪化",
                    value: "dihua"
                }, {
                    type_name: "SelectOption",
                    name: "台湾原创作品",
                    value: "taiwanyuanchuangzuopin"
                }, {
                    type_name: "SelectOption",
                    name: "动作冒险",
                    value: "dongzuomaoxian"
                }, {
                    type_name: "SelectOption",
                    name: "幽默搞笑",
                    value: "youmogaoxiao"
                }, {
                    type_name: "SelectOption",
                    name: "国漫",
                    value: "guoman"
                }, {
                    type_name: "SelectOption",
                    name: "日本",
                    value: "riben"
                }, {
                    type_name: "SelectOption",
                    name: "韩国",
                    value: "hanguo"
                }, {
                    type_name: "SelectOption",
                    name: "欧美",
                    value: "oumei"
                }, {
                    type_name: "SelectOption",
                    name: "养成",
                    value: "yangcheng"
                }, {
                    type_name: "SelectOption",
                    name: "亲情",
                    value: "qinqing"
                }, {
                    type_name: "SelectOption",
                    name: "玄幻脑洞",
                    value: "xuanhuannaodong"
                }, {
                    type_name: "SelectOption",
                    name: "都市脑洞",
                    value: "dushinaodong"
                }, {
                    type_name: "SelectOption",
                    name: "奇幻爱情",
                    value: "qihuanaiqing"
                }, {
                    type_name: "SelectOption",
                    name: "无节操",
                    value: "wujiecao"
                }, {
                    type_name: "SelectOption",
                    name: "反套路",
                    value: "fantaolu"
                }, {
                    type_name: "SelectOption",
                    name: "TL",
                    value: "TL"
                }, {
                    type_name: "SelectOption",
                    name: "长条",
                    value: "changtiao"
                }, {
                    type_name: "SelectOption",
                    name: "悬疑脑洞",
                    value: "xuanyinaodong"
                }, {
                    type_name: "SelectOption",
                    name: "宠兽",
                    value: "chongshou"
                }, {
                    type_name: "SelectOption",
                    name: "黑暗",
                    value: "heian"
                }, {
                    type_name: "SelectOption",
                    name: "独特",
                    value: "dute"
                }, {
                    type_name: "SelectOption",
                    name: "成长",
                    value: "chengzhang"
                }, {
                    type_name: "SelectOption",
                    name: "快看漫画",
                    value: "kuaikanmanhua"
                }, {
                    type_name: "SelectOption",
                    name: "强强",
                    value: "qiangqiang"
                }, {
                    type_name: "SelectOption",
                    name: "少男",
                    value: "shaonan"
                }, {
                    type_name: "SelectOption",
                    name: "知音漫客",
                    value: "zhiyinmanke"
                }, {
                    type_name: "SelectOption",
                    name: "regions.日本",
                    value: "regionsriben"
                }, {
                    type_name: "SelectOption",
                    name: "幻想言情",
                    value: "huanxiangyanqing"
                }, {
                    type_name: "SelectOption",
                    name: "偶像",
                    value: "ouxiang"
                }, {
                    type_name: "SelectOption",
                    name: "直播",
                    value: "zhibo"
                }, {
                    type_name: "SelectOption",
                    name: "游戏体育",
                    value: "youxitiyu"
                }, {
                    type_name: "SelectOption",
                    name: "橘系",
                    value: "juxi"
                }, {
                    type_name: "SelectOption",
                    name: "兄弟情",
                    value: "xiongdiqing"
                }, {
                    type_name: "SelectOption",
                    name: "限制级",
                    value: "xianzhiji"
                }, {
                    type_name: "SelectOption",
                    name: "浪漫爱情",
                    value: "langmanaiqing"
                }, {
                    type_name: "SelectOption",
                    name: "港台",
                    value: "gangtai"
                }, {
                    type_name: "SelectOption",
                    name: "现言脑洞",
                    value: "xianyannaodong"
                }, {
                    type_name: "SelectOption",
                    name: "无敌流",
                    value: "wudiliu"
                }, {
                    type_name: "SelectOption",
                    name: "regions.其它漫画",
                    value: "regionsqitamanhua"
                }, {
                    type_name: "SelectOption",
                    name: "双男主",
                    value: "shuangnanzhu"
                }, {
                    type_name: "SelectOption",
                    name: "古装",
                    value: "guzhuang"
                }, {
                    type_name: "SelectOption",
                    name: "军事",
                    value: "junshi"
                }, {
                    type_name: "SelectOption",
                    name: "LGBTQ+",
                    value: "LGBTQ"
                }, {
                    type_name: "SelectOption",
                    name: "國漫",
                    value: "guoman2"
                }, {
                    type_name: "SelectOption",
                    name: "戀愛",
                    value: "lianai2"
                }, {
                    type_name: "SelectOption",
                    name: "冒險",
                    value: "maoxian2"
                }, {
                    type_name: "SelectOption",
                    name: "格鬥",
                    value: "gedou2"
                }, {
                    type_name: "SelectOption",
                    name: "懸疑",
                    value: "xuanyi2"
                }, {
                    type_name: "SelectOption",
                    name: "劇情",
                    value: "juqing2"
                }, {
                    type_name: "SelectOption",
                    name: "純愛",
                    value: "chunai2"
                }, {
                    type_name: "SelectOption",
                    name: "韓國",
                    value: "hanguo2"
                }, {
                    type_name: "SelectOption",
                    name: "歐美",
                    value: "oumei2"
                }, {
                    type_name: "SelectOption",
                    name: "熱血",
                    value: "rexue2"
                }, {
                    type_name: "SelectOption",
                    name: "後宮",
                    value: "hougong2"
                }, {
                    type_name: "SelectOption",
                    name: "武俠",
                    value: "wuxia2"
                }, {
                    type_name: "SelectOption",
                    name: "古風",
                    value: "gufeng2"
                }, {
                    type_name: "SelectOption",
                    name: "總裁",
                    value: "zongcai2"
                }, {
                    type_name: "SelectOption",
                    name: "異能",
                    value: "yineng2"
                }, {
                    type_name: "SelectOption",
                    name: "戰爭",
                    value: "zhanzheng2"
                }, {
                    type_name: "SelectOption",
                    name: "韓漫",
                    value: "hanman2"
                }, {
                    type_name: "SelectOption",
                    name: "regions.",
                    value: "regions"
                },
                ],
            },
            {
                type: "status",
                name: "进度",
                type_name: "SelectFilter",
                values: [{
                    type_name: "SelectOption",
                    name: "全部",
                    value: ""
                },
                {
                    type_name: "SelectOption",
                    name: "已完结",
                    value: "wanjie"
                },
                {
                    type_name: "SelectOption",
                    name: "连载中",
                    value: "lianzai"
                }
                ],
            }
        ];
    }
    getSourcePreferences() {
        return [{
            "key": "domain_url",
            "editTextPreference": {
                "title": "Url",
                "summary": "古风漫画网址",
                "value": "https://www.gufengmh.com",
                "dialogTitle": "URL",
                "dialogMessage": "",
            }
        }
        ];
    }
}
const mangayomiSources = [{
    "name": "Batoto (v2)",
    "lang": "All",
    "baseUrl": "https://bato.to",
    "apiUrl": "",
    "iconUrl": "https://bato.to/amsta/img/btoto/logo-batoto.png?v0",
    "typeSource": "single",
    "itemType": 0,
    "version": "1.0.0",
    "pkgPath": "manga/src/all/batoto.js",
    "notes": ""
}];

class DefaultExtension extends MProvider {

    statusFromString(status) {
        return {
            "Ongoing": 0,
            "Completed": 1,
            "On_Hiatus": 2,
            "Discontinued": 3,
            "Unrealeased": 4,
        }[status] ?? 5;
    }

    popularMangaListFromHome(res) {
        const doc = new Document(res.body);
        const elements = doc.selectFirst("div.mt-4.row.row-cols-3.row-cols-md-4.row-cols-lg-8.g-0.home-popular").select("div");
        const list = [];

        for (const element of elements) {
            const name = element.selectFirst("a.item-title").text;
            const imageUrl = element.selectFirst("img").getSrc;
            const link = `${this.source.baseUrl}` + element.selectFirst("a.item-title").getHref;
            list.push({ name, imageUrl, link });
        }

        const hasNextPage = false;
        return { "list": list, "hasNextPage": hasNextPage };
    }
    
    latestMangaListFromHome(res) {
        const doc = new Document(res.body);
        const elements = doc.selectFirst("div.mt-0.row.row-cols-1.row-cols-sm-2.row-cols-lg-3.series-list").select("div");
        const list = [];

        for (const element of elements) {
            const name = element.selectFirst("a.item-title").text;
            const imageUrl = element.selectFirst("img").getSrc;
            const link = `${this.source.baseUrl}` + element.selectFirst("a.item-title").getHref;
            list.push({ name, imageUrl, link });
        }

        const hasNextPage = false;
        return { "list": list, "hasNextPage": hasNextPage };
    }

    mangaFromSearch(res) {
        const doc = new Document(res.body);
        const elements = doc.selectFirst("div#series-list").select("div");
        const list = [];

        for (const element of elements) {
            const name = element.selectFirst("a.item-title").text;
            const imageUrl = element.selectFirst("img").getSrc;
            const link = `${this.source.baseUrl}` + element.selectFirst("a.item-title").getHref;
            let genre = [];
            const genres = element.select("div.item-genre > *");
            for (const a of genres) {
                genre.push(a.text);
            }
            list.push({ name, imageUrl, link, genre });
        }

        const hasNextPage = false;
        return { "list": list, "hasNextPage": hasNextPage };
    }

    getHeaders(url) {
        return {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Connection": "keep-alive",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
        }
    }

    getUrl() {
        const preference = new SharedPreferences();
        return preference.get("url")
    }

    async getPopular(page) {
        const res = await new Client().get(`${this.getUrl()}/`, this.getHeaders());
        return this.popularMangaListFromHome(res);
    }

    async getLatestUpdates(page) {
        const res = await new Client().get(`${this.getUrl()}/`, this.getHeaders());
        return this.latestMangaListFromHome(res);
    }

    async search(query, page, filters) {
        let url = `${this.getUrl()}/browse?`;
        if (query != "") {
            url += `word=${query}&page=${page}`
        } else {
            url += `page=${page}`
        }
        filters.forEach(filter => {
            if (filter.type === "genres") {
                const included = filter.state.filter(e => e.state === 1);
                const excluded = filter.state.filter(e => e.state === 2);
                if (included.length > 0) {
                    url += "&genres=";
                    included.forEach(val => {
                        url += `${val.value}`;
                    });
                }
                if (excluded.length > 0) {
                    url += "%7"
                    excluded.forEach(val => {
                        url += `${val.value}`;
                    });
                }
            } else if (filter.type === "translated") {
                const langs = filter.state.filter(e => e.state === true);
                if (langs.length > 0) {
                    url += "&langs="
                    langs.forEach(lang => {
                        url += `${lang.value}`;
                    });
                }
            } else if (filter.type === "original") {
                const langs = filter.state.filter(e => e.state === true);
                if (langs.length > 0) {
                    url += "&origs="
                    langs.forEach(lang => {
                        url += `${lang.value}`;
                    });
                }
            } else if (filter.type === "status") {
                if (filter.state != 0) {
                    url += `&release=${filter.values[filter.state].value}`;
                }
            } else if (filter.type === "chapters") {
                if (filter.state != 0) {
                    url += `&chapters=${filter.values[filter.state].value}`;
                }
            } else if (filter.type === "sort") {
                if (filter.state.index != 5 && !filter.state.ascending) {
                    const get_direction = (ascending) => {
                        if (ascending == true) {
                            return "az";
                        } else {
                            return "za"
                        }
                    }
                    url += `&sort=${filter.values[filter.state.index].value}.${get_direction(filter.state.ascending)}`;
                }
            }
        });
        const res = await new Client().get(url, this.getHeaders());
        return this.mangaFromSearch(res);
    }

    async getDetail(url) {
        const res = await new Client().get(url, this.getHeaders());
        const doc = new Document(res.body);
        const detail = {};

        detail.name = doc.selectFirst("h3.item-title > a").text;
        detail.imageUrl = doc.selectFirst("img.shadow-6").getSrc;

        const description_elements = doc.selectFirst("div.col-24.col-sm-16.col-md-18.mt-4.mt-sm-0.attr-main").select("div");
        for (let i = 0; i < description_elements.length; i++) {
            if (description_elements[i].selectFirst("b").text == "Authors:") {
                detail.author = description_elements[i].selectFirst("a").text;
            } else if (description_elements[i].selectFirst("b").text == "Artists:") {
                detail.artist = description_elements[i].selectFirst("a").text;
            } else if (description_elements[i].selectFirst("b").text == "Original work:") {
                detail.status = this.statusFromString(description_elements[i].selectFirst("span").text);
            } else if (description_elements[i].selectFirst("b").text == "Genres:") {
                const genres = description_elements[i].select("span > *");
                detail.genre = [];
                for (let i = 0; i < genres.length; i++) {
                    detail.genre.push(genres[i].text);
                }
            }
        }
        detail.description = doc.selectFirst("div.limit-height-body > div").text;

        detail.chapters = []
        const chapters = doc.select("div.mt-4.episode-list > div.main > div");
        for (let i = 0; i < chapters.length; i++) {
            const name = chapters[i].selectFirst("a > b").text;
            const url = `${this.getUrl()}` + chapters[i].selectFirst("a.visited.chapt").getHref;
            const scanlator = chapters[i].selectFirst("a.ps-3 > span").text;
            detail.chapters.push({ name, url, scanlator });
        }

        return detail
    }

    async getPageList(url) {
        const res = await new Client().get(url, this.getHeaders());
        const doc = new Document(res.body);
        
        let pages = [];
        const scripts = doc.select("script");
        let targetScript = null;
        
        for (const script of scripts) {
            const code = script.text;
            if (code.includes('const imgHttps')) {
                targetScript = code;
                break;
            }
        }
        if (targetScript != null) {
            const match = targetScript.match(/const imgHttps\s*=\s*(\[[\s\S]*?\]);/);
            if (match) {
                const imgHttpsCode = match[1];
                pages = eval(imgHttpsCode);
            }
        }
        return pages;
    }

    getFilterList() {
        return [
            {
                type_name: "GroupFilter",
                type: "genres",
                name: "Genres",
                state: [
                    ["Artbook", "artbook,"],
                    ["Cartoon", "cartoon,"],
                    ["Comic", "comic,"],
                    ["Doujinshi", "doujinshi,"],
                    ["Imageset", "imageset,"],
                    ["Manga", "manga,"],
                    ["Manhua", "manhua,"],
                    ["Manhwa", "manhwa,"],
                    ["Webtoon", "webtoon,"],
                    ["Western", "western,"],
                    ["4-Koma", "_4_koma,"],
                    ["Oneshot", "oneshot,"],
                    ["Shoujo(G)", "shoujo,"],
                    ["Shounen(B)", "shounen,"],
                    ["Josei(W)", "josei,"],
                    ["Seinen(M)", "seinen,"],
                    ["Yuri(GL)", "yuri,"],
                    ["Yaoi(BL)", "yaoi,"],
                    ["Bara(ML)", "bara,"],
                    ["Kodomo(Kid", "kodomo,"],
                    ["Silver & Golden", "old_people,"],
                    ["Non-Human", "non_human,"],
                    ["Gore", "gore,"],
                    ["Bloody", "bloody,"],
                    ["Violence", "violence,"],
                    ["Ecchi", "ecchi,"],
                    ["Adult", "adult,"],
                    ["Mature", "mature,"],
                    ["Smut", "smut,"],
                    ["Hentai", "hentai,"],
                    ["Action", "action,"],
                    ["Adaption", "adaptation,"],
                    ["Adventure", "adventure,"],
                    ["Age Gap", "age_gap,"],
                    ["Aliens", "aliens,"],
                    ["Animals", "animals,"],
                    ["Anthology", "anthology,"],
                    ["Beasts", "beasts,"],
                    ["Bodyswap", "bodyswap,"],
                    ["Boys", "boys,"],
                    ["Cars", "cars,"],
                    ["Cheating/Infidel", "cheating_infidelity,"],
                    ["Childhood Friends", "childhood_friends,"],
                    ["College Life", "college_life,"],
                    ["Commedy", "comedy,"],
                    ["Contest Winning", "contest_winning,"],
                    ["Cooking", "cooking,"],
                    ["Crime", "crime,"],
                    ["Crossdressing", "crossdressing,"],
                    ["Delinquents", "delinquents,"],
                    ["Dementia", "dementia,"],
                    ["Demons", "demons,"],
                    ["Drama", "drama,"],
                    ["Dungeons", "dungeons,"],
                    ["Emperor's Daughter", "emperor_daughte,"],
                    ["Fantasy", "fantasy,"],
                    ["Fan-Colored", "fan_colored,"],
                    ["Fetish", "fetish,"],
                    ["Full Color", "full_color,"],
                    ["Game", "game,"],
                    ["Gender Bender", "gender_bender,"],
                    ["Gender Swap", "genderswap,"],
                    ["Ghosts", "ghosts,"],
                    ["Girls", "girls,"],
                    ["Gyaru", "gyaru,"],
                    ["Harem", "harem,"],
                    ["Harlequin", "harlequin,"],
                    ["Historical", "historical,"],
                    ["Horror", "horror,"],
                    ["Incest", "incest,"],
                    ["Isekai", "isekai,"],
                    ["Kids", "kids,"],
                    ["Magic", "magic,"],
                    ["Magical Girls", "magical_girls,"],
                    ["Martial Arts", "martial_arts,"],
                    ["Mecha", "mecha,"],
                    ["Medical", "medical,"],
                    ["Military", "military,"],
                    ["Monster Girls", "monster_girls,"],
                    ["Monsters", "monsters,"],
                    ["Music", "music,"],
                    ["Mystery", "mystery,"],
                    ["Netorare/NTR", "netorare,"],
                    ["Ninja", "ninja,"],
                    ["Office Workers", "office_workers,"],
                    ["Omegaverse", "omegaverse,"],
                    ["Parody", "parody,"],
                    ["Philosophical", "philosophical,"],
                    ["Police", "police,"],
                    ["Post-Apocalyptic", "post_apocalyptic,"],
                    ["Phychological", "psychological,"],
                    ["Regression", "regression,"],
                    ["Reincarnation", "reincarnation,"],
                    ["Reverse Harem", "reverse_harem,"],
                    ["Revenge", "revenge,"],
                    ["Revser Isekai", "reverse_isekai,"],
                    ["Romance", "romance,"],
                    ["Royal Family", "royal_family,"],
                    ["Royalty", "royalty,"],
                    ["Samurai", "samurai,"],
                    ["School Life", "school_life,"],
                    ["Sci-Fi", "sci_fi,"],
                    ["Shoujo Ai", "shoujo_ai,"],
                    ["Shounen Ai", "shounen_ai,"],
                    ["Showbiz", "showbiz,"],
                    ["Slice Of Life", "slice_of_life,"],
                    ["SM/BDSM/SUB-DOM", "sm_bdsm,"],
                    ["Space", "space,"],
                    ["Sports", "sports,"],
                    ["Super Power", "super_power,"],
                    ["Superhero", "superhero,"],
                    ["Supernatural", "supernatural,"],
                    ["Survival", "survival,"],
                    ["Thriller", "thriller,"],
                    ["Time Travel", "time_travel,"],
                    ["Tower Climbing", "tower_climbing,"],
                    ["Traditional Games", "traditional_games,"],
                    ["Tragedy", "tragedy,"],
                    ["Transmigration", "transmigration,"],
                    ["Vampires", "vampires,"],
                    ["Villainess", "villainess,"],
                    ["Video Games", "video_games,"],
                    ["Virtual Reality", "virtual_reality,"],
                    ["Wuxia", "wuxia,"],
                    ["Xianxia", "xianxia,"],
                    ["Xuanhuan", "xuanhuan,"],
                    ["Yakuzas", "yakuzas,"],
                    ["Zombies", "zombies,"],
                ].map(x => ({ type_name: 'TriState', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                type: "translated",
                name: "Translated",
                state: [
                    ["Afrikaans", "af,"],
                    ["Arabic", "ar,"],
                    ["Azerbaijani", "az,"],
                    ["Basque", "eu,"],
                    ["Belarusian", "be,"],
                    ["Bengali", "bn,"],
                    ["Bosnian", "bs,"],
                    ["Bulgarian", "bg,"],
                    ["Burmese", "my,"],
                    ["Cambodian", "km,"],
                    ["Cebuano", "ceb,"],
                    ["Chinese", "zh,"],
                    ["Chinese (粵)", "zh_hk,"],
                    ["Chinese (繁)", "zh_tw,"],
                    ["Croatian", "hr,"],
                    ["Czech", "cs,"],
                    ["Danish", "da,"],
                    ["Dutch", "nl,"],
                    ["English", "en,"],
                    ["English (US)", "en_us,"],
                    ["Esperanto", "eo,"],
                    ["Estonian", "et,"],
                    ["Filipino", "fil,"],
                    ["Finnish", "fi,"],
                    ["French", "fr,"],
                    ["Georgian", "ka,"],
                    ["German", "de,"],
                    ["Greek", "el,"],
                    ["Gujarati", "gu,"],
                    ["Haitian Creole", "ht,"],
                    ["Hebrew", "he,"],
                    ["Hindi", "hi,"],
                    ["Hungarian", "hu,"],
                    ["Igbo", "is,"],
                    ["Indonesian", "id,"],
                    ["Irish", "ga,"],
                    ["Italian", "it,"],
                    ["Japanese", "ja,"],
                    ["Javanese", "jv,"],
                    ["Kazakh", "kk,"],
                    ["Korean", "ko,"],
                    ["Kurdish", "ku,"],
                    ["Kyrgyz", "ky,"],
                    ["Laothian", "lo,"],
                    ["Latvian", "lv,"],
                    ["Lithuanian", "lt,"],
                    ["Malay", "ms,"],
                    ["Malayalam", "ml,"],
                    ["Moldavian", "mo,"],
                    ["Mongolian", "mn,"],
                    ["Nepali", "ne,"],
                    ["Norwegian", "no,"],
                    ["Pashto", "ps,"],
                    ["Persian", "fa,"],
                    ["Polish", "pl,"],
                    ["Portuguese", "pt,"],
                    ["Portuguese (BR)", "pt_br,"],
                    ["Portuguese (PT)", "pt_pt,"],
                    ["Romanian", "ro,"],
                    ["Russian", "ru,"],
                    ["Serbian", "sr,"],
                    ["Sinhalese", "si,"],
                    ["Slovak", "sk,"],
                    ["Somali", "so,"],
                    ["Spanish", "es,"],
                    ["Spanish (LA)", "es_419,"],
                    ["Tamil", "ta,"],
                    ["Telugu", "te,"],
                    ["Thai", "th,"],
                    ["Tigrinya", "ti,"],
                    ["Turkish", "tr,"],
                    ["Ukrainian", "uk,"],
                    ["Urdu", "ur,"],
                    ["Vietnamese", "vi,"],
                    ["Yoruba", "yo,"],
                    ["Zulu", "zu,"],
                    ["Other", "_t"],
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                type: "original",
                name: "Original",
                state: [
                    ["Afrikaans", "af,"],
                    ["Albanian", "sq,"],
                    ["Amharic", "am,"],
                    ["Arabic", "ar,"],
                    ["Armenian", "hy,"],
                    ["Azerbaijani", "az,"],
                    ["Belarusian", "be,"],
                    ["Bengali", "bn,"],
                    ["Bosnian", "bs,"],
                    ["Bulgarian", "bg,"],
                    ["Burmese", "my,"],
                    ["Cambodian", "km,"],
                    ["Cebuano", "ceb,"],
                    ["Chinese", "zh,"],
                    ["Chinese (粵)", "zh_hk,"],
                    ["Chinese (繁)", "zh_tw,"],
                    ["Croatian", "hr,"],
                    ["Czech", "cs,"],
                    ["Dutch", "nl,"],
                    ["English", "en,"],
                    ["English (US)", "en_us,"],
                    ["Filipino", "fil,"],
                    ["Finnish", "fi,"],
                    ["French", "fr,"],
                    ["German", "de,"],
                    ["Greek", "el,"],
                    ["Hindi", "hi,"],
                    ["Hungarian", "hu,"],
                    ["Igbo", "ig,"],
                    ["Indonesian", "id,"],
                    ["Italian", "it,"],
                    ["Japanese", "ja,"],
                    ["Javanese", "jv,"],
                    ["Kannada", "kn,"],
                    ["Kazakh", "kk,"],
                    ["Korean", "ko,"],
                    ["Kurdish", "ku,"],
                    ["Kyrgyz", "ky,"],
                    ["Latvian", "lv,"],
                    ["Lithuanian", "lt,"],
                    ["Luxembourgish", "lb,"],
                    ["Macedonian", "mk,"],
                    ["Malagasy", "mg,"],
                    ["Malay", "ms,"],
                    ["Mongolian", "mn,"],
                    ["Persian", "fa,"],
                    ["Polish", "pl,"],
                    ["Portuguese", "pt,"],
                    ["Portuguese (BR)", "pt_br,"],
                    ["Russian", "ru,"],
                    ["Serbian", "sr,"],
                    ["Shona", "sn,"],
                    ["Sinhaleese", "si,"],
                    ["Spanish", "es,"],
                    ["Spanish (LA)", "es_419,"],
                    ["Tajik", "tg,"],
                    ["Thai", "th,"],
                    ["Turkish", "tr,"],
                    ["Ukrainian", "uk,"],
                    ["Urdu", "ur,"],
                    ["Uzbek", "uz,"],
                    ["Vietnamese", "vi,"],
                    ["Yoruba", "yo,z"],
                    ["Zulu", "u,"],
                    ["Other", "_t"],
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "status",
                name: "Status",
                values: [
                    ["All", ""],
                    ["Pending", "pending"],
                    ["Ongoing", "ongoing"],
                    ["Completed", "completed"],
                    ["Hiatus", "hiatus"],
                    ["Cancelled", "cancelled"],
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "chapters",
                name: "Chapters",
                values: [
                    ["All", ""],
                    ["1 ~ 9", "1-9"],
                    ["10 ~ 29", "10-29"],
                    ["30 ~ 99", "30-99"],
                    ["100 ~ 199", "100-199"],
                    ["200+", "200"],
                    ["100+", "100"],
                    ["50+", "50"],
                    ["10+", "10"],
                    ["1+", "1"],
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SortFilter",
                type: "sort",
                name: "Sort",
                state: {
                    type_name: "SortState",
                    index: 5,
                    ascending: false
                },
                values: [
                    ["A-Z", "title"],
                    ["Update time", "update"],
                    ["Create Time", "create"],
                    ["Views: All Time", "views_a"],
                    ["Views: 365 days", "views_y"],
                    ["Views: 30 days", "views_m"],
                    ["Views: 7 days", "views_w"],
                    ["Views: 24 hours", "views_d"],
                    ["Views: 60 minutes", "views_h"],
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
        ];
    }
    
    getSourcePreferences() {
        return [
            {
                "key": "url",
                "listPreference": {
                    "title": "Website Url",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": [
                        "bato.to",
                        "ato.to",
                        "dto.to",
                        "fto.to",
                        "hto.to",
                        "jto.to",
                        "lto.to",
                        "mto.to",
                        "nto.to",
                        "vto.to",
                        "wto.to",
                        "xto.to",
                        "yto.to",
                        "vba.to",
                        "wba.to",
                        "xba.to",
                        "yba.to",
                        "zba.to",
                        "bato.ac",
                        "bato.bz",
                        "bato.cc",
                        "bato.cx",
                        "bato.id",
                        "bato.pw",
                        "bato.sh",
                        "bato.vc",
                        "bato.day",
                        "bato.red",
                        "bato.run",
                        "batoto.in",
                        "batoto.tv",
                        "batotoo.com",
                        "batotwo.com",
                        "batpub.com",
                        "batread.com",
                        "battwo.com",
                        "xbato.com",
                        "xbato.net",
                        "xbato.org",
                        "zbato.com",
                        "zbato.net",
                        "zbato.org",
                        "comiko.net",
                        "comiko.org",
                        "mangatoto.com",
                        "mangatoto.net",
                        "mangatoto.org",
                        "batocomic.com",
                        "batocomic.net",
                        "batocomic.org",
                        "readtoto.com",
                        "readtoto.net",
                        "readtoto.org",
                        "kuku.to",
                        "okok.to",
                        "ruru.to",
                        "xdxd.to",
                    ],
                    "entryValues": [
                        "https://bato.to",
                        "https://ato.to",
                        "https://dto.to",
                        "https://fto.to",
                        "https://hto.to",
                        "https://jto.to",
                        "https://lto.to",
                        "https://mto.to",
                        "https://nto.to",
                        "https://vto.to",
                        "https://wto.to",
                        "https://xto.to",
                        "https://yto.to",
                        "https://vba.to",
                        "https://wba.to",
                        "https://xba.to",
                        "https://yba.to",
                        "https://zba.to",
                        "https://bato.ac",
                        "https://bato.bz",
                        "https://bato.cc",
                        "https://bato.cx",
                        "https://bato.id",
                        "https://bato.pw",
                        "https://bato.sh",
                        "https://bato.vc",
                        "https://bato.day",
                        "https://bato.red",
                        "https://bato.run",
                        "https://batoto.in",
                        "https://batoto.tv",
                        "https://batotoo.com",
                        "https://batotwo.com",
                        "https://batpub.com",
                        "https://batread.com",
                        "https://battwo.com",
                        "https://xbato.com",
                        "https://xbato.net",
                        "https://xbato.org",
                        "https://zbato.com",
                        "https://zbato.net",
                        "https://zbato.org",
                        "https://comiko.net",
                        "https://comiko.org",
                        "https://mangatoto.com",
                        "https://mangatoto.net",
                        "https://mangatoto.org",
                        "https://batocomic.com",
                        "https://batocomic.net",
                        "https://batocomic.org",
                        "https://readtoto.com",
                        "https://readtoto.net",
                        "https://readtoto.org",
                        "https://kuku.to",
                        "https://okok.to",
                        "https://ruru.to",
                        "https://xdxd.to",
                    ],
                }
            },
        ];
    }
}

const mangayomiSources = [
    {
        "name": "Comick",
        "langs": ["all", "en", "pt-br", "ru", "fr", "es-419", "pl", "tr", "it", "es", "id", "hu", "vi", "zh-hk", "ar", "de", "zh", "ca", "bg", "th", "fa", "uk", "mn", "ro", "he", "ms", "tl", "ja", "hi", "my", "ko", "cs", "pt", "nl", "sv", "bn", "no", "lt", "el", "sr", "da"],
        "ids": {
            "all": 370890607,
            "en": 955190069,
            "pt-br": 494197461,
            "ru": 1050814052,
            "fr": 380505196,
            "es-419": 296390197,
            "pl": 242913014,
            "tr": 507059585,
            "it": 851891714,
            "es": 115169439,
            "id": 719269008,
            "hu": 719759654,
            "vi": 301477894,
            "zh-hk": 113594984,
            "ar": 602472856,
            "de": 401493183,
            "zh": 752155292,
            "ca": 1069764002,
            "bg": 678531099,
            "th": 311480598,
            "fa": 141560456,
            "uk": 8261465,
            "mn": 565474938,
            "ro": 533803532,
            "he": 459976450,
            "ms": 375702775,
            "tl": 737984097,
            "ja": 796489006,
            "hi": 683471552,
            "my": 778623467,
            "ko": 1065236294,
            "cs": 422767524,
            "pt": 678647945,
            "nl": 698202010,
            "sv": 359879447,
            "bn": 532878423,
            "no": 481504622,
            "lt": 112887841,
            "el": 824905526,
            "sr": 373675453,
            "da": 574420905
        },
        "baseUrl": "https://comick.io",
        "apiUrl": "https://api.comick.fun",
        "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.comick.png",
        "typeSource": "single",
        "itemType": 0,
        "version": "0.0.85",
        "pkgPath": "manga/src/all/comick.js"
    }];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }
    getHeaders(url) {
        return {
            "Referer": `${this.source.baseUrl}/`,
            'User-Agent':
                "Tachiyomi Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:110.0) Gecko/20100101 Firefox/110.0"
        };
    }

    async getPopular(page) {
        const url = `${this.source.apiUrl}/v1.0/search?sort=follow&page=${page}&tachiyomi=true`;
        const res = await this.client.get(url, this.getHeaders());
        return this.mangaRes(res.body);
    }

    async getLatestUpdates(page) {
        const url = `${this.source.apiUrl}/v1.0/search?sort=uploaded&page=${page}&tachiyomi=true`;
        const res = await this.client.get(url, this.getHeaders());
        return this.mangaRes(res.body);
    }
    async search(query, page, filterList) {
        let url = `${this.source.apiUrl}/v1.0/search`;

        if (query) {
            url += `?q=${encodeURIComponent(query)}&tachiyomi=true`;
        } else {
            filterList.forEach(filter => {
                if (filter.type === "CompletedFilter" && filter.state) {
                    url += `${this.ll(url)}completed=true`;
                } else if (filter.type === "GenreFilter") {
                    const included = filter.state.filter(e => e.state === 1);
                    const excluded = filter.state.filter(e => e.state === 2);
                    included.forEach(val => url += `${this.ll(url)}genres=${val.value}`);
                    excluded.forEach(val => url += `${this.ll(url)}excludes=${val.value}`);
                } else if (filter.type === "DemographicFilter") {
                    const included = filter.state.filter(e => e.state === 1);
                    included.forEach(val => url += `${this.ll(url)}demographic=${val.value}`);
                } else if (filter.type === "TypeFilter") {
                    const country = filter.state.filter(e => e.state);
                    country.forEach(coun => url += `${this.ll(url)}country=${coun.value}`);
                } else if (filter.type === "SortFilter") {
                    url += `${this.ll(url)}sort=${filter.values[filter.state].value}`;
                } else if (filter.type === "StatusFilter") {
                    url += `${this.ll(url)}status=${filter.values[filter.state].value}`;
                } else if (filter.type === "CreatedAtFilter" && filter.state > 0) {
                    url += `${this.ll(url)}time=${filter.values[filter.state].value}`;
                } else if (filter.type === "MinimumFilter" && filter.state) {
                    url += `${this.ll(url)}minimum=${filter.state}`;
                } else if (filter.type === "FromYearFilter" && filter.state) {
                    url += `${this.ll(url)}from=${filter.state}`;
                } else if (filter.type === "ToYearFilter" && filter.state) {
                    url += `${this.ll(url)}to=${filter.state}`;
                } else if (filter.type === "TagFilter" && filter.state) {
                    const tags = filter.state.split(",");
                    tags.forEach(tag => url += `${this.ll(url)}tags=${tag}`);
                }
            });
            url += `&page=${page}&tachiyomi=true`;
        }
        const res = await this.client.get(url, this.getHeaders());
        return this.mangaRes(res.body);
    }

    async getDetail(url) {
        const apiUrl = `${this.source.apiUrl}${url.replace("#", "")}?tachiyomi=true`;
        const res = await this.client.get(apiUrl, this.getHeaders());
        const data = JSON.parse(res.body);
        const lang = this.source.lang != "all" ? `&lang=${this.source.lang}` : "";
        const chapUrlReq =
            `${this.source.apiUrl}${url.replaceAll("#", '')}chapters?${lang}&tachiyomi=true&page=1`;
        const total = JSON.parse((await this.client.get(chapUrlReq, this.getHeaders())).body).total;
        const newChapUrlReq =
            `${this.source.apiUrl}${url.replaceAll("#", '')}chapters?limit=${parseInt(total, 10)}${lang}&tachiyomi=true&page=1`;
        const newRes = await this.client.get(newChapUrlReq, this.getHeaders());
        const chapters = JSON.parse(newRes.body).chapters.map(chapter => {
            let title = "";
            let scanlator = "";

            if (chapter.chap !== "null" && chapter.vol !== "null") {
                title = this.beautifyChapterName(
                    chapter.vol,
                    chapter.chap,
                    chapter.title
                );
            } else {
                title = chapter.title;
            }

            if (chapter.group_name !== "null") {
                scanlator = chapter.group_name
                    .toString()
                    .replace(/]/g, "")
                    .replace(/\[/g, "");
            }

            return {
                name: title,
                url: chapter.hid,
                scanlator: scanlator ?? "",
                dateUpload: new Date(chapter.created_at).valueOf().toString(),
            };
        });

        return {
            author: data.authors?.map(author => author.name).join(', '),
            description: data.comic.desc,
            genres: Array.from(data.comic.md_comic_md_genres.map(g => g.md_genres.name)),
            status: { "1": 0, "2": 1, "3": 3, "4": 2 }[data.comic.status],
            chapters
        };
    }

    async getPageList(url) {
        const apiUrl = `${this.source.apiUrl}/chapter/${url}?tachiyomi=true`;
        const res = await this.client.get(apiUrl, this.getHeaders());
        const data = JSON.parse(res.body);
        return data.chapter.images.map(image => ({
            url: image.url
        }));
    }
    getFilterList() {
        return [
            {
                type_name: "HeaderFilter",
                name: "The filter is ignored when using text search.",
            },
            {
                type_name: "GroupFilter",
                type: "GenreFilter",
                name: "Genre",
                state: [
                    ["4-Koma", "4-koma"],
                    ["Action", "action"],
                    ["Adaptation", "adaptation"],
                    ["Adult", "adult"],
                    ["Adventure", "adventure"],
                    ["Aliens", "aliens"],
                    ["Animals", "animals"],
                    ["Anthology", "anthology"],
                    ["Award Winning", "award-winning"],
                    ["Comedy", "comedy"],
                    ["Cooking", "cooking"],
                    ["Crime", "crime"],
                    ["Crossdressing", "crossdressing"],
                    ["Delinquents", "delinquents"],
                    ["Demons", "demons"],
                    ["Doujinshi", "doujinshi"],
                    ["Drama", "drama"],
                    ["Ecchi", "ecchi"],
                    ["Fan Colored", "fan-colored"],
                    ["Fantasy", "fantasy"],
                    ["Full Color", "full-color"],
                    ["Gender Bender", "gender-bender"],
                    ["Genderswap", "genderswap"],
                    ["Ghosts", "ghosts"],
                    ["Gore", "gore"],
                    ["Gyaru", "gyaru"],
                    ["Harem", "harem"],
                    ["Historical", "historical"],
                    ["Horror", "horror"],
                    ["Incest", "incest"],
                    ["Isekai", "isekai"],
                    ["Loli", "loli"],
                    ["Long Strip", "long-strip"],
                    ["Mafia", "mafia"],
                    ["Magic", "magic"],
                    ["Magical Girls", "magical-girls"],
                    ["Martial Arts", "martial-arts"],
                    ["Mature", "mature"],
                    ["Mecha", "mecha"],
                    ["Medical", "medical"],
                    ["Military", "military"],
                    ["Monster Girls", "monster-girls"],
                    ["Monsters", "monsters"],
                    ["Music", "music"],
                    ["Mystery", "mystery"],
                    ["Ninja", "ninja"],
                    ["Office Workers", "office-workers"],
                    ["Official Colored", "official-colored"],
                    ["Oneshot", "oneshot"],
                    ["Philosophical", "philosophical"],
                    ["Police", "police"],
                    ["Post-Apocalyptic", "post-apocalyptic"],
                    ["Psychological", "psychological"],
                    ["Reincarnation", "reincarnation"],
                    ["Reverse Harem", "reverse-harem"],
                    ["Romance", "romance"],
                    ["Samurai", "samurai"],
                    ["School Life", "school-life"],
                    ["Sci-Fi", "sci-fi"],
                    ["Sexual Violence", "sexual-violence"],
                    ["Shota", "shota"],
                    ["Shoujo Ai", "shoujo-ai"],
                    ["Shounen Ai", "shounen-ai"],
                    ["Slice of Life", "slice-of-life"],
                    ["Smut", "smut"],
                    ["Sports", "sports"],
                    ["Superhero", "superhero"],
                    ["Supernatural", "supernatural"],
                    ["Survival", "survival"],
                    ["Thriller", "thriller"],
                    ["Time Travel", "time-travel"],
                    ["Traditional Games", "traditional-games"],
                    ["Tragedy", "tragedy"],
                    ["User Created", "user-created"],
                    ["Vampires", "vampires"],
                    ["Video Games", "video-games"],
                    ["Villainess", "villainess"],
                    ["Virtual Reality", "virtual-reality"],
                    ["Web Comic", "web-comic"],
                    ["Wuxia", "wuxia"],
                    ["Yaoi", "yaoi"],
                    ["Yuri", "yuri"],
                    ["Zombies", "zombies"]
                ].map(x => ({ type_name: 'TriState', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                type: "DemographicFilter",
                name: "Demographic",
                state: [
                    ["Shounen", "1"],
                    ["Shoujo", "2"],
                    ["Seinen", "3"],
                    ["Josei", "4"]
                ].map(x => ({ type_name: 'TriState', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                type: "TypeFilter",
                name: "Type",
                state: [
                    ["Manga", "jp"],
                    ["Manhwa", "kr"],
                    ["Manhua", "cn"]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "SortFilter",
                name: "Sort",
                state: 0,
                values: [
                    ["Most popular", "follow"],
                    ["Most follows", "user_follow_count"],
                    ["Most views", "view"],
                    ["High rating", "rating"],
                    ["Last updated", "uploaded"],
                    ["Newest", "created_at"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "StatusFilter",
                name: "Status",
                state: 0,
                values: [
                    ["All", "0"],
                    ["Ongoing", "1"],
                    ["Completed", "2"],
                    ["Cancelled", "3"],
                    ["Hiatus", "4"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: 'CheckBox',
                type: "CompletedFilter",
                name: "Completely Scanlated?",
                value: ""
            },
            {
                type_name: "SelectFilter",
                type: "CreatedAtFilter",
                name: "Created at",
                state: 0,
                values: [
                    ["", ""],
                    ["3 days", "3"],
                    ["7 days", "7"],
                    ["30 days", "30"],
                    ["3 months", "90"],
                    ["6 months", "180"],
                    ["1 year", "365"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "TextFilter",
                type: "MinimumFilter",
                name: "Minimum Chapters",
            },
            {
                type_name: "HeaderFilter",
                name: "From Year, ex: 2010",
            },
            {
                type_name: "TextFilter",
                type: "FromYearFilter",
                name: "From",
            },
            {
                type_name: "HeaderFilter",
                name: "To Year, ex: 2021",
            },
            {
                type_name: "TextFilter",
                type: "ToYearFilter",
                name: "To",
            },
            {
                type_name: "HeaderFilter",
                name: "Separate tags with commas",
            },
            {
                type_name: "TextFilter",
                type: "TagFilter",
                name: "Tags",
            },
        ];
    }
    mangaRes(body) {
        body = JSON.parse(body);
        return {
            list: body.map(manga => ({
                name: manga.title,
                imageUrl: manga.cover_url,
                link: `/comic/${manga.hid}/#`
            })),
            hasNextPage: body.hasNextPage || false
        };
    }
    beautifyChapterName(vol, chap, title) {
        let result = "";

        if (vol && vol.trim() !== "") {
            if (chap && chap.trim() === "") {
                result += `Volume ${vol} `;
            } else {
                result += `Vol. ${vol} `;
            }
        }

        if (chap && chap.trim() !== "") {
            if (vol && vol.trim() === "") {
                result += `Chapter ${chap}`;
            } else {
                result += `Ch. ${chap} `;
            }
        }

        if (title && title.trim() !== "") {
            if (chap && chap.trim() === "") {
                result += title;
            } else {
                result += ` : ${title}`;
            }
        }

        return result;
    }

    ll(url) {
        return url.includes("?") ? "&" : "?";
    }
}

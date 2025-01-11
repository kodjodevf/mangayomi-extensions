const mangayomiSources = [{
    "name": "Sudatchi",
    "lang": "en",
    "baseUrl": "https://sudatchi.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://sudatchi.com",
    "typeSource": "single",
    "isManga": null,
    "version": "0.0.2",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/en/sudatchi.js"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        return {
            "Referer": this.source.baseUrl,
        }
    }

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }

    getImgUrl(slug) {
        return `https://ipfs.sudatchi.com/ipfs/${slug}`
    }

    async extractFromUrl(url) {
        var res = await new Client().get(url, this.getHeaders());
        var doc = new Document(res.body);
        var jsonData = doc.selectFirst("#__NEXT_DATA__").text
        return JSON.parse(jsonData).props.pageProps;
    }


    async formListFromHome(animes) {
        var list = []
        var lang = this.getPreference("sudatchi_pref_lang")
        for (var item of animes) {
            var details = "Anime" in item ? item.Anime : item
            var name = details.titleRomanji
            switch (lang) {
                case "e": {
                    name = "titleEnglish" in details ? details.titleEnglish : name;
                    break;
                }
                case "j": {
                    name = "titleJapanese" in details ? details.titleJapanese : name;
                    break;
                }

            }
            var link = details.slug
            var imageUrl = this.getImgUrl(details.imgUrl)
            list.push({
                name,
                imageUrl,
                link
            });
        }
        return list;
    }

    async getPopular(page) {
        var pageProps = await this.extractFromUrl(this.source.baseUrl)
        //  var  = extract
        var latestEpisodes = await this.formListFromHome(pageProps.latestEpisodes)
        var latestAnimes = await this.formListFromHome(pageProps.latestAnimes)
        var newAnimes = await this.formListFromHome(pageProps.newAnimes)
        var animeSpotlight = await this.formListFromHome(pageProps.AnimeSpotlight)
        var list = [...animeSpotlight, ...latestAnimes, ...latestEpisodes, ...newAnimes]
        return {
            list,
            hasNextPage: false
        };
    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        var extract = await this.extractFromUrl(this.source.baseUrl)
        var latest = extract.props.pageProps.latestEpisodes
        var list = await this.formListFromHome(latest)

        return {
            list,
            hasNextPage: false
        };
    }
    async search(query, page, filters) {
        var type = '';
        for (var filter of filters[0].state) if (filter.state) type += `,${filter.value}`;
        var status = '';
        for (var filter of filters[1].state) if (filter.state) status += `,${filter.value}`;
        var genre = '';
        for (var filter of filters[2].state) if (filter.state) genre += `,${filter.value}`;
        var year = '';
        for (var filter of filters[3].state) if (filter.state) year += `,${filter.value}`;

        var api = `https://sudatchi.com/api/directory?page=${page}&genres=${genre}&years=${year}&types=${type}&status=${status}&title=${query}&category=`
        var response = await new Client().get(api);
        var body = JSON.parse(response.body);

        var list = await this.formListFromHome(body.animes)
        var hasNextPage = body.pages > page ? true : false;

        return {
            list,
            hasNextPage
        };
    }

    statusCode(status) {
        return {
            "Currently Airing": 0,
            "Finished Airing": 1,
            "Hiatus": 2,
            "Discontinued": 3,
            "Not Yet Released": 4,
        }[status] ?? 5;
    }

    async getDetail(url) {
        var link = `https://sudatchi.com/anime/${url}`
        var jsonData = await this.extractFromUrl(link);
        var details = jsonData.animeData
        var name = details.titleRomanji
        var lang = this.getPreference("sudatchi_pref_lang")
        switch (lang) {
            case "e": {
                name = "titleEnglish" in details ? details.titleEnglish : name;
                break;
            }
            case "j": {
                name = "titleJapanese" in details ? details.titleJapanese : name;
                break;
            }
        }
        var description = details.synopsis
        var status = this.statusCode(details.Status.name)
        var imageUrl = this.getImgUrl(details.imgUrl)
        var genre = []
        var animeGenres = details.AnimeGenres
        for (var gObj of animeGenres) {
            genre.push(gObj.Genre.name)
        }

        var chapters = []
        var episodes = details.Episodes

        for (var eObj of episodes) {
            var name = eObj.title
            var number = eObj.number
            var epUrl = `${url}/${number}`
            chapters.push({ name, url: epUrl })
        }


        return { name, description, status, imageUrl, genre, chapters }

    }
    // For novel html content
    async getHtmlContent(url) {
        throw new Error("getHtmlContent not implemented");
    }
    // Clean html up for reader
    async cleanHtmlContent(html) {
        throw new Error("cleanHtmlContent not implemented");
    }
    // For anime episode video list
    async getVideoList(url) {
        throw new Error("getVideoList not implemented");
    }
    // For manga chapter pages
    async getPageList() {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        var currentYear = new Date().getFullYear();
        var formattedYears = Array.from({ length: currentYear - 2003 }, (_, i) => (i + 2004).toString()).map(year => ({ type_name: 'CheckBox', name: year, value: year }));

        return [
            {
                type_name: "GroupFilter",
                name: "Type",
                state: [
                    ["All", ""],
                    ["BD", "BD"],
                    ["Movie", "Movie"],
                    ["ONA", "ONA"],
                    ["OVA", "OVA"],
                    ["Special", "Special"],
                    ["TV", "TV"]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                name: "Status",
                state: [
                    ["All", ""],
                    ["Currently Airing", "Currently Airing"],
                    ["Finished Airing", "Finished Airing"],
                    ["Hiatus", "Hiatus"],
                    ["Not Yet Released", "Not Yet Released"]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            }, {
                type_name: "GroupFilter",
                name: "Genre",
                state: [
                    ["Action", "Action"],
                    ["Adventure", "Adventure"],
                    ["Comedy", "Comedy"],
                    ["Cyberpunk", "Cyberpunk"],
                    ["Demons", "Demons"],
                    ["Drama", "Drama"],
                    ["Ecchi", "Ecchi"],
                    ["Fantasy", "Fantasy"],
                    ["Harem", "Harem"],
                    ["Hentai", "Hentai"],
                    ["Historical", "Historical"],
                    ["Horror", "Horror"],
                    ["Isekai", "Isekai"],
                    ["Josei", "Josei"],
                    ["Magic", "Magic"],
                    ["Martial Arts", "Martial Arts"],
                    ["Mecha", "Mecha"],
                    ["Military", "Military"],
                    ["Music", "Music"],
                    ["Mystery", "Mystery"],
                    ["Police", "Police"],
                    ["Post-Apocalyptic", "Post-Apocalyptic"],
                    ["Psychological", "Psychological"],
                    ["Romance", "Romance"],
                    ["School", "School"],
                    ["Sci-Fi ", "Sci-Fi "],
                    ["Seinen", "Seinen"],
                    ["Shoujo", "Shoujo"],
                    ["Shounen", "Shounen"],
                    ["Slice of Life", "Slice of Life"],
                    ["Space", "Space"],
                    ["Sports", "Sports"],
                    ["Super Power", "Super Power"],
                    ["Supernatural", "Supernatural"],
                    ["Thriller", "Thriller"],
                    ["Tragedy", "Tragedy"],
                    ["Vampire", "Vampire"],
                    ["Yaoi", "Yaoi"],
                    ["Yuri", "Yuri"]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            }, {
                type_name: "GroupFilter",
                name: "Year",
                state: formattedYears
            },

        ];
    }
    getSourcePreferences() {
        return [{
            key: 'sudatchi_pref_lang',
            listPreference: {
                title: 'Preferred title language',
                summary: '',
                valueIndex: 0,
                entries: ["Romanji", "English", "Japanese"],
                entryValues: ["r", "e", "j"]
            }
        },]
    }
}

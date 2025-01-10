const mangayomiSources = [{
    "name": "Sudatchi",
    "lang": "en",
    "baseUrl": "https://sudatchi.com",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://sudatchi.com",
    "typeSource": "single",
    "isManga": null,
    "version": "0.0.1",
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
        return JSON.parse(jsonData);
    }

    async formList(latestEpisodes) {
        var list = []
        for (var item of latestEpisodes) {
            var details = "Anime" in item ? item.Anime : item
            var lang = this.getPreference("sudatchi_pref_lang")
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
        var extract = await this.extractFromUrl(this.source.baseUrl)
        var pageProps = extract.props.pageProps
        var latestEpisodes = await this.formList(pageProps.latestEpisodes)
        var latestAnimes = await this.formList(pageProps.latestAnimes)
        var newAnimes = await this.formList(pageProps.newAnimes)
        var animeSpotlight = await this.formList(pageProps.AnimeSpotlight)
        var list = [...animeSpotlight, ...newAnimes, ...latestAnimes, ...latestEpisodes]
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
        var list = await this.formList(latest)

        return {
            list,
            hasNextPage: false
        };
    }
    async search(query, page, filters) {
        throw new Error("search not implemented");
    }
    async getDetail(url) {
        throw new Error("getDetail not implemented");
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
        throw new Error("getFilterList not implemented");
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

const mangayomiSources = [{
    "name": "AnimeZ",
    "lang": "en",
    "baseUrl": "https://animez.org",
    "apiUrl": "",
    "iconUrl": "https://www.google.com/s2/favicons?sz=256&domain=https://animez.org/",
    "typeSource": "multi",
    "itemType": 1,
    "version": "0.0.1",
    "pkgPath": "anime/src/en/animez.js"
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    getHeaders(url) {
        return {
            "Referer": this.source.baseUrl,
        }
    }

    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    async request(slug) {
        var url = this.source.baseUrl + slug
        var res = await this.client.get(url, this.getHeaders());
        return new Document(res.body);
    }
    async page(slug) {
        var body = await this.request(slug)
        var list = []
        var hasNextPage = false;

        var animes = body.select("li.TPostMv")
        animes.forEach(anime => {
            var link = anime.selectFirst("a").getHref
            var name = anime.selectFirst('h2.Title').text;
            var imageUrl = this.source.baseUrl + anime.selectFirst('img').getSrc;

            list.push({ name, link, imageUrl });
        });

        var paginations = body.select(".pagination > li")
        hasNextPage = paginations[paginations.length - 1].text == "Last" ? true : false

        return { list, hasNextPage }
    }

    sortByPref(key){
        var sort = parseInt(this.getPreference(key))
        var sortBy = "hot"
        switch(sort){
            case 1:{
                sortBy = "lastest-chap"
                break;
            }case 2:{
                sortBy = "hot"
                break;
            }
            case 3:{
                sortBy = "lastest-manga"
                break;
            }
            case 4:{
                sortBy = "top-manga"
                break;
            }
            case 5:{
                sortBy = "top-month"
                break;
            }
            case 6:{
                sortBy = "top-week"
                break;
            }
            case 7:{
                sortBy = "top-day"
                break;
            }
            case 8:{
                sortBy = "follow"
                break;
            }
            case 9:{
                sortBy = "comment"
                break;
            }
            case 10:{
                sortBy = "num-chap"
                break;
            }
        }
        return sortBy;

    }

    async getPopular(page) {
        var sortBy = this.sortByPref("animez_pref_popular_section")
        var slug = `/?act=search&f[status]=all&f[sortby]=${sortBy}&&pageNum=${page}`
        return await this.page(slug)

    }
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    async getLatestUpdates(page) {
        var sortBy = this.sortByPref("animez_pref_latest_section")
        var slug = `/?act=search&f[status]=all&f[sortby]=${sortBy}&&pageNum=${page}`
        return await this.page(slug)
    }
    async search(query, page, filters) {
        var slug = `/?act=search&f[status]=all&f[keyword]=${query}&&pageNum=${page}`
        return await this.page(slug)
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
    async getPageList(url) {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    getSourcePreferences() {
        return [{
            key: 'animez_pref_popular_section',
            listPreference: {
                title: 'Preferred popular content',
                summary: '',
                valueIndex: 1,
                entries: ["Latest update", "Hot", "New releases", "Top all","Top month","Top week","Top day","Top follow","Top comments","Number of episodes"],
                entryValues: ["1", "2" ,"3", "4","5","6","7","8","9","10"]
            }
        },{
            key: 'animez_pref_latest_section',
            listPreference: {
                title: 'Preferred latest content',
                summary: '',
                valueIndex: 0,
                entries: ["Latest update", "Hot", "New releases", "Top all","Top month","Top week","Top day","Top follow","Top comments","Number of episodes"],
                entryValues: ["1", "2" ,"3", "4","5","6","7","8","9","10"]
            }
        },]
    }
}

const mangayomiSources = [{
    "name": "VIVAMAXph",
    "lang": "all",
    "baseUrl": "https://vivamaxph.com/",
    "apiUrl": "",
    "iconUrl": "https://vivamaxph.com/wp-content/uploads/2024/02/logo2-1.png",
    "typeSource": "single",
    "isManga": false,
    "isNsfw": true,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/all/vivamaxph.js"
}];

class DefaultExtension extends MProvider {
    async getPopular(page) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(`${baseUrl}/page/${page}/?filter=most-viewed`);
        const elements = new Document(res.body).select("article");
        const list = [];          
        for (const element of elements){ 
            const linkElement = element.selectFirst("a");        
            const name = element.selectFirst("a").attr("title");
            const imageUrl = linkElement.selectFirst("img").attr("data-src");            
            const link = element.selectFirst("a").attr("href");                
            if (name && imageUrl && link) {
                list.push({ name, imageUrl, link });
            }
        }
        return {
            list: list,
            hasNextPage: true
        }
    }
    async getLatestUpdates(page) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(`${baseUrl}/page/${page}/?filter=latest`);
        const elements = new Document(res.body).select("article");
        const list = [];          
        for (const element of elements){ 
            const linkElement = element.selectFirst("a");        
            const name = element.selectFirst("a").attr("title");
            const imageUrl = linkElement.selectFirst("img").attr("data-src");            
            const link = element.selectFirst("a").attr("href");                
            if (name && imageUrl && link) {
                list.push({ name, imageUrl, link });
            }
        }
        return {
            list: list,
            hasNextPage: true
        };
    }
    async search(query, page, filters) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(`${baseUrl}?s=${query}`);
        // console.log(res.body);
        const elements = new Document(res.body).select("article");
        const list = [];          
        for (const element of elements){ 
            const linkElement = element.selectFirst("a");        
            const name = element.selectFirst("a").attr("title");
            const imageUrl = linkElement.selectFirst("img").attr("data-src");            
            const link = element.selectFirst("a").attr("href");                
            if (name && imageUrl && link) {
                list.push({ name, imageUrl, link });
            }
        }
        return {
            list: list,
            hasNextPage: false
        };
    }
    
    async getDetail(url) {
        const baseUrl = this.source.baseUrl;
        const res = await new Client().get(url);
        const elements = new Document(res.body);
        const movieURL = elements.selectFirst("meta[property='og:url']").attr("content"); 
        const episodes = [] 
        let episode = {
            "name": "movie",
            "url": `${movieURL}`
        }
        episodes.push(episode)
        const name = elements.selectFirst("h1[itemprop='name']").text
        const imageUrl = elements.selectFirst("meta[property='og:image']").attr("content");
        return {
            name, imageUrl,  episodes
        };  
    }
    // For anime episode video list
    async getVideoList(url) {
        const res = await new Client().get(url);
        const elements = new Document(res.body);
        const videos = []
        const redirectgs = elements.selectFirst("iframe").attr("src");
        const body = (await new Client().get(redirectgs)).body;
        const quality = "DoodStream";        
        const vids = await doodExtractor(redirectgs, quality);
        for (const vid of vids) {
            videos.push(vid);
        }
      return videos;                        
    }
    // For manga chapter pages
    async getPageList() {
        throw new Error("getPageList not implemented");
    }
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

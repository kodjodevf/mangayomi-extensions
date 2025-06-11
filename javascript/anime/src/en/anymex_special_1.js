const mangayomiSources = [{
    "name": "AnymeX Special #1",
    "lang": "en",
    "baseUrl": "https://xprime.tv",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/RyanYuuki/AnymeX/main/assets/images/logo.png",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.0.1",
    "pkgPath": ""
}];

class DefaultExtension extends MProvider {
    
    constructor() {
        super();
        this.client = new Client();
    }
    
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }
    
    mapToManga(dataArr, isMovie) {
        var type = isMovie ? "movie" : "tv";    
        return dataArr.map((e) => {
            return {
                name: e.title ?? e.name,
                link: `https://tmdb.hexa.watch/api/tmdb/${type}/${e.id}`,
                imageUrl: "https://image.tmdb.org/t/p/w500" + (e.poster_path ?? e.backdrop_path),
                description: e.overview,
            };
        });
    }

    async requestSearch(query, isMovie) {
        const type = isMovie ? "movie" : "tv";
        const url = `https://tmdb.hexa.watch/api/tmdb/search/${type}?language=en-US&query=${encodeURIComponent(query)}&page=1&include_adult=false`;

        const resp = await this.client.get(url);
        const data = JSON.parse(resp.body);
        return data;
    }
    
    async getPopular(page) {
        throw new Error("getPopular not implemented");
    }
    
    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }
    
    async getLatestUpdates(page) {
        throw new Error("getLatestUpdates not implemented");
    }

    async search(query, page = 1, filters) {
        try {
            const [movieData, seriesData] = await Promise.all([
                this.requestSearch(query, true),
                this.requestSearch(query, false)
            ]);

            const movies = this.mapToManga(movieData.results || [], true);
            const series = this.mapToManga(seriesData.results || [], false);
            
            console.log(series);

            const maxLength = Math.max(movies.length, series.length);
            const mixedResults = [];

            for (let i = 0; i < maxLength; i++) {
                if (i < movies.length) mixedResults.push(movies[i]);
                if (i < series.length) mixedResults.push(series[i]);
            }

            return {
                list: mixedResults,
                hasNextPage: false
            };
        } catch (error) {
            console.error('Search error:', error);
            throw error;
        }
    }

    async getDetail(url) {
        const resp = await this.client.get(url);
        const parsedData = JSON.parse(resp.body);
        const isMovie = url.includes('movie');

        const name = parsedData.name ?? parsedData.title;
        const chapters = [];

        const idMatch = url.match(/(?:movie|tv)\/(\d+)/);
        const tmdbId = idMatch ? idMatch[1] : null;

        if (!tmdbId) throw new Error("Invalid TMDB ID in URL");

        if (isMovie) {
            const releaseDate = parsedData.release_date;
            chapters.push({
                name: 'Movie',
                url: `movie/${name}/${releaseDate.split('-')[0]}/${tmdbId}`
            });
        } else {
            const seasons = parsedData.seasons || [];

            for (const season of seasons) {
                if (season.season_number === 0) continue;

                const episodeCount = season.episode_count;

                for (let ep = 1; ep <= episodeCount; ep++) {
                    chapters.push({
                        name: `S${season.season_number} · E${ep}`,
                        url: `tv/${name}/${season.air_date.split('-')[0]}/${tmdbId}/${season.season_number}/${ep}`
                    });
                }
            }
        }

        return {
            name,
            chapters
        };
    }

    // For novel html content
    async getHtmlContent(url) {
        throw new Error("getHtmlContent not implemented");
    }
    
    // Clean html up for reader
    async cleanHtmlContent(html) {
        throw new Error("cleanHtmlContent not implemented");
    }

    async getVideoList(url) {
        const splitParts = url.split('/');
        const isMovie = url.includes('movie');

        const title = decodeURIComponent(splitParts[1]); 
        const releaseDate = splitParts[2];
        const id = splitParts[3];

        let newUrl = `https://backend.xprime.tv/primebox?name=${encodeURIComponent(title)}&fallback_year=${releaseDate}&id=${id}`;

        if (!isMovie) {
            const season = splitParts[4];
            const episode = splitParts[5];
            newUrl += `&season=${season}&episode=${episode}`;
        }

        const resp = await this.client.get(newUrl);
        const data = JSON.parse(resp.body);
        console.log(data);
        
        var result = Object.entries(data.streams).map(([quality, url]) => ({
            url,
            quality,
            originalUrl: url,
            subtitles: data.subtitles?.map(sub => ({
                file: sub.file,
                label: sub.label
            })) || []
        }));
        
        return result;
    }

    // For manga chapter pages
    async getPageList(url) {
        throw new Error("getPageList not implemented");
    }
    
    getFilterList() {
        throw new Error("getFilterList not implemented");
    }
    
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}
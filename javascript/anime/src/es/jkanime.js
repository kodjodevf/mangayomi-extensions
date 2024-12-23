const mangayomiSources = [{
    "name": "JKAnime",
    "lang": "es",
    "baseUrl": "https://jkanime.net",
    "apiUrl": "",
    "iconUrl": "https://cdn.jkanime.net/logo_jk.png",
    "typeSource": "single",
    "itemType": 1,
    "version": "0.1.13",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/es/jkanime.js"
}];

class DefaultExtension extends MProvider {
    constructor () {
        super();
        this.client = new Client();
    }
    getHeaders(url) {
        throw new Error("getHeaders not implemented");
    }
    async parseAnimeList(url) {
        const res = await this.client.get(url);
        const doc = new Document(res.body);
        const code = doc.selectFirst("script:contains(var animes)").text;
        const list = [];

        for (const element of code.matchAll(/{.*?short_title.*?}/g)) {
            const data = JSON.parse(element[0]);
            const name = data.title;
            const imageUrl = data.image;
            const link = this.source.baseUrl + '/' + data.slug;
            list.push({ name, imageUrl, link });
        }
        
        const nextBtn = doc.selectFirst("a.nav-next");
        const hasNextPage = nextBtn && nextBtn.text != '';
        return { "list": list, "hasNextPage": hasNextPage };
    }
    statusFromString(status) {
        return {
            "En emision": 0,
            "Finalizado": 1,
            "Concluido": 1
        }[status] ?? 5;
    }
    async getPopular(page) {
        const res = await this.client.get('https://jkanime.net/top/');
        const doc = new Document(res.body);
        const list = [];

        for (const i of doc.select('div#conb')) {
            const name = i.selectFirst('h2 a').text;
            const imageUrl = i.selectFirst('img').getSrc;
            let link = i.selectFirst('a').getHref;
            link = link.endsWith('/') ? link.slice(0, -1) : link;
            list.push({ name, imageUrl, link });
        }

        return { "list": list, "hasNextPage": false };
    }
    async getLatestUpdates(page) {
        return await this.parseAnimeList(`${this.source.baseUrl}/directorio/${page}/`);
    }
    async search(query, page, filters) {
        query = query.trim().replaceAll(/\ +/g, "_");

        // Search sometimes failed because filters were empty. I experienced this mostly on android...
        if (!filters || filters.length == 0) {
            return this.parseAnimeList(`${this.source.baseUrl}/buscar/${query}/${page}/`);
        } else if (query) {
            var url = `${this.source.baseUrl}/buscar/${query}/${page}/`;
            url += `?filtro=${filters[1].values[filters[1].state].value}`;
            url += `&tipo=${filters[5].values[filters[5].state].value}`;
            url += `&estado=${filters[6].values[filters[6].state].value}`;
        } else {
            var url = `${this.source.baseUrl}/directorio/${query}/${page}`;
            url += `/${filters[1].values[filters[1].state].value}`;
            url += `/${filters[2].values[filters[2].state].value}`;
            url += `/${filters[3].values[filters[3].state].value}`;
            url += `/${filters[4].values[filters[4].state].value}`;
            url += `/${filters[5].values[filters[5].state].value}`;
            url += `/${filters[6].values[filters[6].state].value}`;
            url += `/${filters[7].values[filters[7].state].value}`;
            url += `/${filters[8].values[filters[8].state].value}`;
        }        
        return await this.parseAnimeList(url);
    }
    async getDetail(url) {
        let res = await this.client.get(url);
        const doc = new Document(res.body);
        const detail = {};

        const id = res.body.match(/data-anime="(\d+)"/)[1];
        const lastEpisodeUrl = `${this.source.baseUrl}/ajax/last_episode/${id}`;

        const info = doc.selectFirst("div.anime__details__content");
        const extInfo = doc.selectFirst('div.aninfo');
        detail.name = info.selectFirst("h3").text;
        detail.imageUrl = info.selectFirst("div.anime__details__pic").attr('data-setbg');
        detail.description = info.selectFirst("p.sinopsis").text.trim();
        detail.status = this.statusFromString(extInfo.selectFirst("span:contains(Estado) + span").text);
        detail.genre = extInfo.select("li:contains(Genero) a").map(e => e.text);
        detail.author = extInfo.select("li:contains(Studios) a").map(e => e.text).join(', ');

        // get episodes
        detail.episodes = [];
        res = await this.client.get(lastEpisodeUrl, {'User-Agent': 'Mangayomi'});
        const end = parseInt(JSON.parse(res.body)[0].number);
        for (let i = 1; i <= end; i++) {
            detail.episodes.push({
                name: 'Episodio ' + i,
                url: url + '/' + i
            });
        }
        detail.episodes.reverse();
        return detail;
    }
    async extractRedirect(redirect, referer, lang, type, host) {
        const res = await this.client.get(this.source.baseUrl + redirect, {'Referer': referer});
        const m3u = res.body.match(/http.*?.m3u8/)[0];
        return [{ url: m3u, originalUrl: m3u, headers: {'Referer': referer}, quality: `${lang} ${type} ${host}` }];
    };
    // For anime episode video list
    async getVideoList(url) {
        const res = await this.client.get(url);
        const doc = new Document(res.body);
        let promises = [];
        const videos = [];
        
        const code = doc.selectFirst("script:contains(var video)").text;

        // extract direct video links
        for (const m of code.matchAll(/video\s*\[\d+\].*?src="(.*?)"/g)) {
            promises.push(this.extractRedirect(m[1], url, 'Español', 'Sub', 'Desu'));
        }
        promises = [Promise.any(promises)];

        // extract remote video links
        for (const server of code.matchAll(/{"remote"\s*:\s*"(.*?)".*?"server"\s*:\s*"(.*?)"/g)) {
            const link = Uint8Array.fromBase64(server[1]).decode('utf-8');
            const host = server[2];
            promises.push(extractAny(link, host.toLowerCase(), 'Español', 'Sub', host));
        }
        for (const p of (await Promise.allSettled(promises))) {
            if (p.status == 'fulfilled') {
                videos.push.apply(videos, p.value);
            }
        }
        return sortVideos(videos);
    }
    getFilterList() {
        return [
            {
                type_name: "HeaderFilter",
                type: "info",
                name: "IMPORTANT: Some filters do not work when searching text!",
                state: 0
            },
            {
                type_name: "SelectFilter",
                type: "filtro",
                name: "Filtro",
                state: 0,
                values: [
                    ["Por fecha", ""],
                    ["Por nombre", "nombre"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "genero",
                name: "Género",
                state: 0,
                values: [
                    ["Género", ""],
                    ["Accion", "accion"],
                    ["Aventura", "aventura"],
                    ["Autos", "autos"],
                    ["Comedia", "comedia"],
                    ["Dementia", "dementia"],
                    ["Demonios", "demonios"],
                    ["Misterio", "misterio"],
                    ["Drama", "drama"],
                    ["Ecchi", "ecchi"],
                    ["Fantasia", "fantasia"],
                    ["Juegos", "juegos"],
                    ["Hentai", "hentai"],
                    ["Historico", "historico"],
                    ["Terror", "terror"],
                    ["Magia", "magia"],
                    ["Artes Marciales", "artes-marciales"],
                    ["Mecha", "mecha"],
                    ["Musica", "musica"],
                    ["Parodia", "parodia"],
                    ["Samurai", "samurai"],
                    ["Romance", "romance"],
                    ["Colegial", "colegial"],
                    ["Sci-Fi", "sci-fi"],
                    ["Shoujo Ai", "shoujo-ai"],
                    ["Shounen Ai", "shounen-ai"],
                    ["Space", "space"],
                    ["Deportes", "deportes"],
                    ["Super Poderes", "super-poderes"],
                    ["Vampiros", "vampiros"],
                    ["Yaoi", "yaoi"],
                    ["Yuri", "yuri"],
                    ["Harem", "harem"],
                    ["Cosas de la vida", "cosas-de-la-vida"],
                    ["Sobrenatural", "sobrenatural"],
                    ["Militar", "militar"],
                    ["Policial", "policial"],
                    ["Psicologico", "psicologico"],
                    ["Thriller", "thriller"],
                    ["Español Latino", "latino"],
                    ["Isekai", "isekai"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "demografia",
                name: "Demografía",
                state: 0,
                values: [
                    ["Demografía", ""],
                    ["Niños", "nios"],
                    ["Shoujo", "shoujo"],
                    ["Shounen", "shounen"],
                    ["Seinen", "seinen"],
                    ["Josei", "josei"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "categoria",
                name: "Categoría",
                state: 0,
                values: [
                    ["Categoría", ""],
                    ["Donghua", "donghua"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "tipo",
                name: "Tipo",
                state: 0,
                values: [
                    ["Tipo", ""],
                    ["Animes", "animes"],
                    ["Peliculas", "peliculas"],
                    ["Especiales", "especiales"],
                    ["Ovas", "ovas"],
                    ["Onas", "onas"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "estado",
                name: "Estado",
                state: 0,
                values: [
                    ["Estado", ""],
                    ["En emisión", "emision"],
                    ["Finalizado", "finalizados"],
                    ["Por Estrenar", "estrenos"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "ano",
                name: "Año",
                state: 0,
                values: [
                    ["Año", "Año"],
                    ["2024", "2024"],
                    ["2023", "2023"],
                    ["2022", "2022"],
                    ["2021", "2021"],
                    ["2020", "2020"],
                    ["2019", "2019"],
                    ["2018", "2018"],
                    ["2017", "2017"],
                    ["2016", "2016"],
                    ["2015", "2015"],
                    ["2014", "2014"],
                    ["2013", "2013"],
                    ["2012", "2012"],
                    ["2011", "2011"],
                    ["2010", "2010"],
                    ["2009", "2009"],
                    ["2008", "2008"],
                    ["2007", "2007"],
                    ["2006", "2006"],
                    ["2005", "2005"],
                    ["2004", "2004"],
                    ["2003", "2003"],
                    ["2002", "2002"],
                    ["2001", "2001"],
                    ["2000", "2000"],
                    ["1999", "1999"],
                    ["1998", "1998"],
                    ["1997", "1997"],
                    ["1996", "1996"],
                    ["1995", "1995"],
                    ["1994", "1994"],
                    ["1993", "1993"],
                    ["1992", "1992"],
                    ["1991", "1991"],
                    ["1990", "1990"],
                    ["1989", "1989"],
                    ["1988", "1988"],
                    ["1987", "1987"],
                    ["1986", "1986"],
                    ["1985", "1985"],
                    ["1984", "1984"],
                    ["1983", "1983"],
                    ["1982", "1982"],
                    ["1981", "1981"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "temporada",
                name: "Temporada",
                state: 0,
                values: [
                    ["Temporada", ""],
                    ["Invierno", "invierno"],
                    ["Primavera", "primavera"],
                    ["Verano", "verano"],
                    ["Otoño", "otoño"]
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            }
        ];
    }
    getSourcePreferences() {
        const languages = ['Español'];
        const types = ['Sub'];
        const resolutions = ['1080p', '720p', '480p'];
        const hosts = ['Desu', 'Filemoon', 'Mixdrop', 'Mp4upload', 'Streamtape', 'Streamwish', 'Vidhide', 'VOE'];

        return [
            {
                key: 'lang',
                listPreference: {
                    title: 'Preferred Language',
                    summary: 'If available, this language will be chosen by default. Priority = 0 (lower is better)',
                    valueIndex: 0,
                    entries: languages,
                    entryValues: languages
                }
            },
            {
                key: 'type',
                listPreference: {
                    title: 'Preferred Type',
                    summary: 'If available, this type will be chosen by default. Priority = 1 (lower is better)',
                    valueIndex: 0,
                    entries: types,
                    entryValues: types
                }
            },
            {
                key: 'res',
                listPreference: {
                    title: 'Preferred Resolution',
                    summary: 'If available, this resolution will be chosen by default. Priority = 2 (lower is better)',
                    valueIndex: 0,
                    entries: resolutions,
                    entryValues: resolutions
                }
            },
            {
                key: 'host',
                listPreference: {
                    title: 'Preferred Host',
                    summary: 'If available, this hoster will be chosen by default. Priority = 3 (lower is better)',
                    valueIndex: 0,
                    entries: hosts,
                    entryValues: hosts
                }
            }
        ];
    }
}

/***************************************************************************************************
* 
*   mangayomi-js-helpers v1.2
*       
*   # Video Extractors
*       - vidGuardExtractor
*       - doodExtractor
*       - vidozaExtractor
*       - okruExtractor
*       - amazonExtractor
*       - vidHideExtractor
*       - filemoonExtractor
*       - mixdropExtractor
*       - speedfilesExtractor
*       - luluvdoExtractor
*       - burstcloudExtractor (not working, see description)
*   
*   # Video Extractor Wrappers
*       - streamWishExtractor
*       - voeExtractor
*       - mp4UploadExtractor
*       - yourUploadExtractor
*       - streamTapeExtractor
*       - sendVidExtractor
*   
*   # Video Extractor helpers
*       - extractAny
*   
*   # Playlist Extractors
*       - m3u8Extractor
*       - jwplayerExtractor
*   
*   # Extension Helpers
*       - sortVideos()
*   
*   # Uint8Array
*       - Uint8Array.fromBase64()
*       - Uint8Array.prototype.toBase64()
*       - Uint8Array.prototype.decode()
*   
*   # String
*       - String.prototype.encode()
*       - String.decode()
*       - String.prototype.reverse()
*       - String.prototype.swapcase()
*       - getRandomString()
*
*   # Encode/Decode Functions
*       - decodeUTF8
*       - encodeUTF8
*   
*   # Url
*       - absUrl()
*
***************************************************************************************************/

//--------------------------------------------------------------------------------------------------
//  Video Extractors
//--------------------------------------------------------------------------------------------------

async function vidGuardExtractor(url) {
    // get html
    const res = await new Client().get(url);
    const doc = new Document(res.body);
    const script = doc.selectFirst('script:contains(eval)');

    // eval code
    const code = script.text;
    eval?.('var window = {};');
    eval?.(code);
    const playlistUrl = globalThis.window.svg.stream;

    // decode sig
    const encoded = playlistUrl.match(/sig=(.*?)&/)[1];
    const charCodes = [];

    for (let i = 0; i < encoded.length; i += 2) {
        charCodes.push(parseInt(encoded.slice(i, i + 2), 16) ^ 2);
    }

    let decoded = Uint8Array.fromBase64(
        String.fromCharCode(...charCodes))
        .slice(5, -5)
        .reverse();

    for (let i = 0; i < decoded.length; i += 2) {
        let tmp = decoded[i];
        decoded[i] = decoded[i + 1];
        decoded[i + 1] = tmp;
    }

    decoded = decoded.decode();
    return await m3u8Extractor(playlistUrl.replace(encoded, decoded), null);
}

async function doodExtractor(url) {
    const dartClient = new Client({ 'useDartHttpClient': true, "followRedirects": false });
    let response = await dartClient.get(url);
    while ("location" in response.headers) {
        response = await dartClient.get(response.headers.location);
    }
    const newUrl = response.request.url;
    const doodhost = newUrl.match(/https:\/\/(.*?)\//, newUrl)[0].slice(8, -1);
    const md5 = response.body.match(/'\/pass_md5\/(.*?)',/, newUrl)[0].slice(11, -2);
    const token = md5.substring(md5.lastIndexOf("/") + 1);
    const expiry = new Date().valueOf();
    const randomString = getRandomString(10);

    response = await new Client().get(`https://${doodhost}/pass_md5/${md5}`, { "Referer": newUrl });
    const videoUrl = `${response.body}${randomString}?token=${token}&expiry=${expiry}`;
    const headers = { "User-Agent": "Mangayomi", "Referer": doodhost };
    return [{ url: videoUrl, originalUrl: videoUrl, headers: headers, quality: '' }];
}

async function vidozaExtractor(url) {
    let response = await new Client({ 'useDartHttpClient': true, "followRedirects": true }).get(url);
    const videoUrl = response.body.match(/https:\/\/\S*\.mp4/)[0];
    return [{ url: videoUrl, originalUrl: videoUrl, quality: '' }];
}

async function okruExtractor(url) {
    const res = await new Client().get(url);
    const doc = new Document(res.body);
    const tag = doc.selectFirst('div[data-options]');
    const playlistUrl = tag.attr('data-options').match(/hlsManifestUrl.*?(h.*?id=\d+)/)[1].replaceAll('\\\\u0026', '&');
    return await m3u8Extractor(playlistUrl, null);
}

async function amazonExtractor(url) {
    const res = await new Client().get(url);
    const doc = new Document(res.body);
    const videoUrl = doc.selectFirst('video').getSrc;
    return videoUrl ? [{ url: videoUrl, originalUrl: videoUrl, headers: null, quality: '' }] : [];
}

async function vidHideExtractor(url) {
    const res = await new Client().get(url);
    return await jwplayerExtractor(res.body);
}

async function filemoonExtractor(url, headers) {
    headers = headers ?? {};
    headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
    delete headers['user-agent'];
    
    let res = await new Client().get(url, headers);
    const src = res.body.match(/iframe src="(.*?)"/)?.[1];
    if (src) {
        res = await new Client().get(src, {
            'Referer': url,
            'Accept-Language': 'de,en-US;q=0.7,en;q=0.3',
            'User-Agent': headers['User-Agent']
        });
    }
    return await jwplayerExtractor(res.body, headers);
}

async function mixdropExtractor(url) {
    headers = {'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'};
    let res = await new Client({ 'useDartHttpClient': true, "followRedirects": false }).get(url, headers);
    while ("location" in res.headers) {
        res = await new Client({ 'useDartHttpClient': true, "followRedirects": false }).get(res.headers.location, headers);
    }
    const newUrl = res.request.url;
    let doc = new Document(res.body);
    
    const code = doc.selectFirst('script:contains(MDCore):contains(eval)').text;
    const unpacked = unpackJs(code);
    let videoUrl = unpacked.match(/wurl="(.*?)"/)?.[1];

    if (!videoUrl) return [];

    videoUrl = 'https:' + videoUrl;
    headers.referer = newUrl;
    
    return [{url: videoUrl, originalUrl: videoUrl, quality: '', headers: headers}];
}

async function speedfilesExtractor(url) {
    let res = await new Client().get(url);
    let doc = new Document(res.body);
    
    const code = doc.selectFirst('script:contains(var)').text;
    let b64;

    // Get b64
    for (const match of code.matchAll(/(?:var|let|const)\s*\w+\s*=\s*["']([^"']+)/g)) {
        if (match[1].match(/[g-zG-Z]/)) {
            b64 = match[1];
            break;
        }
    }

    // decode b64 => b64
    const step1 = Uint8Array.fromBase64(b64).reverse().decode().swapcase();
    // decode b64 => hex
    const step2 = Uint8Array.fromBase64(step1).reverse().decode();
    // decode hex => b64
    let step3 = [];
    for (let i = 0; i < step2.length; i += 2) {
        step3.push(parseInt(step2.slice(i, i + 2), 16) - 3);
    }
    step3 = String.fromCharCode(...step3.reverse()).swapcase();
    // decode b64 => url
    const videoUrl = Uint8Array.fromBase64(step3).decode();
    
    return [{url: videoUrl, originalUrl: videoUrl, quality: '', headers: null}];
}

async function luluvdoExtractor(url) {
    const client = new Client();    
    const match = url.match(/(.*?:\/\/.*?)\/.*\/(.*)/);
    const headers = {'user-agent': 'Mangayomi'};
    const res = await client.get(`${match[1]}/dl?op=embed&file_code=${match[2]}`, headers);    
    return await jwplayerExtractor(res.body, headers);
}

/** Does not work: Client always sets 'charset=utf-8' in Content-Type. */
async function burstcloudExtractor(url) {
    let client = new Client();
    let res = await client.get(url);

    const id = res.body.match(/data-file-id="(.*?)"/)[1];
    const headers = {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        'Referer': url,
    };
    const data = {
        'fileId': id
    };

    res = await client.post(`https://www.burstcloud.co/file/play-request/`, headers, data);
    const videoUrl = res.body.match(/cdnUrl":"(.*?)"/)[1];
    return [{
        url: videoUrl,
        originalUrl: videoUrl,
        headers: { 'Referer': url.match(/.*?:\/\/.*?\//) },
        quality: ''
    }];
}

//--------------------------------------------------------------------------------------------------
//  Video Extractor Wrappers
//--------------------------------------------------------------------------------------------------

_streamWishExtractor = streamWishExtractor;
streamWishExtractor = async (url) => {
    return (await _streamWishExtractor(url, '')).map(v => {
        v.quality = v.quality.slice(3, -1);
        return v;
    });
}

_voeExtractor = voeExtractor;
voeExtractor = async (url) => {
    return (await _voeExtractor(url, '')).map(v => {
        v.quality = v.quality.replace(/Voe: (\d+p?)/i, '$1');
        return v;
    });
}

_mp4UploadExtractor = mp4UploadExtractor;
mp4UploadExtractor = async (url) => {
    return (await _mp4UploadExtractor(url)).map(v => {
        v.quality = v.quality.match(/\d+p/)?.[0] ?? '';
        return v;
    });
}

_yourUploadExtractor = yourUploadExtractor;
yourUploadExtractor = async (url) => {
    return (await _yourUploadExtractor(url))
    .filter(v => !v.url.includes('/novideo'))
    .map(v => {
        v.quality = '';
        return v;
    });
}

_streamTapeExtractor = streamTapeExtractor;
streamTapeExtractor = async (url) => {
    return await _streamTapeExtractor(url, '');
}

_sendVidExtractor = sendVidExtractor;
sendVidExtractor = async (url) => {
    let res = await new Client().get(url);
    var videoUrl, quality;
    try {
        videoUrl = res.body.match(/og:video" content="(.*?\.mp4.*?)"/)[1];
        quality = res.body.match(/og:video:height" content="(.*?)"/)?.[1];
        quality = quality ? quality + 'p' : '';
    } catch (error) {
        
    }
    if (!videoUrl) {
        return _sendVidExtractor(url, null, '');
    }
    return [{url: videoUrl, originalUrl: videoUrl, quality: quality, headers: null}];
}

//--------------------------------------------------------------------------------------------------
//  Video Extractor Helpers
//--------------------------------------------------------------------------------------------------

async function extractAny(url, method, lang, type, host, headers = null) {
    const m = extractAny.methods[method];
    return (!m) ? [] : (await m(url, headers)).map(v => {
        v.quality = v.quality ? `${lang} ${type} ${v.quality} ${host}` : `${lang} ${type} ${host}`;
        return v;
    });
};

extractAny.methods = {
    'amazon': amazonExtractor,
    'burstcloud': burstcloudExtractor,
    'doodstream': doodExtractor,
    'filemoon': filemoonExtractor,
    'luluvdo': luluvdoExtractor,
    'mixdrop': mixdropExtractor,
    'mp4upload': mp4UploadExtractor,
    'okru': okruExtractor,
    'sendvid': sendVidExtractor,
    'speedfiles': speedfilesExtractor,
    'streamtape': streamTapeExtractor,
    'streamwish': vidHideExtractor,
    'vidguard': vidGuardExtractor,
    'vidhide': vidHideExtractor,
    'vidoza': vidozaExtractor,
    'voe': voeExtractor,
    'yourupload': yourUploadExtractor
};

//--------------------------------------------------------------------------------------------------
//  Playlist Extractors
//--------------------------------------------------------------------------------------------------

async function m3u8Extractor(url, headers = null) {
    // https://developer.apple.com/documentation/http-live-streaming/creating-a-multivariant-playlist
    // https://developer.apple.com/documentation/http-live-streaming/adding-alternate-media-to-a-playlist
    // define attribute lists
    const streamAttributes = [
        ['avg_bandwidth', /AVERAGE-BANDWIDTH=(\d+)/],
        ['bandwidth', /\bBANDWIDTH=(\d+)/],
        ['resolution', /\bRESOLUTION=([\dx]+)/],
        ['framerate', /\bFRAME-RATE=([\d\.]+)/],
        ['codecs', /\bCODECS="(.*?)"/],
        ['video', /\bVIDEO="(.*?)"/],
        ['audio', /\bAUDIO="(.*?)"/],
        ['subtitles', /\bSUBTITLES="(.*?)"/],
        ['captions', /\bCLOSED-CAPTIONS="(.*?)"/]
    ];
    const mediaAttributes = [
        ['type', /\bTYPE=([\w-]*)/],
        ['group', /\bGROUP-ID="(.*?)"/],
        ['lang', /\bLANGUAGE="(.*?)"/],
        ['name', /\bNAME="(.*?)"/],
        ['autoselect', /\bAUTOSELECT=(\w*)/],
        ['default', /\bDEFAULT=(\w*)/],
        ['instream-id', /\bINSTREAM-ID="(.*?)"/],
        ['assoc-lang', /\bASSOC-LANGUAGE="(.*?)"/],
        ['channels', /\bCHANNELS="(.*?)"/],
        ['uri', /\bURI="(.*?)"/]
    ];
    const streams = [], videos = {}, audios = {}, subtitles = {}, captions = {};
    const dict = { 'VIDEO': videos, 'AUDIO': audios, 'SUBTITLES': subtitles, 'CLOSED-CAPTIONS': captions };

    const res = await new Client().get(url, headers);
    const text = res.body;

    if (res.statusCode != 200) {
        return [];
    }

    // collect media
    for (const match of text.matchAll(/#EXT-X-MEDIA:(.*)/g)) {
        const info = match[1], medium = {};
        for (const attr of mediaAttributes) {
            const m = info.match(attr[1]);
            medium[attr[0]] = m ? m[1] : null;
        }

        const type = medium.type;
        delete medium.type;
        const group = medium.group;
        delete medium.group;

        const typedict = dict[type];
        if (typedict[group] == undefined)
            typedict[group] = [];
        typedict[group].push(medium);
    }

    // collect streams
    for (const match of text.matchAll(/#EXT-X-STREAM-INF:(.*)\s*(.*)/g)) {
        const info = match[1], stream = { 'url': absUrl(match[2], url) };
        for (const attr of streamAttributes) {
            const m = info.match(attr[1]);
            stream[attr[0]] = m ? m[1] : null;
        }

        stream['video'] = videos[stream.video] ?? null;
        stream['audio'] = audios[stream.audio] ?? null;
        stream['subtitles'] = subtitles[stream.subtitles] ?? null;
        stream['captions'] = captions[stream.captions] ?? null;

        // format resolution or bandwidth
        let quality;
        if (stream.resolution) {
            quality = stream.resolution.match(/x(\d+)/)[1] + 'p';
        } else {
            quality = (parseInt(stream.avg_bandwidth ?? stream.bandwidth) / 1000000) + 'Mb/s'
        }

        // add stream to list
        const subs = stream.subtitles?.map((s) => {
            return { file: s.uri, label: s.name };
        });
        const auds = stream.audio?.map((a) => {
            return { file: a.uri, label: a.name };
        });
        streams.push({
            url: stream.url,
            quality: quality,
            originalUrl: stream.url,
            headers: headers,
            subtitles: subs ?? null,
            audios: auds ?? null
        });
    }
    return streams.length ? streams : [{
        url: url,
        quality: '',
        originalUrl: url,
        headers: headers,
        subtitles: null,
        audios: null
    }];
}

async function jwplayerExtractor(text, headers) {
    // https://docs.jwplayer.com/players/reference/playlists
    const getsetup = /setup\(({[\s\S]*?})\)/;
    const getsources = /sources:\s*(\[[\s\S]*?\])/;
    const gettracks = /tracks:\s*(\[[\s\S]*?\])/;
    const unpacked = unpackJs(text);

    const videos = [], subtitles = [];

    const data = eval('(' + (getsetup.exec(text) || getsetup.exec(unpacked))?.[1] + ')');

    if (data){
        var sources = data.sources;
        var tracks = data.tracks;
    } else {
        var sources = eval('(' + (getsources.exec(text) || getsources.exec(unpacked))?.[1] + ')');
        var tracks = eval('(' + (gettracks.exec(text) || gettracks.exec(unpacked))?.[1] + ')');
    }
    for (t of tracks) {
        if (t.type == "captions") {
            subtitles.push({file: t.file, label: t.label});
        }
    }
    for (s of sources) {
        if (s.file.includes('master.m3u8')) {
            videos.push(...(await m3u8Extractor(s.file, headers)));
        } else if (s.file.includes('.mpd')) {
            
        } else {
            videos.push({url: s.file, originalUrl: s.file, quality: '', headers: headers});
        }
    }
    return videos.map(v => {
        v.subtitles = subtitles;
        return v;
    });
}

//--------------------------------------------------------------------------------------------------
//  Extension Helpers
//--------------------------------------------------------------------------------------------------

function sortVideos(videos) {
    const pref = new SharedPreferences();
    const getres = RegExp('(\\d+)p?', 'i');
    const lang = RegExp(pref.get('lang'), 'i');
    const type = RegExp(pref.get('type'), 'i');
    const res = RegExp(getres.exec(pref.get('res'))[1], 'i');
    const host = RegExp(pref.get('host'), 'i');

    let getScore = (q, hasRes) => {
        const bLang = lang.test(q), bType = type.test(q), bRes = res.test(q), bHost = host.test(q);
        if (hasRes) {
            return bLang * (8 + bType * (4 + bRes * (2 + bHost * 1)));
        } else {
            return bLang * (8 + bType * (4 + (bHost * 3)));
        }
    }

    return videos.sort((a, b) => {
        const resA = getres.exec(a.quality)?.[1];
        const resB = getres.exec(b.quality)?.[1];
        const score = getScore(b.quality, resB) - getScore(a.quality, resA);

        if (score) return score;

        const qA = resA ? a.quality.replace(resA, (9999 - parseInt(resA)).toString()) : a.quality;
        const qB = resA ? b.quality.replace(resB, (9999 - parseInt(resB)).toString()) : b.quality;

        return qA.localeCompare(qB);
    });
}

//--------------------------------------------------------------------------------------------------
//  Uint8Array
//--------------------------------------------------------------------------------------------------

Uint8Array.fromBase64 = function (b64) {
    //        [00,01,02,03,04,05,06,07,08,\t,\n,0b,0c,\r,0e,0f,10,11,12,13,14,15,16,17,18,19,1a,1b,1c,1d,1e,1f,' ', !, ", #, $, %, &, ', (, ), *, +,',', -, ., /, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, :, ;, <,'=', >, ?, @,A,B,C,D,E,F,G,H,I,J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, [, \, ], ^, _, `, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, {, |, }, ~,7f]
    const m = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, 62, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1]
    let data = [], val = 0, bits = -8
    for (const c of b64) {
        let n = m[c.charCodeAt(0)];
        if (n == -1) break;
        val = (val << 6) + n;
        bits += 6;
        for (; bits >= 0; bits -= 8)
            data.push((val >> bits) & 0xFF);
    }
    return new Uint8Array(data);
}

Uint8Array.prototype.toBase64 = function () {
    const m = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    let b64 = '', val = 0, bits = -6;
    for (const b of this) {
        val = (val << 8) + b;
        bits += 8;
        while (bits >= 0) {
            b64 += m[(val >> bits) & 0x3F];
            bits -= 6;
        }
    }
    if (bits > -6)
        b64 += m[(val << -bits) & 0x3F];
    return b64 + ['', '', '==', '='][b64.length % 4];
}

Uint8Array.prototype.decode = function (encoding = 'utf-8') {
    encoding = encoding.toLowerCase();
    if (encoding == 'utf-8') {
        return decodeUTF8(this);
    }
    return null;
}

//--------------------------------------------------------------------------------------------------
//  String
//--------------------------------------------------------------------------------------------------

String.prototype.encode = function (encoding = 'utf-8') {
    encoding = encoding.toLowerCase();
    if (encoding == 'utf-8') {
        return encodeUTF8(this);
    }
    return null;
}

String.decode = function (data, encoding = 'utf-8') {
    encoding = encoding.toLowerCase();
    if (encoding == 'utf-8') {
        return decodeUTF8(data);
    }
    return null;
}

String.prototype.reverse = function () {
    return this.split('').reverse().join('');
}

String.prototype.swapcase = function () {
    const isAsciiLetter = /[A-z]/;
    const result = [];
    for (const l of this)
        result.push(isAsciiLetter.test(l) ? String.fromCharCode(l.charCodeAt() ^ 32) : l);
    return result.join('');
}

function getRandomString(length) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
    let result = "";
    for (let i = 0; i < length; i++) {
        const random = Math.floor(Math.random() * 61);
        result += chars[random];
    }
    return result;
}

//--------------------------------------------------------------------------------------------------
//  Encode/Decode Functions
//--------------------------------------------------------------------------------------------------

function decodeUTF8(data) {
    const codes = [];
    for (let i = 0; i < data.length;) {
        const c = data[i++];
        const len = (c > 0xBF) + (c > 0xDF) + (c > 0xEF);
        let val = c & (0xFF >> (len + 1));
        for (const end = i + len; i < end; i++) {
            val = (val << 6) + (data[i] & 0x3F);
        }
        codes.push(val);
    }
    return String.fromCharCode(...codes);
}

function encodeUTF8(string) {
    const data = [];
    for (const c of string) {
        const code = c.charCodeAt(0);
        const len = (code > 0x7F) + (code > 0x7FF) + (code > 0xFFFF);
        let bits = len * 6;

        data.push((len ? ~(0xFF >> len + 1) : (0)) + (code >> bits));
        while (bits > 0) {
            data.push(0x80 + ((code >> (bits -= 6)) & 0x3F))
        }
    }
    return new Uint8Array(data);
}

//--------------------------------------------------------------------------------------------------
//  Url
//--------------------------------------------------------------------------------------------------

function absUrl(url, base) {
    if (url.search(/^\w+:\/\//) == 0) {
        return url;
    } else if (url.startsWith('/')) {
        return base.slice(0, base.lastIndexOf('/')) + url;
    } else {
        return base.slice(0, base.lastIndexOf('/') + 1) + url;
    }
}
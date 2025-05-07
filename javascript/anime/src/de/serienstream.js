const mangayomiSources = [{
    "name": "SerienStream",
    "lang": "de",
    "baseUrl": "https://s.to",
    "apiUrl": "",
    "iconUrl": "https://s.to/favicon.ico",
    "typeSource": "single",
    "itemType": 1,
    "isNsfw": false,
    "version": "0.0.9",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/de/serienstream.js"
}];

class DefaultExtension extends MProvider {
    constructor () {
        super();
        this.client = new Client();
    }
    async getPopular(page) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/beliebte-serien`);
        const elements = new Document(res.body).select("div.seriesListContainer div");
        const list = [];
        for (const element of elements) {
            const linkElement = element.selectFirst("a");
            const name = element.selectFirst("h3").text;
            const imageUrl = baseUrl + linkElement.selectFirst("img").attr("data-src");
            const link = linkElement.attr("href");
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    async getLatestUpdates(page) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/neu`);
        const elements = new Document(res.body).select("div.seriesListContainer div");
        const list = [];
        for (const element of elements) {
            const linkElement = element.selectFirst("a");
            const name = element.selectFirst("h3").text;
            const imageUrl = baseUrl + linkElement.selectFirst("img").attr("data-src");
            const link = linkElement.attr("href");
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    async search(query, page, filters) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(`${baseUrl}/serien`);
        const elements = new Document(res.body).select("#seriesContainer > div > ul > li > a").filter(e => e.attr("title").toLowerCase().includes(query.toLowerCase()));
        const list = [];
        for (const element of elements) {
            const name = element.text;
            const link = element.attr("href");
            const img = new Document((await this.client.get(baseUrl + link)).body).selectFirst("div.seriesCoverBox img").attr("data-src");
            const imageUrl = baseUrl + img;
            list.push({ name, imageUrl, link });
        }
        return {
            list: list,
            hasNextPage: false
        }
    }
    cleanHtmlString(input) {
      if (!input) return "";
      return input
          .replace(/&lt;/g, '<')
          .replace(/&gt;/g, '>')
          .replace(/<br>/g, '\n')
          .replace(/<br\s*\/?>/g, '\n')
          .replace(/&#039;/g, "'")
          .replace(/&quot;/g, '"')
          .replace(/<a\s+href="([^"]*)".*?>.*?<\/a>/g, '$1');
    }
    /**
     * Custom asyncPool implementation.
     * @param {number} poolLimit - Maximum number of concurrent promises.
     * @param {Array} array - Array of items to process.
     * @param {function} iteratorFn - Function that returns a promise for each item.
     * @returns {Promise<Array>} - Promise resolving to an array of results.
     */
    async asyncPool(poolLimit, array, iteratorFn) {
        const ret = [];       // Array to store all promises
        const executing = []; // Array to store currently executing promises
    
        for (const item of array) {
          const p = Promise.resolve().then(() => iteratorFn(item));
          ret.push(p);
    
          // When poolLimit is reached, wait for the fastest promise to complete
          if (poolLimit <= array.length) {
            const e = p.then(() => {
              // Remove the promise from executing array once it resolves
              executing.splice(executing.indexOf(e), 1);
            });
            executing.push(e);
            if (executing.length >= poolLimit) {
              await Promise.race(executing);
            }
          }
        }
        return Promise.all(ret);
    }
    async getDetail(url) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(baseUrl + url);
        const document = new Document(res.body);
        const imageUrl = baseUrl +
            document.selectFirst("div.seriesCoverBox img").attr("data-src");
        const name = document.selectFirst("div.series-title h1 span").text;
        const genre = document.select("div.genres ul li").map(e => e.text).filter(text => !/^\+\s\d+$/.test(text));
        const description = this.cleanHtmlString(document.selectFirst("p.seri_des").attr("data-full-description"));
        const produzent = document.select("div.cast li")
            .filter(e => e.outerHtml.includes("Produzent:"));
        let author = "";
        if (produzent.length > 0) {
            author = produzent[0]
              .select("li")
              .map((e) => e.text)
              .filter((text) => !/^\s\&\s\d+\sweitere$/.test(text))
              .join(", ");
        }
        const seasonsElements = document.select("#stream > ul:nth-child(1) > li > a");
        // Use asyncPool to limit concurrency while processing seasons
        const episodesArrays = await this.asyncPool(2, seasonsElements, element => this.parseEpisodesFromSeries(element));
        // Flatten the resulting arrays and reverse the order
        const episodes = episodesArrays.flat().reverse();
        return { name, imageUrl, description, author, status: 5, genre, episodes };
    }
    async parseEpisodesFromSeries(element) {
        const seasonId = element.getHref;
        const res = await this.client.get(this.source.baseUrl + seasonId);
        const episodeElements = new Document(res.body).select("table.seasonEpisodesList tbody tr");
        // Use asyncPool to limit concurrency while processing episodes of a season
        return await this.asyncPool(13, episodeElements, e => this.episodeFromElement(e));
    }
    async episodeFromElement(element) {
        const titleAnchor = element.selectFirst("td.seasonEpisodeTitle a");
        const episodeSpan = titleAnchor.selectFirst("span");
        const url = titleAnchor.attr("href");
        const dateUpload = await this.getUploadDateFromEpisode(url);
        const episodeSeasonId = element.attr("data-episode-season-id");
        let episode = this.cleanHtmlString(episodeSpan.text);
        let name = "";
        if (url.includes("/film")) {
            name = `Film ${episodeSeasonId} : ${episode}`;
        } else {
            const seasonMatch = url.match(/staffel-(\d+)\/episode/);
            name = `Staffel ${seasonMatch[1]} Folge ${episodeSeasonId} : ${episode}`;
        }
        return name && url ? { name, url, dateUpload } : {};
    }
    async getUploadDateFromEpisode(url) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(baseUrl + url);
        const getLastSundayOfMonth = (year, month) => {
            const lastDay = this.createDate(year, month, 0);
            const lastSunday = lastDay.getDate() - lastDay.getDay();
            return this.createDate(year, month - 1, lastSunday);
        };
        const document = new Document(res.body);
        const dateString = document.selectFirst('strong[style="color: white;"]').text;
        const dateTimePart = dateString.split(", ")[1];
        const [date, time] = dateTimePart.split(" ");
        const [day, month, year] = date.split(".");
        const [hours, minutes] = time.split(":");
        const dayInt = parseInt(day);
        const monthInt = parseInt(month);
        const yearInt = parseInt(year);
        const hoursInt = parseInt(hours);
        const minutesInt = parseInt(minutes);
        const lastSundayOfMarch = getLastSundayOfMonth(yearInt, 3);
        const lastSundayOfOctober = getLastSundayOfMonth(yearInt, 10);
        const jsDate = this.createDate(yearInt, monthInt - 1, dayInt, hoursInt, minutesInt);
        // If Date between lastSundayOfMarch & lastSundayOfOctober -> CEST (MESZ)
        const isInDST = jsDate >= lastSundayOfMarch && jsDate < lastSundayOfOctober;
        let timeZoneOffset = isInDST ? 0 : 1;
        // If it's in CEST, subtract 1 hour from UTC (to get local time in CEST)
        const correctedTime = this.createDate(jsDate.getTime() + (timeZoneOffset - 1) * 60 * 60 * 1000);
        return String(correctedTime.valueOf()); // dateUpload is a string containing date expressed in millisecondsSinceEpoch.
    }

    createDate(yearOrNum, month, day) {
        if (yearOrNum && month && day) {
            return day < 1 ? new Date(Math.max(new Date().getFullYear(), yearOrNum), Math.max(0, month)) : 
                new Date(Math.max(new Date().getFullYear(), yearOrNum), Math.max(0, month), day);
        } else if (yearOrNum) {
            return new Date(yearOrNum);
        } else {
            return new Date();
        }
    }

    async getVideoList(url) {
        const baseUrl = this.source.baseUrl;
        const res = await this.client.get(baseUrl + url, {
            'Accept': '*/*',
            'Referer': baseUrl + url,
            'Priority': 'u=0, i',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0'
        });
        const document = new Document(res.body);
        let promises = [];
        const videos = [];

        const preferences = new SharedPreferences();
        const hostFilter = preferences.get("host_filter");
        const langFilter = preferences.get("lang_filter");

        const redirectsElements = document.select("ul.row li");
        const dartClient = new Client({ 'useDartHttpClient': true, "followRedirects": false });

        for (const element of redirectsElements) {
            const langkey = element.attr("data-lang-key");
            const lang = (langkey == 1 || langkey == 3) ? 'Deutscher' : 'Englischer';
            const type = (langkey == 1) ? 'Dub' : 'Sub';
            const host = element.selectFirst("a h4").text;

            if (hostFilter.includes(host) && langFilter.includes(`${lang} ${type}`)) {
                const redirect = baseUrl + element.selectFirst("a.watchEpisode").attr("href");
                promises.push((async (redirect, lang, type, host) => {
                    const location = (await dartClient.get(redirect)).headers.location;
                    return await extractAny(location, host.toLowerCase(), lang, type, host, {'Referer': this.source.baseUrl});
                })(redirect, lang, type, host));
            }
        }
        for (const p of (await Promise.allSettled(promises))) {
            if (p.status == 'fulfilled') {
                videos.push.apply(videos, p.value);
            }
        }
        return sortVideos(videos);
    }
    getSourcePreferences() {
        const languages = ['Deutsch', 'Englisch'];
        const languageValues = ['Deutscher', 'Englischer'];
        const types = ['Dub', 'Sub'];
        const resolutions = ['1080p', '720p', '480p'];
        const hosts = ['Doodstream', 'Filemoon', 'Luluvdo', 'SpeedFiles', 'Streamtape', 'Vidoza', 'VOE'];
        const languageFilters = [];

        for (const lang of languageValues) {
            for (const type of types) {
                languageFilters.push(`${lang} ${type}`);
            }
        }

        return [
            {
                key: 'lang',
                listPreference: {
                    title: 'Bevorzugte Sprache',
                    summary: 'Wenn verfügbar, wird diese Sprache ausgewählt. Priority = 0 (lower is better)',
                    valueIndex: 0,
                    entries: languages,
                    entryValues: languageValues
                }
            },
            {
                key: 'type',
                listPreference: {
                    title: 'Bevorzugter Typ',
                    summary: 'Wenn verfügbar, wird dieser Typ ausgewählt. Priority = 1 (lower is better)',
                    valueIndex: 0,
                    entries: types,
                    entryValues: types
                }
            },
            {
                key: 'res',
                listPreference: {
                    title: 'Bevorzugte Auflösung',
                    summary: 'Wenn verfügbar, wird diese Auflösung ausgewählt. Priority = 2 (lower is better)',
                    valueIndex: 0,
                    entries: resolutions,
                    entryValues: resolutions
                }
            },
            {
                key: 'host',
                listPreference: {
                    title: 'Bevorzugter Hoster',
                    summary: 'Wenn verfügbar, wird dieser Hoster ausgewählt. Priority = 3 (lower is better)',
                    valueIndex: 0,
                    entries: hosts,
                    entryValues: hosts
                }
            },
            {
                key: "lang_filter",
                multiSelectListPreference: {
                    title: "Sprachen auswählen",
                    summary: "Wähle aus welche Sprachen dir angezeigt werden sollen. Weniger streams zu laden beschleunigt den Start der Videos.",
                    entries: languageFilters,
                    entryValues: languageFilters,
                    values: languageFilters
                }
            },
            {
                key: "host_filter",
                multiSelectListPreference: {
                    title: "Hoster auswählen",
                    summary: "Wähle aus welche Hoster dir angezeigt werden sollen. Weniger streams zu laden beschleunigt den Start der Videos.",
                    entries: hosts,
                    entryValues: hosts,
                    values: hosts
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

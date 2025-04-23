const mangayomiSources = [{
    "name": "KissKH",
    "lang": "all",
    "baseUrl": "https://kisskh.ovh",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/all.kisskh.jpg",
    "typeSource": "multi",
    "itemType": 1,
    "version": "0.1.0",
    "pkgPath": "anime/src/all/kisskh.js"
}];

class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    getPreference(key) {
        return new SharedPreferences().get(key);
    }

    getHeaders() {
        return {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6832.64 Safari/537.36",
            "Referer": this.source.baseUrl,
            "Origin": this.source.baseUrl,
        }
    }

    getBaseUrl() {
        return this.getPreference("kisskh_base_url");
    }

    async request(url) {
        var res = await this.client.get(url, { headers: this.getHeaders() });
        return res.body
    }

    async APIRequest(slug) {
        try {
            var baseUrl = this.getBaseUrl();
            var api = baseUrl + `/api/DramaList${slug}`;
            var body = await this.request(api)
            return JSON.parse(body);
        } catch (e) {
            console.log(e);
        }
        return [];
    }

    async formatpageList(slug) {
        var res = await this.APIRequest(slug);
        var list = []
        var hasNextPage = false

        for (var media of res) {
            var name = media.title
            var imageUrl = media.thumbnail
            var link = "" + media.id

            list.push({ name, imageUrl, link });
        }
        return { list, hasNextPage }
    }

    async getPopular(page) {
        var mostViewed = await this.formatpageList("/MostView?c=1");
        var topRated = await this.formatpageList("/TopRating");

        var list = [...mostViewed.list, ...topRated.list]
        return { list, hasNextPage: false };
    }

    async getLatestUpdates(page) {
        return await this.formatpageList("/LastUpdate");
    }

    async search(query, page, filters) {
        return await this.formatpageList(`/Search?q=${query}&type=0`);
    }

    async getDetail(url) {
        function statusCode(status) {
            return {
                "Ongoing": 0,
                "Completed": 1,
                "Upcoming": 4,
            }[status] ?? 5;
        }

        var baseUrl = this.getBaseUrl()
        // Check while refreshing the page
        if (url.includes(baseUrl)) {
            url = url.split("?id=")[1]
        }

        var res = await this.APIRequest(`/Drama/${url}`)
        var id = res.id
        var name = res.title
        var slug = name.replace(/[^A-Z0-9]/gi, "-")
        var link = baseUrl + `/Drama/${slug}?id=${id}`
        var imageUrl = res.thumbnail
        var status = statusCode(res.status)
        var description = res.description
        var genre = [res.type, res.country]

        var chapters = []
        var episodes = res.episodes
        episodes.forEach(item => {
            var epNum = item.number
            var name = epNum == 0 ? "Movie" : `Epsiode: ${epNum}`

            chapters.push({
                name,
                url: "" + item.id,
            })
        });

        return { name, imageUrl, link, description, genre, status, chapters }
    }


    // For anime episode video list
    async getVideoList(url) {
        var episodeId = url
        var baseUrl = this.getBaseUrl()
        var headers = this.getHeaders()

        var appName = "kisskh"
        var appVer = "2.8.10"
        var platformVer = 4830201

        var vidGuid = "62f176f3bb1b5b8e70e39932ad34a0c7"
        var vidKkey = this.generateToken(episodeId, appVer, vidGuid, platformVer, appName)
        var vidSlug = `/Episode/${episodeId}.png?err=false&ts=null&time=null&kkey=${vidKkey}`
        var vidData = await this.APIRequest(vidSlug)
        if (vidData == []) {
            // Empty arrary
            return vidData
        }

        var streams = [{
            url: vidData.Video,
            originalUrl: vidData.Video,
            quality: "Auto",
            headers,
        }]

        var subtitles = []
        var subGuid = "VgV52sWhwvBSf8BsM3BRY9weWiiCbtGp"
        var subKkey = this.generateToken(episodeId, appVer, subGuid, platformVer, appName)
        var subApi = `${baseUrl}/api/Sub/${episodeId}/?kkey=${subKkey}`
        var subBody = await this.request(subApi)
        var subData = JSON.parse(subBody);
        for (var sub of subData) {
            var subUrl = sub.src
            var subtitleText = await this.getSubtitle(subUrl)

            subtitles.push({
                file: subtitleText,
                label: sub.label
            })
        }

        streams[0].subtitles = subtitles
        return streams
    }

    getSourcePreferences() {
        return [
            {
                key: "kisskh_base_url",
                editTextPreference: {
                    title: "Override base url",
                    summary: "",
                    value: "https://kisskh.ovh",
                    dialogTitle: "Override base url",
                    dialogMessage: "",
                }
            },
        ]
    }

    // ----------------Subtitle Decoders----------------
    // Credits :- https://github.com/Prudhvi-pln/udb/

    async getSubtitle(subUrl) {
        var key = "sWODXX04QRTkHdlZ"
        var iv = "8pwhapJeC4hrS9hO"
        if (subUrl.endsWith(".txt1")) {
            key = "AmSmZVcH93UQUezi"
            iv = "ReBKWW8cqdjPEnF6"
        } else if (subUrl.endsWith("txt")) {
            key = "8056483646328763"
            iv = "6852612370185273"
        }

        var subText = ""
        var subBody = await this.request(subUrl)
        try {
            var splitText = subBody.split("\n")
            for (var txt of splitText) {
                txt = txt.trim()
                if (txt.length > 0) {
                    var decryptedText = cryptoHandler(txt, iv, key, false)
                    subText += decryptedText + "\n"
                }
            }
        } catch (e) {
            console.log(e)
        }
        return subText

    }


    // ----------------KissKh Decoders----------------
    // Source :- https://kisskh.ovh/common.js?v=9082123

    generateToken(episodeId, appVer, guid, platformVer, appName) {
        var param2 = null
        var userAgent = appName
        var referrer = appName
        var appCodeName = appName
        var url = appName
        var platform = appName

        // Convert string to word array
        function stringToWordArray(string) {
            const stringLength = string.length;
            const words = [];

            for (let i = 0; i < stringLength; i++) {
                words[i >>> 2] |= (string.charCodeAt(i) & 255) << (24 - i % 4 * 8);
            }

            return [words, stringLength];
        }

        // Convert word array to hex string
        function wordArrayToHex(words, length) {
            const hexChars = [];

            for (let i = 0; i < length; i++) {
                hexChars.push((words[i >>> 2] >>> (24 - i % 4 * 8) & 255).toString(16).padStart(2, "0"));
            }

            return hexChars.join("");
        }

        // Truncate string to 48 chars
        function truncateString(str) {
            return (str || "").substr(0, 48);
        }

        // Calculate simple hash of a string
        function simpleHash(str) {
            let hash = 0;
            const len = str.length;

            for (let i = 0; i < len; i++) {
                hash = (hash << 5) - hash + str.charCodeAt(i);
            }

            return hash;
        }

        // Apply PKCS7-like padding
        function padString(data) {
            const padLength = 16 - data.length % 16;

            for (let i = 0; i < padLength; ++i) {
                data += String.fromCharCode(padLength);
            }

            return data;
        }

        // Initialize AES lookup tables
        function initializeAESTables() {
            const ROUND_CONSTANTS = [1332468387, -1641050960, 2136896045, -1629555948, 1399201960, -850809832, -1307058635, 751381793, -1933648423, 1106735553, -203378700, -550927659, 766369351, 1817882502, -1615200142, 1083409063, -104955314, -1780208184, 173944250, 1254993693, 1422337688, -1054667952, -880990486, -2119136777, -1822404972, 1380140484, -1723964626, 412019417, -890799303, -1734066435, 26893779, 420787978, -1337058067, 686432784, 695238595, 811911369, -391724567, -1068702727, -381903814, -648522509, -1266234148, 1959407397, -1644776673, 1152313324];
            const SUB_MIX_0 = [];
            const SUB_MIX_1 = [];
            const SUB_MIX_2 = [];
            const SUB_MIX_3 = [];
            const SBOX = [];
            const MULT_TABLE = [];

            for (let i = 0; i < 256; i++) {
                MULT_TABLE[i] = i < 128 ? i << 1 : i << 1 ^ 283;
            }

            let x = 0;
            let xi = 0;
            for (let i = 0; i < 256; i++) {
                let sx = xi ^ xi << 1 ^ xi << 2 ^ xi << 3 ^ xi << 4;
                sx = sx >>> 8 ^ sx & 255 ^ 99;
                SBOX[x] = sx;

                let x2 = MULT_TABLE[x];
                let x4 = MULT_TABLE[MULT_TABLE[x2]];
                let t = MULT_TABLE[sx] * 257 ^ sx * 16843008;

                SUB_MIX_0[x] = t << 24 | t >>> 8;
                SUB_MIX_1[x] = t << 16 | t >>> 16;
                SUB_MIX_2[x] = t << 8 | t >>> 24;
                SUB_MIX_3[x] = t;

                if (x) {
                    x = x2 ^ MULT_TABLE[MULT_TABLE[MULT_TABLE[x4 ^ x2]]];
                    xi ^= MULT_TABLE[MULT_TABLE[xi]];
                } else {
                    x = xi = 1;
                }
            }

            return [ROUND_CONSTANTS, SUB_MIX_0, SUB_MIX_1, SUB_MIX_2, SUB_MIX_3, SBOX];
        }

        // Process one block (AES encryption round)
        function processBlock(words, offset, AES_TABLES) {
            const [ROUND_CONSTANTS, SUB_MIX_0, SUB_MIX_1, SUB_MIX_2, SUB_MIX_3, SBOX] = AES_TABLES;

            let keySchedule;
            if (offset === 0) {
                keySchedule = [22039283, 1457920463, 776125350, -1941999367];
            } else {
                keySchedule = words.slice(offset - 4, offset);
            }

            // XOR with previous block or IV
            for (let i = 0; i < 4; i++) {
                words[offset + i] ^= keySchedule[i];
            }

            // Perform AES rounds
            const NUM_ROUNDS = 10;
            let t0 = words[offset] ^ ROUND_CONSTANTS[0];
            let t1 = words[offset + 1] ^ ROUND_CONSTANTS[1];
            let t2 = words[offset + 2] ^ ROUND_CONSTANTS[2];
            let t3 = words[offset + 3] ^ ROUND_CONSTANTS[3];

            let ksIndex = 4;
            let s0, s1, s2;

            // Main round function
            for (let round = 1; round < NUM_ROUNDS; round++) {
                s0 = SUB_MIX_0[t0 >>> 24] ^ SUB_MIX_1[t1 >>> 16 & 255] ^ SUB_MIX_2[t2 >>> 8 & 255] ^ SUB_MIX_3[t3 & 255] ^ ROUND_CONSTANTS[ksIndex++];
                s1 = SUB_MIX_0[t1 >>> 24] ^ SUB_MIX_1[t2 >>> 16 & 255] ^ SUB_MIX_2[t3 >>> 8 & 255] ^ SUB_MIX_3[t0 & 255] ^ ROUND_CONSTANTS[ksIndex++];
                s2 = SUB_MIX_0[t2 >>> 24] ^ SUB_MIX_1[t3 >>> 16 & 255] ^ SUB_MIX_2[t0 >>> 8 & 255] ^ SUB_MIX_3[t1 & 255] ^ ROUND_CONSTANTS[ksIndex++];
                t3 = SUB_MIX_0[t3 >>> 24] ^ SUB_MIX_1[t0 >>> 16 & 255] ^ SUB_MIX_2[t1 >>> 8 & 255] ^ SUB_MIX_3[t2 & 255] ^ ROUND_CONSTANTS[ksIndex++];
                t0 = s0;
                t1 = s1;
                t2 = s2;
            }

            // Final round
            s0 = (SBOX[t0 >>> 24] << 24 | SBOX[t1 >>> 16 & 255] << 16 | SBOX[t2 >>> 8 & 255] << 8 | SBOX[t3 & 255]) ^ ROUND_CONSTANTS[ksIndex++];
            s1 = (SBOX[t1 >>> 24] << 24 | SBOX[t2 >>> 16 & 255] << 16 | SBOX[t3 >>> 8 & 255] << 8 | SBOX[t0 & 255]) ^ ROUND_CONSTANTS[ksIndex++];
            s2 = (SBOX[t2 >>> 24] << 24 | SBOX[t3 >>> 16 & 255] << 16 | SBOX[t0 >>> 8 & 255] << 8 | SBOX[t1 & 255]) ^ ROUND_CONSTANTS[ksIndex++];
            t3 = (SBOX[t3 >>> 24] << 24 | SBOX[t0 >>> 16 & 255] << 16 | SBOX[t1 >>> 8 & 255] << 8 | SBOX[t2 & 255]) ^ ROUND_CONSTANTS[ksIndex++];

            words[offset] = s0;
            words[offset + 1] = s1;
            words[offset + 2] = s2;
            words[offset + 3] = t3;
        }

        // Process all blocks
        function processBlocks(words, AES_TABLES) {
            const length = words.length;
            for (let i = 0; i < length; i += 4) {
                processBlock(words, i, AES_TABLES);
            }
        }

        // Create data array with all parameters
        const dataArray = ["", episodeId, param2, "mg3c3b04ba", appVer, guid, platformVer,
            truncateString(url),
            truncateString(userAgent.toLowerCase()),
            truncateString(referrer),
            appCodeName, appName, platform, "00", ""];

        // Insert hash of the data at position 1
        dataArray.splice(1, 0, simpleHash(dataArray.join("|")));

        // Join, pad, and process
        const paddedData = padString(dataArray.join("|"));
        const [words, length] = stringToWordArray(paddedData);

        // Initialize AES tables and process blocks
        const AES_TABLES = initializeAESTables();
        processBlocks(words, AES_TABLES);

        // Return final hex string in uppercase
        return wordArrayToHex(words, length).toUpperCase();
    }

    // End
}

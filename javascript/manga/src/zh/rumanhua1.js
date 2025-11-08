const mangayomiSources = [{
  name: "如漫画",
  lang: "zh",
  baseUrl: "http://www.rumanhua1.com",
  iconUrl: "https://i.ibb.co/TDfbbwDB/Untitled-design.png",
  typeSource: "single",
  itemType: 0,
  isNsfw: false,
  version: "0.2.0",
  pkgName: "manga/src/zh/rumanhua1.js"
}];

class DefaultExtension extends MProvider {
  constructor() {
    super();
    this.client = new Client();
  }

  getHeaders() {
    return {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    };
  }


  get supportsLatest() { return true; }

  async getPopular() {
    const res = await this.client.get("http://www.rumanhua1.com/rank/1", this.getHeaders());
    const doc = new Document(res.body);
    const list = [];
    for (const el of doc.select(".likedata")) {
      const a = el.selectFirst("a");
      if (!a) continue;
      const url = "/" + a.attr("href").replace(/^\/|\/$/g, "") + "/";
      let img = el.selectFirst("img")?.attr("data-src") || "";
      if (img.startsWith("//")) img = "https:" + img;
      list.push({
        name: el.selectFirst(".le-t")?.text || "",
        imageUrl: img,
        link: url,
        author: el.selectFirst(".likeinfo > p")?.text.replace("作者：", "") || "",
        description: el.selectFirst(".le-j")?.text || ""
      });
    }
    return { list, hasNextPage: false };
  }

  async getLatestUpdates() {
    const res = await this.client.get("http://www.rumanhua1.com/rank/5", this.getHeaders());
    const doc = new Document(res.body);
    const list = [];
    for (const el of doc.select(".likedata")) {
      const a = el.selectFirst("a");
      if (!a) continue;
      const url = "/" + a.attr("href").replace(/^\/|\/$/g, "") + "/";
      let img = el.selectFirst("img")?.attr("data-src") || "";
      if (img.startsWith("//")) img = "http:" + img;
      list.push({
        name: el.selectFirst(".le-t")?.text || "",
        imageUrl: img,
        link: url,
        author: el.selectFirst(".likeinfo > p")?.text.replace("作者：", "") || ""
      });
    }
    return { list, hasNextPage: false };
  }

    async search(query) {
        if (!query) return await this.getPopular();
        const res = await this.client.post("http://www.rumanhua1.com/s", 
        {"Content-Type": "application/x-www-form-urlencoded"},
        `k=${encodeURIComponent(query)}`);
        console.log(res.body);
        const doc = new Document(res.body);
        const list = [];
        
        for (const el of doc.select(".item-data .col-auto")) { 
        const a = el.selectFirst("a");
        if (!a) continue;
        const url = "/" + a.attr("href").replace(/^\/|\/$/g, "") + "/";
        let img = el.selectFirst("img")?.attr("data-src") || "";
        if (img.startsWith("//")) img = "http:" + img;
        list.push({
            name: el.selectFirst(".e-title, .title")?.text || "",
            imageUrl: img,
            link: url,
            author: el.selectFirst(".tip")?.text || ""
        });
        }
        return { list, hasNextPage: false };
    }

    async getDetail(url) {
        const mangaId = url.replace(/^\/|\/$/g, "");
        const res = await this.client.get(`http://www.rumanhua1.com/${mangaId}/`, this.getHeaders());
        const doc = new Document(res.body);
        const info = doc.selectFirst(".comicInfo");
        if (!info) return { chapters: [] };
        
        let img = info.selectFirst("img")?.attr("data-src") || "";
        if (img.startsWith("//")) img = "http:" + img;
        
        const detContainer = info.selectFirst(".detinfo");
        const title = detContainer?.selectFirst("h1")?.text || "";
        let author = "", genres = [], status = 0, updated = "", contentDesc = "";
        
        if (detContainer) {
            contentDesc = detContainer.selectFirst(".content")?.text || "";
            for (const span of detContainer.select("span")) {
                const txt = span.text.trim();
                if (txt.startsWith("作  者："))
                    author = txt.replace("作  者：", "").trim();
                else if (txt.startsWith("状  态："))
                    status = txt.includes("连载") ? 0 : 1;
                else if (txt.startsWith("标  签："))
                    genres = txt.replace("标  签：", "").trim().split(/\s+/).filter(Boolean);
                else if (/更新/.test(txt))
                    updated = txt;
            }
        }
        
        let chapters = [];
        const chapterContainer = doc.selectFirst(".chapterlistload");
        if (chapterContainer) {
            const chapterElements = chapterContainer.select("ul a");
            for (const element of chapterElements) {
                const href = element.attr("href");
                if (href) {
                    chapters.push({
                        name: element.text.trim(),
                        url: href.replace(/^\/|\/$/g, "").replace(/\.html$/, "")
                    });
                }
            }
            
            if (chapterContainer.selectFirst(".chaplist-more")) {
                const moreRes = await this.client.post(
                    `http://www.rumanhua1.com/morechapter`, 
                    {"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"},
                    `id=${encodeURIComponent(mangaId)}`
                );
                const parsed = JSON.parse(moreRes.body);
                if (parsed && parsed.code === "200" && Array.isArray(parsed.data)) {
                    chapters.push(...parsed.data.map(c => ({
                        name: c.chaptername || "",
                        url: c.chapterid || ""
                    })));
                }
            }
        }
        
        const description = (contentDesc || "") + (updated ? ("\n" + updated) : "");
        return {
            name: title,
            imageUrl: img,
            description,
            genre: genres,
            author,
            status,
            chapters
        };
    }

    async getPageList(mangaId) {
        const res = await this.client.get(`http://www.rumanhua1.com/${mangaId}.html`, this.getHeaders());
        const doc = new Document(res.body);
        
        const scripts = doc.select("script[type='text/javascript']");
        
        let obfuscatedScript = null;
        for (const script of scripts) {
            const scriptText = script.text;
            if (scriptText.includes("eval(function(p,a,c,k,e,d")) {
                obfuscatedScript = scriptText;
                break;
            }
        }
        
        if (!obfuscatedScript) {
            console.error('No obfuscated script found.');
            return [];
        }
        
        const unpackedCode = unpack(obfuscatedScript);
        const match = unpackedCode.match(/var\s+\w+\s*=\s*["']([\s\S]*?)["'];?/);
        const encrypted = match ? match[1] : null;
        
        if (encrypted) {
            const decodedData = decode(encrypted);
            console.log('Decoded Data:', JSON.stringify(decodedData));
            return decodedData;
        }
        
        console.error('No encrypted data found.');  
        return [];
    }

}

function main(source) {
  const ext = new DefaultExtension();
  ext.source = source;
  return ext;
}


class Unbaser {
    constructor(base) {
        this.ALPHABET = {
            62: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
            95: "' !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'",
        };
        this.dictionary = {};
        this.base = base;
        if (36 < base && base < 62) {
            this.ALPHABET[base] = this.ALPHABET[base] ||
                this.ALPHABET[62].substr(0, base);
        }
        if (2 <= base && base <= 36) {
            this.unbase = (value) => parseInt(value, base);
        }
        else {
            try {
                [...this.ALPHABET[base]].forEach((cipher, index) => {
                    this.dictionary[cipher] = index;
                });
            }
            catch (er) {
                throw Error("Unsupported base encoding.");
            }
            this.unbase = this._dictunbaser;
        }
    }
    _dictunbaser(value) {
        let ret = 0;
        [...value].reverse().forEach((cipher, index) => {
            ret = ret + ((Math.pow(this.base, index)) * this.dictionary[cipher]);
        });
        return ret;
    }
}

function detect(source) {
    return source.replace(" ", "").startsWith("eval(function(p,a,c,k,e,");
}

function unpack(source) {
    let { payload, symtab, radix, count } = _filterargs(source);
    if (count != symtab.length) {
        throw Error("Malformed p.a.c.k.e.r. symtab.");
    }
    let unbase;
    try {
        unbase = new Unbaser(radix);
    }
    catch (e) {
        throw Error("Unknown p.a.c.k.e.r. encoding.");
    }
    function lookup(match) {
        const word = match;
        let word2;
        if (radix == 1) {
            word2 = symtab[parseInt(word)];
        }
        else {
            word2 = symtab[unbase.unbase(word)];
        }
        return word2 || word;
    }
    source = payload.replace(/\b\w+\b/g, lookup);
    return _replacestrings(source);
    function _filterargs(source) {
        const juicers = [
            /}\('(.*)', *(\d+|\[\]), *(\d+), *'(.*)'\.split\('\|'\), *(\d+), *(.*)\)\)/,
            /}\('(.*)', *(\d+|\[\]), *(\d+), *'(.*)'\.split\('\|'\)/,
        ];
        for (const juicer of juicers) {
            const args = juicer.exec(source);
            if (args) {
                let a = args;
                if (a[2] == "[]") {
                }
                try {
                    return {
                        payload: a[1],
                        symtab: a[4].split("|"),
                        radix: parseInt(a[2]),
                        count: parseInt(a[3]),
                    };
                }
                catch (ValueError) {
                    throw Error("Corrupted p.a.c.k.e.r. data.");
                }
            }
        }
        throw Error("Could not make sense of p.a.c.k.e.r data (unexpected code structure)");
    }
    function _replacestrings(source) {
        return source;
    }
}

function decode(_0x4a8b2c) {
  const _0x3f2d1a = [
    "jsjiami.com.v6","wpbDtsKEw51r","csK+w5vDong=","WlRcGsKl","bcO/w7JNwq4=","wo1dGcK5wrY=","w4MywrYwwpM=","wpE7GcKOwr8=","w53CksKNw6Nhw6bCi8OJd8KbSj/DtsK4PMOUAkLCg8KYwowKwrROcMKjwowtRMK2BsKjS8Kjw4HDryFA","UcKOw6PDtlXDgj7CgCoLwoDCsw==","XMKJdsO3LA==","w5vCm8O5KsOEw6rDthI6","wqNww71YwqMEClXCsArDu0XDgjfCngg4VMK+w4Msw791wrPChMKiwq4eG8K1w6TDpQZcVsOcw6IMwoTDslbCjMKmw5rCtGkOwoJZw49qwqVVwr/DocOWA8OhZCPCpXjCssOSw7w=","OcKRU8OGwqXCr8K3SsK0w7d8w5UkwpDCjy8=","woA4T8O9bsO8wocfLHnDuCc=","wqXCpcOwwroWwoVRAQkEw7Mj","w7wQDzozwoAHS8K7bMKTw64=","w5fDlcK3w5XCug==","w55Ww5dqw4YhIXzCijPCjSvDrBHCsCgdY8KfwroQw4RFw4bCv8KXwrdeRsOtw6jDrgYUW8OXw70Bw4TDr0vCn8Oqwoo=","w7bDo2YMccKxwrjDrG5IGgctwohXOsO+wpF9bMOSw7DDs17DlMKPAMKqw4I/w75kHMOoAGsfw54=","RcKgw6fDjXs=","w5HDnHXCjsODw7xE","w4ocwqQDwpjCig==","GMKybcOcw6zCpsOS","MzNHd8KpTg==","w5vDmnDCmcO6w4c=","wpvDhcKEN8OVdsKt","PcO7wq95woTChA==","L8ObwrTCpzw=","woXCpnYGVw==","MUlpwrPCqg==","Z3fDl8K0Jw==","wqbDrsKGG8Ol","wrMwLsKAwq0=","woTDkw3DsH0=","RlxcJsKt","wrRYYcKrAg==","wp13csK3HQ==","wrTDssKaJ8O4","Mn5OwrNXwoU=","w7LDkhQA","ZsK0ZcOlwps=","wonClzp1","w5BlSjgzwo9ZAsK6acOJw64=","Xx4qBjDCvE3CkcOfc8OVw44=","w6HCgEPCgcOYwoFwwp7Ch8KhQm0=","w4vDnUPCnMO2","ayp3ZMKuwoE4w4nDh3hlw4s=","w5w5w40rwo8=","cntvAiTClmTDk8OkVcOnw44=","WMOOw6ZjwrkR","VWhhOAM=","W8KZw6LDvGLDgg==","wovDv8KqH8Os","PnTCtcKSw4HCu3BjwpPCvcOYw7Y=","McOJwq7CshQ=","woBxNcKbwq/Cu8O8A8KbbA==","woLDisKSIcOI","w4URwqsWwq3Clg==","bjsjHBiHBIamlKzFSLi.rcom.v6=="
  ];
  
  (function(_0x2e4f18, _0x1c9d3e, _0x5a7b2f) {
    const _0x3d8c1b = function(_0x4b2e5f, _0x2d1a3c, _0x1f8e4d, _0x3a9b2e, _0x5c1d4f, _0x2b3e1a) {
      _0x2d1a3c = _0x2d1a3c >> 8;
      _0x5c1d4f = "po";
      const _0x4e2d1c = "shift", _0x1a3f2e = "push", _0x3c4b5d = "‮";
      if (_0x2d1a3c < _0x4b2e5f) {
        while (--_0x4b2e5f) {
          _0x3a9b2e = _0x2e4f18[_0x4e2d1c]();
          if (_0x2d1a3c === _0x4b2e5f && _0x3c4b5d === "‮" && _0x3c4b5d.length === 1) {
            _0x2d1a3c = _0x3a9b2e;
            _0x1f8e4d = _0x2e4f18[_0x5c1d4f + "p"]();
          } else if (_0x2d1a3c && _0x1f8e4d.replace(/[bHBHBIlKzFSLr=]/g, "") === _0x2d1a3c) {
            _0x2e4f18[_0x1a3f2e](_0x3a9b2e);
          }
        }
        _0x2e4f18[_0x1a3f2e](_0x2e4f18[_0x4e2d1c]());
      }
      return 978102;
    };
    return _0x3d8c1b(++_0x1c9d3e, _0x5a7b2f) >> _0x1c9d3e ^ _0x5a7b2f;
  })(_0x3f2d1a, 185, 47360);
  
  const _0x5e1f2a = _0x3f2d1a.length ^ 185;
  
  const _0x1d4c3b = function(_0x2a1e3f, _0x4c2d1e) {
    _0x2a1e3f = ~~`0x${_0x2a1e3f.slice(1)}`;
    let _0x3b4e2d = _0x3f2d1a[_0x2a1e3f];
    
    if (_0x1d4c3b.BZQWxr === void 0) {
      (function() {
        const _0x5a2c1d = typeof window !== "undefined" ? window : typeof process === "object" && typeof require === "function" && typeof global === "object" ? global : this;
        const _0x4b3e2c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
        _0x5a2c1d.atob = function(_0x3e1d4f) {
          const _0x2c4b3e = String(_0x3e1d4f).replace(/=+$/, "");
          let _0x1c3d2e = "";
          for (let _0x1f3e2d = 0, _0x4e2c1b, _0x3d1e4c, _0x2b4e1a = 0; _0x3d1e4c = _0x2c4b3e.charAt(_0x2b4e1a++); ~_0x3d1e4c && (_0x4e2c1b = _0x1f3e2d % 4 ? _0x4e2c1b * 64 + _0x3d1e4c : _0x3d1e4c, _0x1f3e2d++ % 4) ? _0x1c3d2e += String.fromCharCode(_0x4e2c1b >> (_0x1f3e2d * -2 & 6) & 255) : 0) {
            _0x3d1e4c = _0x4b3e2c.indexOf(_0x3d1e4c);
          }
          return _0x1c3d2e;
        };
      })();
      
      const _0x2e4d1c = function(_0x3a2e1d, _0x4b3d2c) {
        const _0x1c2e3d = [];
        let _0x5e2d1a = 0;
        let _0x4a1e3b;
        let _0x2d3c1e = "";
        let _0x3e2b4d = "";
        _0x3a2e1d = atob(_0x3a2e1d);
        for (let _0x1d4e2c = 0, _0x2c1a3e = _0x3a2e1d.length; _0x1d4e2c < _0x2c1a3e; _0x1d4e2c++) {
          _0x3e2b4d += "%" + ("00" + _0x3a2e1d.charCodeAt(_0x1d4e2c).toString(16)).slice(-2);
        }
        _0x3a2e1d = decodeURIComponent(_0x3e2b4d);
        for (let _0x4e2d3c = 0; _0x4e2d3c < 256; _0x4e2d3c++) {
          _0x1c2e3d[_0x4e2d3c] = _0x4e2d3c;
        }
        for (let _0x4e2d3c = 0; _0x4e2d3c < 256; _0x4e2d3c++) {
          _0x5e2d1a = (_0x5e2d1a + _0x1c2e3d[_0x4e2d3c] + _0x4b3d2c.charCodeAt(_0x4e2d3c % _0x4b3d2c.length)) % 256;
          _0x4a1e3b = _0x1c2e3d[_0x4e2d3c];
          _0x1c2e3d[_0x4e2d3c] = _0x1c2e3d[_0x5e2d1a];
          _0x1c2e3d[_0x5e2d1a] = _0x4a1e3b;
        }
        let _0x4e2d3c = 0;
        _0x5e2d1a = 0;
        for (let _0x2b1e4c = 0; _0x2b1e4c < _0x3a2e1d.length; _0x2b1e4c++) {
          _0x4e2d3c = (_0x4e2d3c + 1) % 256;
          _0x5e2d1a = (_0x5e2d1a + _0x1c2e3d[_0x4e2d3c]) % 256;
          _0x4a1e3b = _0x1c2e3d[_0x4e2d3c];
          _0x1c2e3d[_0x4e2d3c] = _0x1c2e3d[_0x5e2d1a];
          _0x1c2e3d[_0x5e2d1a] = _0x4a1e3b;
          _0x2d3c1e += String.fromCharCode(_0x3a2e1d.charCodeAt(_0x2b1e4c) ^ _0x1c2e3d[(_0x1c2e3d[_0x4e2d3c] + _0x1c2e3d[_0x5e2d1a]) % 256]);
        }
        return _0x2d3c1e;
      };
      
      _0x1d4c3b.RFtTHu = _0x2e4d1c;
      _0x1d4c3b.KEpAmN = {};
      _0x1d4c3b.BZQWxr = !0;
    }
    
    const _0x4e3d2c = _0x1d4c3b.KEpAmN[_0x2a1e3f];
    if (_0x4e3d2c === void 0) {
      if (_0x1d4c3b.CwFFPP === void 0) {
        _0x1d4c3b.CwFFPP = !0;
      }
      _0x3b4e2d = _0x1d4c3b.RFtTHu(_0x3b4e2d, _0x4c2d1e);
      _0x1d4c3b.KEpAmN[_0x2a1e3f] = _0x3b4e2d;
    } else {
      _0x3b4e2d = _0x4e3d2c;
    }
    return _0x3b4e2d;
  };
  
  const _0x3c2e4d = function(_0x4d3e2a, _0x2e1c4b) {
    const _0x1e4c3d = {Qcdqx: _0x1d4c3b("\u202B7", "Aykh")};
    const _0x4a2e1d = _0x2e1c4b[_0x1d4c3b("\u202E8", "K4F0")];
    let _0x3e2d1c, _0x2c4e1a, _0x1d3e2b, _0x4e1c3d, _0x2a4e1c, _0x3d2e1a, _0x1c4e3b, _0x4e2d3a;
    let _0x2e4c1d = 0, _0x3c1e2d = 0, _0x1d2e4c = "", _0x4e3c2d = [];
    
    if (!_0x4d3e2a) return _0x4d3e2a;
    _0x4d3e2a += "";
    
    do {
      _0x4e1c3d = _0x4a2e1d[_0x1d4c3b("\u202E9", "#YOq")](_0x4d3e2a[_0x1d4c3b("\u202Ea", "3DFV")](_0x2e4c1d++));
      _0x2a4e1c = _0x4a2e1d[_0x1d4c3b("\u202Eb", "w2OY")](_0x4d3e2a[_0x1d4c3b("\u202Ec", "b&Qr")](_0x2e4c1d++));
      _0x3d2e1a = _0x4a2e1d.indexOf(_0x4d3e2a[_0x1d4c3b("\u202Ed", "#YOq")](_0x2e4c1d++));
      _0x1c4e3b = _0x4a2e1d[_0x1d4c3b("\u202Ee", "JxZa")](_0x4d3e2a[_0x1d4c3b("\u202Ef", "&T[E")](_0x2e4c1d++));
      _0x4e2d3a = _0x2e1c4b.utMCl(_0x2e1c4b[_0x1d4c3b("\u202E10", "nbJx")](_0x2e1c4b[_0x1d4c3b("\u202E11", "Aykh")](_0x4e1c3d, 18) | _0x2e1c4b[_0x1d4c3b("\u202E12", "sL23")](_0x2a4e1c, 12), _0x2e1c4b.WqTyQ(_0x3d2e1a, 6)), _0x1c4e3b);
      _0x3e2d1c = _0x2e1c4b[_0x1d4c3b("\u202E13", "TF]V")](_0x2e1c4b[_0x1d4c3b("\u202E14", "JxZa")](_0x4e2d3a, 16), 255);
      _0x2c4e1a = _0x2e1c4b[_0x1d4c3b("\u202E15", "uikU")](_0x2e1c4b.TEfIH(_0x4e2d3a, 8), 255);
      _0x1d3e2b = _0x2e1c4b[_0x1d4c3b("\u202E16", "zzoR")](_0x4e2d3a, 255);
      
      if (_0x2e1c4b.zHmTm(_0x3d2e1a, 64)) {
        _0x4e3c2d[_0x3c1e2d++] = String.fromCharCode(_0x3e2d1c);
      } else if (_0x2e1c4b[_0x1d4c3b("\u202E1a", "JxZa")](_0x1c4e3b, 64)) {
        _0x4e3c2d[_0x3c1e2d++] = String.fromCharCode(_0x3e2d1c, _0x2c4e1a);
      } else {
        _0x4e3c2d[_0x3c1e2d++] = String.fromCharCode(_0x3e2d1c, _0x2c4e1a, _0x1d3e2b);
      }
    } while (_0x2e1c4b.iDzLi(_0x2e4c1d, _0x4d3e2a[_0x1d4c3b("\u202E1b", "(WP^")]));
    
    _0x1d2e4c = _0x4e3c2d[_0x1d4c3b("\u202E1c", "fYo#")]("");
    return _0x1d2e4c;
  };
  
  const _0x2e1c4b = {
    gzHdY: _0x1d4c3b("\u202B0", "&SK*"),
    utMCl: function(_0x1a, _0x2b) { return _0x1a | _0x2b; },
    vgqOC: function(_0x1c, _0x2d) { return _0x1c | _0x2d; },
    QecxE: function(_0x1e, _0x2e) { return _0x1e << _0x2e; },
    WqTyQ: function(_0x1f, _0x2f) { return _0x1f << _0x2f; },
    AgFWF: function(_0x3a, _0x3b) { return _0x3a & _0x3b; },
    TEfIH: function(_0x3c, _0x3d) { return _0x3c >> _0x3d; },
    TAVIP: function(_0x3e, _0x3f) { return _0x3e & _0x3f; },
    zHmTm: function(_0x4a, _0x4b) { return _0x4a == _0x4b; },
    tDzsM: function(_0x4c, _0x4d) { return _0x4c === _0x4d; },
    xLwmg: "nEEWq",
    FYzuU: function(_0x4e, _0x4f) { return _0x4e == _0x4f; },
    iDzLi: function(_0x5a, _0x5b) { return _0x5a < _0x5b; },
    eTWDI: function(_0x5c, _0x5d) { return _0x5c(_0x5d); },
    qWSBZ: _0x1d4c3b("\u202E1", "hNnh"),
    QlgUw: _0x1d4c3b("\u202B2", "%m[D"),
    hddam: "dmJmc2EyNTY=",
    soRwM: _0x1d4c3b("\u202B3", "ems^"),
    UJGLi: _0x1d4c3b("\u202B4", "P%H%"),
    cNKXu: "ZHNvMTV0bG8=",
    yTJMA: function(_0x5d, _0x5e) { return _0x5d % _0x5e; },
    hukZk: function(_0x5f, _0x6a) { return _0x5f ^ _0x6a; },
    PdtKZ: function(_0x6b, _0x6c) { return _0x6b !== _0x6c; },
    hLzOE: _0x1d4c3b("\u202E5", "s#ic"),
    nDMPZ: function(_0x6d, _0x6e) { return _0x6d + _0x6e; },
    RmRio: function(_0x6f, _0x7a) { return _0x6f + _0x7a; },
    jFsAJ: function(_0x7b, _0x7c) { return _0x7b + _0x7c; },
    clqYT: _0x1d4c3b("\u202E6", "&SK*"),
    SdgUu: function(_0x7d, _0x7e) { return _0x7d(_0x7e); }
  };
  
  const _0x4e2c3d = [
    _0x1d4c3b("\u202B1f", "P%H%"),
    _0x1d4c3b("\u202E20", "Eh%@"),
    _0x2e1c4b.QlgUw,
    _0x1d4c3b("\u202E21", "#YOq"),
    _0x2e1c4b.hddam,
    _0x2e1c4b[_0x1d4c3b("\u202E22", "#YOq")],
    _0x1d4c3b("\u202B23", "]ZXp"),
    _0x2e1c4b.UJGLi,
    _0x2e1c4b[_0x1d4c3b("\u202E24", "db#q")],
    _0x1d4c3b("\u202E25", "Eh%@")
  ];
  
  const _0x1a2e3d = _0x3c2e4d(_0x4a8b2c, _0x2e1c4b);
  
  for (let _0x2c3e4d = 0; _0x2c3e4d < _0x4e2c3d.length; _0x2c3e4d++) {
    try {
      const _0x3d4e2c = _0x4e2c3d[_0x2c3e4d];
      const _0x4e1c2d = _0x3c2e4d(_0x3d4e2c, _0x2e1c4b);
      let _0x2e3c4d = "";
      
      for (let _0x1c2e4d = 0; _0x1c2e4d < _0x1a2e3d.length; _0x1c2e4d++) {
        const _0x3e2d4c = _0x1c2e4d % _0x4e1c2d.length;
        _0x2e3c4d += String.fromCharCode(_0x1a2e3d.charCodeAt(_0x1c2e4d) ^ _0x4e1c2d.charCodeAt(_0x3e2d4c));
      }
      
      const _0x4c2e3d = _0x3c2e4d(_0x2e3c4d, _0x2e1c4b);
      const _0x1e2c4d = JSON.parse(_0x4c2e3d);
      return _0x1e2c4d;
    } catch (_0x2d4e3c) {}
  }
  
  throw new Error('No candidate produced valid JSON.');
}

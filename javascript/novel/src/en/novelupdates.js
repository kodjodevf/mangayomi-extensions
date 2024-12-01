const mangayomiSources = [{
    "name": "Novel Updates",
    "lang": "en",
    "baseUrl": "https://novelupdates.com",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/Schnitzel5/mangayomi-extensions/main/javascript/icon/en.novelupdates.png",
    "typeSource": "single",
    "itemType": 2,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "novel/src/en/novelupdates.js",
    "appMinVerReq": "0.3.75"
}];

class DefaultExtension extends MProvider {
    getHeaders(url) {
        return {
            Referer: this.source.baseUrl
        };
    }
    mangaListFromPage(res) {
        const doc = new Document(res.body);
        const mangaElements = doc.select("div.grid > div.search_main_box_nu");
        const list = [];
        for (const element of mangaElements) {
            const name = element.selectFirst(".search_title > a").text;
            const imageUrl = element.selectFirst("img").getSrc;
            const link = element.selectFirst(".search_title > a").getHref.replace("https://novelupdates.com/", "");
            list.push({ name, imageUrl, link });
        }
        const hasNextPage = doc.selectFirst("div.digg_pagination > a.next_page").text == " →";
        return { "list": list, hasNextPage };
    }
    toStatus(status) {
        if (status.includes("Ongoing"))
            return 0;
        else if (status.includes("Completed"))
            return 1;
        else if (status.includes("Hiatus"))
            return 2;
        else if (status.includes("Dropped"))
            return 3;
        else
            return 5;
    }
    parseDate(date) {
        const months = {
            "january": "01", "february": "02", "march": "03", "april": "04",
            "may": "05", "june": "06", "july": "07", "august": "08",
            "september": "09", "october": "10", "november": "11", "december": "12"
        };
        date = date.toLowerCase().replace(/(st|nd|rd|th)/g, "").split(" ");
        if (!(date[0] in months)) {
            return String(new Date().valueOf());
        }
        date[0] = months[date[0]];
        const formattedDate = `${date[2]}-${date[0]}-${date[1].padStart(2, "0")}`; // Format YYYY-MM-DD
        return String(new Date(formattedDate).valueOf());
    }

    async getPopular(page) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(`${baseUrl}/series-ranking/?rank=popmonth&pg=${page}`);
        return this.mangaListFromPage(res);
    }

    async getLatestUpdates(page) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(`${baseUrl}/series-finder/?sf=1&sh=&sort=sdate&order=desc&pg=${page}`);
        return this.mangaListFromPage(res);
    }
    async search(query, page, filters) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(`${baseUrl}/series-finder/?sf=1&sh=${query}&sort=sdate&order=desc&pg=${page}`);
        return this.mangaListFromPage(res);
    }

    async getDetail(url) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(baseUrl + "/" + url);
        const doc = new Document(res.body);
        const imageUrl = doc.selectFirst(".wpb_wrapper img")?.getSrc;
        const type = doc.selectFirst("#showtype")?.text.trim();
        const description = doc.selectFirst("#editdescription")?.text.trim() + `\n\nType: ${type}`;
        const author = doc.select("#authtag").map((el) => el.text.trim()).join(", ");
        const artist = doc.select("#artiststag").map((el) => el.text.trim()).join(", ");
        const status = this.toStatus(doc.selectFirst("#editstatus").text.trim());
        const genre = doc.select("#seriesgenre > a")
        .map((el) => el.text.trim());

        const novelId = doc.selectFirst("input#mypostid")?.attr("value");
        const formData = new FormData();
        formData.append('action', 'nd_getchapters');
        formData.append('mygrr', '0');
        formData.append('mypostid', novelId);
    
        const link = `${baseUrl}/wp-admin/admin-ajax.php`;

        const headers = {
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            'Referer': baseUrl + "/" + url,
        };
    
        const chapters = [];
        const chapterRes = await client.post(link, headers, formData);
        const chapterDoc = new Document(chapterRes.body);

        const nameReplacements = {
            'v': 'volume ',
            'c': ' chapter ',
            'part': 'part ',
            'ss': 'SS',
          };

        chapterDoc.select("li.sp_li_chp").forEach((el) => {
            let chapterName = el.text;
            for (const name in nameReplacements) {
                chapterName = chapterName.replace(name, nameReplacements[name]);
            }
            chapterName = chapterName.replace(/\b\w/g, l => l.toUpperCase()).trim();
            const chapterUrl = `https:${el.select("a")[1].attr("href")}`;
            const dateUpload = String(Date.now());
            chapters.push({ chapterName, chapterUrl, dateUpload });
        });

        return {
            imageUrl,
            description,
            genre,
            author,
            artist,
            status,
            chapters
        };
    }

    async getPageList(url) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(baseUrl + "/series/" + url);
        const scriptData = new Document(res.body).select("script:contains(self.__next_f.push)").map((e) => e.text.substringAfter("\"").substringBeforeLast("\"")).join("");
        console.log(scriptData);
        const match = scriptData.match(/\\"pages\\":(\[.*?])/);
        if (!match) {
            throw new Error("Failed to find chapter pages");
        }
        const pagesData = match[1];

        const pageList = JSON.parse(pagesData.replace(/\\(.)/g, "$1"))
            .sort((a, b) => a.order - b.order);
        return pageList;
    }

    getSourcePreferences() {
        return [{
            "key": "overrideBaseUrl1",
            "editTextPreference": {
                "title": "Override BaseUrl",
                "summary": "https://novelupdates.com",
                "value": "https://novelupdates.com",
                "dialogTitle": "Override BaseUrl",
                "dialogMessage": "",
            }
        }];
    }

}
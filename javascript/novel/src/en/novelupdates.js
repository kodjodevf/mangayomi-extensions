const mangayomiSources = [{
    "name": "Novel Updates",
    "lang": "en",
    "baseUrl": "https://novelupdates.com",
    "apiUrl": "",
    "iconUrl": "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/javascript/icon/en.novelupdates.png",
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
        const mangaElements = doc.select("div.grid > a[href]");
        const list = [];
        for (const element of mangaElements) {
            const name = element.selectFirst("span.block").text;
            const imageUrl = element.selectFirst("img").getSrc;
            const link = element.getHref;
            list.push({ name, imageUrl, link });
        }
        const hasNextPage = doc.selectFirst("a.flex.bg-themecolor:contains(Next)").text != "";
        return { "list": list, hasNextPage };
    }
    toStatus(status) {
        if (status == "Ongoing")
            return 0;
        else if (status == "Completed")
            return 1;
        else if (status == "Hiatus")
            return 2;
        else if (status == "Dropped")
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
        const res = await new Client().get(`${baseUrl}/series?name=&status=-1&types=-1&order=rating&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getLatestUpdates(page) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(`${baseUrl}/series?genres=&status=-1&types=-1&order=update&page=${page}`);
        return this.mangaListFromPage(res);
    }
    async search(query, page, filters) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(`${baseUrl}/series?name=${query}&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getDetail(url) {
        const baseUrl = new SharedPreferences().get("overrideBaseUrl1");
        const res = await new Client().get(baseUrl + "/" + url);
        const doc = new Document(res.body);
        const imageUrl = doc.selectFirst("img[alt=poster]")?.getSrc;
        const description = doc.selectFirst("span.font-medium.text-sm")?.text.trim();
        const author = doc.selectFirst("h3:contains('Author')").nextElementSibling.text.trim();
        const artist = doc.selectFirst("h3:contains('Artist')").nextElementSibling.text.trim();
        const status = this.toStatus(doc.selectFirst("h3:contains('Status')").nextElementSibling.text.trim());
        const genre = doc.select("div[class^=space] > div.flex > button.text-white")
            .map((el) => el.text.trim());
        const chapters = [];
        const chapterElements = doc.select("div.scrollbar-thumb-themecolor > div.group");
        for (const element of chapterElements) {
            const url = element.selectFirst("a").getHref;
            const chNumber = element.selectFirst("h3 > a").text;
            const chTitle = element.select("h3 > a > span").map((span) => span.text.trim()).join(" ").trim();
            const name = chTitle == "" ? chNumber : `${chNumber} - ${chTitle}`;

            let dateUpload;
            try {
                const dateText = element.selectFirst("h3 + h3").text.trim();
                const cleanDateText = dateText.replace(/(\d+)(st|nd|rd|th)/, "$1");
                dateUpload = this.parseDate(cleanDateText);
            } catch (_) {
                dateUpload = null
            }
            chapters.push({ name, url, dateUpload });
        }
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
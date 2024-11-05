const mangayomiSources = [{
    "name": "Mangafire",
    "langs": ["en", "ja", "fr", "es", "es-la", "pt", "pt-br"],
    "baseUrl": "https://mangafire.to",
    "apiUrl": "",
    "iconUrl": "https://mangafire.to/assets/sites/mangafire/favicon.png?v3",
    "typeSource": "single",
    "isManga": true,
    "version": "0.1.0",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/all/mangafire.js"
}];

class DefaultExtension extends MProvider {
    mangaListFromPage(res) {
        const doc = new Document(res.body);
        const elements = doc.select("div.unit");
        const list = [];

        for (const element of elements){
          const name = element.selectFirst("div.info > a").text;
          const imageUrl = element.selectFirst("img").getSrc;
          const link = element.selectFirst("a").getHref;
          list.push({name, imageUrl, link});
        }

        const hasNextPage = doc.selectFirst("li.page-item.active + li").text != "";
        return { "list": list, "hasNextPage": hasNextPage };
    }

    statusFromString(status){
        if (status == "Releasing")
            return 0;
        else if (status == "Completed")
            return 1;
        else if (status == "On_Hiatus")
            return 2;
        else if (status == "Discontinued")
            return 3;
        else
            return 5;
    }

    parseDate(date) {
        const months = {
          "jan": "01", "feb": "02", "mar": "03", "apr": "04", "may": "05", "jun": "06", "jul": "07", "aug": "08", "sep": "09", "oct": "10", "nov": "11", "dec": "12"
        };
        date = date.toLowerCase().replace(",", "").split(" ");

        if (!(date[0] in months)) {
            return String(new Date().valueOf())
        }
        
        date[0] = months[date[0]];
        date = [date[2], date[0], date[1]];
        date = date.join("-");
        return String(new Date(date).valueOf());
    }

    async getPopular(page) {
        console.log(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=trending&page=${page}`);
        const res = await new Client().get(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=trending&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getLatestUpdates(page) {
        const res = await new Client().get(`${this.source.baseUrl}/filter?keyword=&language=${this.source.lang}&sort=recently_updated&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async search(query, page, filters) {
        query = query.trim().replaceAll(/\ +/g, "+");
        let url = `${this.source.baseUrl}/filter?keyword=${query}`;

        for (const filter of filters[0].state) {
            if (filter.state == true)
                url += `&type%5B%5D=${filter.value}`;
        }

        for (const filter of filters[1].state) {
            if (filter.state == 1)
                url += `&genre%5B%5D=${filter.value}`;
            else if (filter.state == 2)
                url += `&genre%5B%5D=-${filter.value}`;
        }

        // &genre_mode=and

        for (const filter of filters[2].state) {
            if (filter.state == true)
                url += `&status%5B%5D=${filter.value}`;
        }

        url += `&language=${this.source.lang}`;
        url += `&minchap=${filters[3].values[filters[3].state].value}`;
        url += `&sort=${filters[4].values[filters[4].state].value}`;

        const res = await new Client().get(`${url}&page=${page}`);
        return this.mangaListFromPage(res);
    }

    async getDetail(url) {
        // get urls
        const id = url.split(".").pop();
        const infoUrl = this.source.baseUrl + url;
        const chapterUrl = `https://mangafire.to/ajax/read/${id}/chapter/${this.source.lang}`;
        const detail = {};
        
        // request
        const idRes = await new Client().get(chapterUrl);
        const idDoc = new Document(JSON.parse(idRes.body).result.html);
        const infoRes = await new Client().get(infoUrl);
        const infoDoc = new Document(infoRes.body);
        
        // extract info
        const info = infoDoc.selectFirst("div.info");
        const sidebar = infoDoc.select("aside.sidebar div.meta div");
        detail.name = info.selectFirst("h1").text;
        detail.status = this.statusFromString(info.selectFirst("p").text);
        detail.imageUrl = infoDoc.selectFirst("div.poster img").getSrc;
        detail.author = sidebar[0].selectFirst("a").text;
        detail.description = infoDoc.selectFirst("div#synopsis").text.trim();
        detail.genre = sidebar[2].select("a");
        detail.genre.forEach((e, i) => {
            detail.genre[i] = e.text;
        });

        // get chapter
        const ids = idDoc.select("a");
        const dates = infoDoc.select("div.list-body > ul.scroll-sm > li > a > span + span");
        detail.chapters = [];
        for (let i = 0; i < ids.length; i++) {
            const name = ids[i].text;
            const id = ids[i].attr("data-id");
            const url = `https://mangafire.to/ajax/read/chapter/${id}`;
            const dateUpload = this.parseDate(dates[i].text);
            detail.chapters.push({name, url, dateUpload});
        }
        return detail;
    }

    // For manga chapter pages
    async getPageList(url) {
        const res = await new Client().get(url);
        const data = JSON.parse(res.body);
        const pages = [];
        data.result.images.forEach(img => {
            pages.push(img[0]);
        });
        return pages;
    }

    getFilterList() {
        return [
            {
                type_name: "GroupFilter",
                name: "Type",
                state: [
                    {
                        type_name: "CheckBox",
                        name: "Manga",
                        value: "manga"
                    },
                    {
                        type_name: "CheckBox",
                        name: "One-Shot",
                        value: "one_shot"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Doujinshi",
                        value: "doujinshi"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Novel",
                        value: "novel"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Manhwa",
                        value: "manhwa"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Manhua",
                        value: "manhua"
                    }
                ]
            },
            {
                type_name: "GroupFilter",
                name: "Genre",
                state: [
                    {
                    	type_name: "TriState",
                    	name: "Action",
                    	value: "1"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Adventure",
                    	value: "78"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Avant Garde",
                    	value: "3"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Boys Love",
                    	value: "4"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Comedy",
                    	value: "5"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Demons",
                    	value: "77"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Drama",
                    	value: "6"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Ecchi",
                    	value: "7"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Fantasy",
                    	value: "79"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Girls Love",
                    	value: "9"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Gourmet",
                    	value: "10"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Harem",
                    	value: "11"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Horror",
                    	value: "530"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Isekai",
                    	value: "13"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Iyashikei",
                    	value: "531"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Josei",
                    	value: "15"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Kids",
                    	value: "532"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Magic",
                    	value: "539"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Mahou Shoujo",
                    	value: "533"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Martial Arts",
                    	value: "534"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Mecha",
                    	value: "19"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Military",
                    	value: "535"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Music",
                    	value: "21"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Mystery",
                    	value: "22"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Parody",
                    	value: "23"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Psychological",
                    	value: "536"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Reverse Harem",
                    	value: "25"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Romance",
                    	value: "26"
                    },
                    {
                    	type_name: "TriState",
                    	name: "School",
                    	value: "73"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Sci-Fi",
                    	value: "28"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Seinen",
                    	value: "537"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Shoujo",
                    	value: "30"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Shounen",
                    	value: "31"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Slice of Life",
                    	value: "538"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Space",
                    	value: "33"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Sports",
                    	value: "34"
                    },
                    {
                    	type_name: "TriState",
                    	name: "SuperPower",
                    	value: "75"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Supernatural",
                    	value: "76"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Suspense",
                    	value: "37"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Thriller",
                    	value: "38"
                    },
                    {
                    	type_name: "TriState",
                    	name: "Vampire",
                    	value: "39"
                    }
                ]
            },
            {
                type_name: "GroupFilter",
                name: "Status",
                state: [
                    {
                        type_name: "CheckBox",
                        name: "Releasing",
                        value: "releasing"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Completed",
                        value: "completed"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Hiatus",
                        value: "on_hiatus"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Discontinued",
                        value: "discontinued"
                    },
                    {
                        type_name: "CheckBox",
                        name: "Not Yet Published",
                        value: "info"
                    }
                ]
            },
            {
                type_name: "SelectFilter",
                type: "length",
                name: "Length",
                values: [
                    {
                        type_name: "SelectOption",
                        name: ">= 1 chapters",
                        value: "1"
                    },
                    {
                        type_name: "SelectOption",
                        name: ">= 3 chapters",
                        value: "3"
                    },
                    {
                        type_name: "SelectOption",
                        name: ">= 5 chapters",
                        value: "5"
                    },
                    {
                        type_name: "SelectOption",
                        name: ">= 10 chapters",
                        value: "10"
                    },
                    {
                        type_name: "SelectOption",
                        name: ">= 20 chapters",
                        value: "20"
                    },
                    {
                        type_name: "SelectOption",
                        name: ">= 30 chapters",
                        value: "30"
                    },
                    {
                        type_name: "SelectOption",
                        name: ">= 50 chapters",
                        value: "50"
                    }
                ],
            },
            {
                type_name: "SelectFilter",
                type: "sort",
                name: "Sort",
                state: 3,
                values: [
                    {
                        type_name: "SelectOption",
                        name: "Added",
                        value: "recently_added"
                    },
                    {
                        type_name: "SelectOption",
                        name: "Updated",
                        value: "recently_updated"
                    },
                    {
                        type_name: "SelectOption",
                        name: "Trending",
                        value: "trending"
                    },
                    {
                        type_name: "SelectOption",
                        name: "Most Relevant",
                        value: "most_relevant"
                    },
                    {
                        type_name: "SelectOption",
                        name: "Name",
                        value: "title_az"
                    }
                ],
            }
        ];
    }

    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

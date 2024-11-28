const mangayomiSources = [{
    "name": "MangaWorld",
    "lang": "it",
    "baseUrl": "https://www.mangaworld.ac",
    "apiUrl": "",
    "iconUrl": "https://www.mangaworld.ac/public/assets/images/MangaWorldSquareLogo.png",
    "typeSource": "single",
    "isManga": true,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/it/mangaworld.js"
}];

class DefaultExtension extends MProvider {
    constructor () {
        super();
        this.client = new Client();
        this.getPageCount = /totalPages["']:\s*(\d+).*?page["']:\s*(\d+)/i; // totalPages:\s*(\d+).*?page:\s*(\d+)
        this.getMangas = /['"]mangas['"]:([\s\S]+?])\s*\}/i; // mangas:([\s\S]+?])\s*\}
        this.getManga = /manga['"]:\s*(\{[\S\s]*?\}),\s*['"]image/i; // manga:\s*(\{[\S\s]*?\}),\s*image
        this.getPages = /pages['"]:\s*(\{[\S\s]*?\})\s*\}/ // pages: ({[\S\s]*?})\s*}
        this.getChapter = /chapter['"]:\s*(\{[\S\s]*?\}),\s*['"]image/i; // chapter:\s*(\{[\S\s]*?\}),\s*image
        this.getCdn = /cdn_url["']:\s*["'](.+?)["']/i;
    }
    parseStatus(status) {
        return {
            'In corso': 0,
            'Finito': 1,
            'In pausa': 2,
            'Droppato': 3,
            'Cancellato': 3
        }[status] ?? 5;
    }
    async parseMangaList(url) {
        const res = await this.client.get(url);
        const json = this.getMangas.exec(res.body)[1];
        let mangas = JSON.parse(json).map(manga => ({
            name: manga.title,
            imageUrl: manga.imageT,
            author: manga.author.join(', '),
            artist: manga.artist.join(', '),
            status: this.parseStatus(manga.statusT),
            description: manga.trama,
            genre: manga.genres.map(g => g.name),
            link: `${this.source.baseUrl}/manga/${manga.linkId}/${manga.slug}`,
        }));
        const pageNums = this.getPageCount.exec(res.body);
        return { "list": mangas, "hasNextPage": pageNums[1] > pageNums[2] };
    }
    async getPopular(page) {
        return await this.parseMangaList(this.source.baseUrl + `/archive?sort=most_read&page=${page}`);
    }
    async getLatestUpdates(page) {
        return await this.parseMangaList(this.source.baseUrl + `/archive?sort=newest&page=${page}`);
    }
    async search(query, page, filters) {
        let url = `${this.source.baseUrl}/archive?keyword=${query}`
        // Search sometimes failed because filters were empty. I experienced this mostly on android...
        if (!filters || filters.length == 0) {
            return await this.parseMangaList(url + `&page=${page}`);
        }

        // type
        for (const filter of filters[0].state) {
            if (filter.state == true)
                url += `&type=${filter.value}`;
        }
        // genre
        for (const filter of filters[1].state) {
            if (filter.state == true)
                url += `&genre=${filter.value}`;
        }
        // status
        for (const filter of filters[2].state) {
            if (filter.state == true)
                url += `&status=${filter.value}`;
        }
        // year
        for (const filter of filters[3].state) {
            if (filter.state == true)
                url += `&year=${filter.value}`;
        }
        // sort
        url += `&sort=${filters[4].values[filters[4].state].value}`;
        return await this.parseMangaList(url + `&page=${page}`);
    }
    async getDetail(url) {
        const res = await this.client.get(url);
        const chapters = [];

        const manga = JSON.parse(this.getManga.exec(res.body)[1]);
        const pages = JSON.parse(this.getPages.exec(res.body)[1]);
        const baseUrl = `${this.source.baseUrl}/manga/${manga.linkId}/${manga.slug}/read/`;

        for (const v of pages.volumes) {
            for (const c of v.chapters) {
                chapters.push({
                    name: c.name,
                    url: baseUrl + c.id,
                    dateUpload: new Date(c.createdAt).valueOf().toString(),
                });
            }
        }
        for (const c of pages.singleChapters) {
            chapters.push({
                name: c.name,
                url: baseUrl + c.id,
                dateUpload: new Date(c.createdAt).valueOf().toString(),
            });
        }
        return {
            name: manga.title,
            imageUrl: manga.imageT,
            author: manga.author.join(', '),
            artist: manga.artist.join(', '),
            status: this.parseStatus(manga.statusT),
            description: manga.trama,
            genre: manga.genres.map(g => g.name),
            chapters: chapters
        };
    }
    // For manga chapter pages
    async getPageList(url) {
        const res = await new Client().get(url);
        const cdn = this.getCdn.exec(res.body)[1];
        const chapter = JSON.parse(this.getChapter.exec(res.body)[1]);
        const manga = chapter.manga;
        const volume = chapter.volume;
        const baseUrl = volume ?
            `${cdn}/chapters/${manga.slugFolder}-${manga.id}/${volume.slugFolder}-${volume.id}/${chapter.slugFolder}-${chapter.id}/` :
            `${cdn}/chapters/${manga.slugFolder}-${manga.id}/${chapter.slugFolder}-${chapter.id}/`;
        return chapter.pages.map(img => ({url: baseUrl + img}));
    }
    getFilterList() {
        return [
            {
                type_name: "GroupFilter",
                name: "Tipo",
                state: [
                    ['Manga', 'manga'],
                    ['Manhua', 'manhua'],
                    ['Manhwa', 'manhwa'],
                    ['Oneshot', 'oneshot']
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                name: "Generi",
                state: [
                    ['Adulti', 'adulti'],
                    ['Arti Marziali', 'arti-marziali'],
                    ['Avventura', 'avventura'],
                    ['Azione', 'azione'],
                    ['Commedia', 'commedia'],
                    ['Doujinshi', 'doujinshi'],
                    ['Drammatico', 'drammatico'],
                    ['Ecchi', 'ecchi'],
                    ['Fantasy', 'fantasy'],
                    ['Gender Bender', 'gender-bender'],
                    ['Harem', 'harem'],
                    ['Hentai', 'hentai'],
                    ['Horror', 'horror'],
                    ['Josei', 'josei'],
                    ['Lolicon', 'lolicon'],
                    ['Maturo', 'maturo'],
                    ['Mecha', 'mecha'],
                    ['Mistero', 'mistero'],
                    ['Psicologico', 'psicologico'],
                    ['Romantico', 'romantico'],
                    ['Sci-fi', 'sci-fi'],
                    ['Scolastico', 'scolastico'],
                    ['Seinen', 'seinen'],
                    ['Shotacon', 'shotacon'],
                    ['Shoujo', 'shoujo'],
                    ['Shoujo Ai', 'shoujo-ai'],
                    ['Shounen', 'shounen'],
                    ['Shounen Ai', 'shounen-ai'],
                    ['Slice of Life', 'slice-of-life'],
                    ['Smut', 'smut'],
                    ['Soprannaturale', 'soprannaturale'],
                    ['Sport', 'sport'],
                    ['Storico', 'storico'],
                    ['Tragico', 'tragico'],
                    ['Yaoi', 'yaoi'],
                    ['Yuri', 'yuri']
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                name: "Stato",
                state: [
                    ['In corso', 'ongoing'],
                    ['Finito', 'completed'],
                    ['Droppato', 'dropped'],
                    ['In pausa', 'paused'],
                    ['Cancellato', 'canceled']
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "GroupFilter",
                name: "Anno",
                state: [
                    ['Sconosciuto', 'Sconosciuto'],
                    ['1968', '1968'],
                    ['1970', '1970'],
                    ['1972', '1972'],
                    ['1973', '1973'],
                    ['1974', '1974'],
                    ['1975', '1975'],
                    ['1976', '1976'],
                    ['1977', '1977'],
                    ['1979', '1979'],
                    ['1980', '1980'],
                    ['1981', '1981'],
                    ['1982', '1982'],
                    ['1983', '1983'],
                    ['1984', '1984'],
                    ['1985', '1985'],
                    ['1986', '1986'],
                    ['1987', '1987'],
                    ['1988', '1988'],
                    ['1989', '1989'],
                    ['1990', '1990'],
                    ['1991', '1991'],
                    ['1992', '1992'],
                    ['1993', '1993'],
                    ['1994', '1994'],
                    ['1995', '1995'],
                    ['1996', '1996'],
                    ['1997', '1997'],
                    ['1998', '1998'],
                    ['1999', '1999'],
                    ['2000', '2000'],
                    ['2001', '2001'],
                    ['2002', '2002'],
                    ['2003', '2003'],
                    ['2004', '2004'],
                    ['2005', '2005'],
                    ['2006', '2006'],
                    ['2007', '2007'],
                    ['2008', '2008'],
                    ['2009', '2009'],
                    ['2010', '2010'],
                    ['2011', '2011'],
                    ['2012', '2012'],
                    ['2013', '2013'],
                    ['2014', '2014'],
                    ['2015', '2015'],
                    ['2016', '2016'],
                    ['2017', '2017'],
                    ['2018', '2018'],
                    ['2019', '2019'],
                    ['2020', '2020'],
                    ['2021', '2021'],
                    ['2022', '2022'],
                    ['2023', '2023'],
                    ['2024', '2024']
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: x[1] }))
            },
            {
                type_name: "SelectFilter",
                type: "sort",
                name: "Ordina per",
                state: 4,
                values: [
                    ['Più letti', 'most_read'],
                    ['Meno letti', 'less_read'],
                    ['Più recenti', 'newest'],
                    ['Meno recenti', 'oldest'],
                    ['A-Z', 'a-z'],
                    ['Z-A', 'z-a']
                ].map(x => ({type_name: 'SelectOption', name: x[0], value: x[1] }))
            }
        ];
    }
    getSourcePreferences() {
        throw new Error("getSourcePreferences not implemented");
    }
}

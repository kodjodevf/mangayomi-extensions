const mangayomiSources = [{
    "name": "Mangalib",
    "lang": "ru",
    "baseUrl": "https://mangalib.org/ru",
    "apiUrl": "https://api.mangalib.me/api",
    "iconUrl": "https://mangalib.org/static/images/logo/ml/icon-180.png",
    "typeSource": "single",
    "isManga": true,
    "isNsfw": true,
    "version": "0.0.1",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/ru/mangalib.js"
}];

// filters: https://api.mangalib.me/api/constants?fields[]=genres&fields[]=tags&fields[]=types&fields[]=scanlateStatus&fields[]=status&fields[]=format&fields[]=ageRestriction
// directory: https://api.mangalib.me/api/manga?q=encodeURIComponent(query)&sort_by=(|chap_count|views|rate_avg|releaseDate|last_chapter_at|created_at|name|rus_name)&sort_type=(|asc)&page=2
// details: https://api.mangalib.me/api/manga/34466--jeonjijeog-dogja-sijeom_?fields[]=chap_count&fields[]=summary&fields[]=genres&fields[]=authors&fields[]=artists
// chapters: https://api.mangalib.me/api/manga/34466--jeonjijeog-dogja-sijeom_/chapters
// pages: https://api.mangalib.me/api/manga/34466--jeonjijeog-dogja-sijeom_/chapter?number=147&volume=1
// image servers: https://api.mangalib.me/api/constants?fields[]=imageServers
class DefaultExtension extends MProvider {
    constructor () {
        super();
        this.client = new Client();
        this.apiHeaders = {
            'accept': '*/*',
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'};
        this.getFilterUrl = this.source.apiUrl + '/constants?fields[]=genres&fields[]=tags&fields[]=types&fields[]=scanlateStatus&fields[]=status&fields[]=format&fields[]=ageRestriction';
    }
    parseStatus(status) {
        return {
            "Онгоинг": 0,
            "Завершён": 1,
            "Приостановлен": 2,
            "Выпуск прекращён": 3,
            "Анонс": 4
        }[status] ?? 5;
    }
    async parseMangaList(url) {
        const res = await this.client.get(url, this.apiHeaders);
        const json = JSON.parse(res.body);
        let mangas = json.data.map(manga => ({
            name: manga.rus_name,
            imageUrl: manga.cover.default,
            link: manga.slug_url
        }));
        return { "list": mangas, "hasNextPage": json.meta.has_next_page };
    }
    async getPopular(page) {
        return await this.parseMangaList(this.source.apiUrl + `/manga?page=${page}`);
    }
    async getLatestUpdates(page) {
        return await this.parseMangaList(this.source.apiUrl + `/manga?page=${page}&sort_by=last_chapter_at`);
    }
    async search(query, page, filters) {
        let url = `${this.source.apiUrl}/manga?q=${encodeURIComponent(query)}`
        // Search sometimes failed because filters were empty. I experienced this mostly on android...
        if (!filters || filters.length == 0) {
            return await this.parseMangaList(url + `&page=${page}`);
        }
        for (const filter of filters[0].state) {
            if (filter.state == true)
                url += `&types[]=${filter.value}`;
        }
        for (const filter of filters[1].state) {
            if (filter.state == true)
                url += `&caution[]=${filter.value}`;
        }

        const minChapF = filters[2].state[0];
        const maxChapF = filters[2].state[1];
        const minChap = minChapF.values[minChapF.state].value;
        const maxChap = maxChapF.values[maxChapF.state].value;
        url += minChap ? `&chap_count_min=${minChap}` : '';
        url += maxChap ? `&chap_count_max=${maxChap}` : '';

        const minYearF = filters[3].state[0];
        const maxYearF = filters[3].state[1];
        const minYear = minYearF.values[minYearF.state].value;
        const maxYear = maxYearF.values[maxYearF.state].value;
        url += minYear ? `&year_min=${minYear}` : '';
        url += maxYear ? `&year_max=${maxYear}` : '';

        for (const filter of filters[4].state) {
            if (filter.state == 1)
                url += `&genres[]=${filter.value}`;
            else if (filter.state == 2)
                url += `&genres_exclude[]=${filter.value}`;
        }
        for (const filter of filters[5].state) {
            if (filter.state == true)
                url += `&status[]=${filter.value}`;
        }
        for (const filter of filters[6].state) {
            if (filter.state == true)
                url += `&scanlate_status[]=${filter.value}`;
        }
        for (const filter of filters[7].state) {
            if (filter.state == 1)
                url += `&format[]=${filter.value}`;
            else if (filter.state == 2)
                url += `&format_exclude[]=${filter.value}`;
        }
        const sortVal = filters[8].values[filters[8].state.index].value;
        const sortType = filters[8].state.ascending ? 'asc' : '';
        url += sortVal ? `&sort_by=${sortVal}` : '';
        url += sortType ? `&sort_type=${sortType}` : '';

        return await this.parseMangaList(url + `&page=${page}`);
    }
    async getDetail(url) {
        const infoRes = await this.client.get(`${this.source.apiUrl}/manga/${url}?fields[]=chap_count&fields[]=summary&fields[]=genres&fields[]=authors&fields[]=artists`, this.apiHeaders);
        const chapterRes = await this.client.get(`${this.source.apiUrl}/manga/${url}/chapters`, this.apiHeaders);
        
        const info = JSON.parse(infoRes.body).data;
        const chapters = JSON.parse(chapterRes.body).data;
        const chapterBaseUrl = `${this.source.apiUrl}/manga/${url}/chapter`;
        
        return {
            name: info.name,
            imageUrl: info.cover.default,
            author: info.authors.map(x => x.name).join(', '),
            artist: info.artists.map(x => x.name).join(', '),
            status: this.parseStatus(info.status.label),
            description: info.summary,
            genre: info.genres.map(x => x.name),
            chapters: chapters.map(c => ({
                name: `Том ${c.volume} Глава ${c.number}` + (c.name ? `: ${c.name}` : ''),
                url: `${chapterBaseUrl}?number=${c.number}&volume=${c.volume}`,
                dateUpload: new Date(c.branches[0].created_at).valueOf().toString(),
                scanlator: c.branches[0].teams.map(x => x.name).join(', ')
            })).reverse()
        };
    }
    // For manga chapter pages
    async getPageList(url) {
        const serverId = new SharedPreferences().get('imageServer');

        let res = await this.client.get(`${this.source.apiUrl}/constants?fields[]=imageServers`, this.apiHeaders);
        const imageServers = JSON.parse(res.body).data.imageServers;
        const imageServer = imageServers.find(x => x.id == serverId).url;

        res = await this.client.get(url, this.apiHeaders);
        const chapter = JSON.parse(res.body).data;
        return chapter.pages.map(img => ({url: imageServer + img.url, headers: this.apiHeaders}));
    }
    getFilterList() {
        const chapterCounts = ['1','5','10','20','30','40','50','100','200','500','1000','2000','5000','10000'].map(x => [x, x]);
        const years = [...range(1980, new Date().getFullYear() + 1, -1), ...range(1930, 1971, -10)].map(x => {
            x = x.toString();
            return [x, x];
        });
        return [
            {
                type_name: "GroupFilter",
                type: "type",
                name: "Тип",
                state: [
                    ["Манга", 1],
                    ["OEL-манга", 4],
                    ["Манхва", 5],
                    ["Маньхуа", 6],
                    ["Руманга", 8],
                    ["Комикс", 9]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: `${x[1]}` }))
            },
            {
                type_name: "GroupFilter",
                type: "age_restriction",
                name: "возрастной рейтинг",
                state: [
                    ["Нет", 0],
                    ["6+", 1],
                    ["12+", 2],
                    ["16+", 3],
                    ["18+", 4]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: `${x[1]}` }))
            },
            {
                type_name: "GroupFilter",
                type: "chapter_count",
                name: "Количество глав",
                state: [
                    {
                        type_name: "SelectFilter",
                        type: "chap_count_min",
                        name: "от",
                        state: 0,
                        values: [['от', ''], ...chapterCounts].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
                    },
                    {
                        type_name: "SelectFilter",
                        type: "chap_count_max",
                        name: "до",
                        state: 0,
                        values: [['до', ''], ...chapterCounts].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
                    }
                ]
            },
            {
                type_name: "GroupFilter",
                type: "years",
                name: "Год выпуска",
                state: [
                    {
                        type_name: "SelectFilter",
                        type: "year_min",
                        name: "от",
                        state: 0,
                        values: [['от', ''], ...years].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
                    },
                    {
                        type_name: "SelectFilter",
                        type: "year_max",
                        name: "до",
                        state: 0,
                        values: [['до', ''], ...years].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
                    }
                ]
            },
            {
                type_name: "GroupFilter",
                type: "genre",
                name: "Жанры",
                state: [
                    ["Арт", 32, false],
                    ["Безумие", 91, false],
                    ["Боевик", 34, false],
                    ["Боевые искусства", 35, false],
                    ["Вампиры", 36, false],
                    ["Военное", 89, false],
                    ["Гарем", 37, false],
                    ["Гендерная интрига", 38, false],
                    ["Героическое фэнтези", 39, false],
                    ["Демоны", 81, false],
                    ["Детектив", 40, false],
                    ["Детское", 88, false],
                    ["Драма", 43, false],
                    ["Игра", 44, false],
                    ["Исекай", 79, false],
                    ["История", 45, false],
                    ["Киберпанк", 46, false],
                    ["Кодомо", 76, false],
                    ["Комедия", 47, false],
                    ["Космос", 83, false],
                    ["Магия", 85, false],
                    ["Махо-сёдзё", 48, false],
                    ["Машины", 90, false],
                    ["Меха", 49, false],
                    ["Мистика", 50, false],
                    ["Музыка", 80, false],
                    ["Научная фантастика", 51, false],
                    ["Омегаверс", 77, false],
                    ["Пародия", 86, false],
                    ["Повседневность", 52, false],
                    ["Полиция", 82, false],
                    ["Постапокалиптика", 53, false],
                    ["Приключения", 54, false],
                    ["Психология", 55, false],
                    ["Романтика", 56, false],
                    ["Самурайский боевик", 57, false],
                    ["Сверхъестественное", 58, false],
                    ["Сёдзё", 59, false],
                    ["Сёдзё-ай", 60, false],
                    ["Сёнэн-ай", 62, true],
                    ["Спорт", 63, false],
                    ["Супер сила", 87, false],
                    ["Сэйнэн", 64, false],
                    ["Трагедия", 65, false],
                    ["Триллер", 66, false],
                    ["Ужасы", 67, false],
                    ["Фантастика", 68, false],
                    ["Фэнтези", 69, false],
                    ["Хентай", 84, false],
                    ["Эротика", 71, true],
                    ["Этти", 72, false]                    
                ].map(x => ({ type_name: 'TriState', name: x[0], value: `${x[1]}` }))
            },
            {
                type_name: "GroupFilter",
                type: "status",
                name: "Статус титула",
                state: [
                    ["Онгоинг", 1],
                    ["Завершён", 2],
                    ["Анонс", 3],
                    ["Приостановлен", 4],
                    ["Выпуск прекращён", 5]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: `${x[1]}` }))
            },
            {
                type_name: "GroupFilter",
                type: "translation_status",
                name: "Статус перевода",
                state: [
                    ["Продолжается", 1],
                    ["Завершён", 2],
                    ["Заморожен", 3],
                    ["Заброшен", 4]
                ].map(x => ({ type_name: 'CheckBox', name: x[0], value: `${x[1]}` }))
            },
            {
                type_name: "GroupFilter",
                type: "format",
                name: "Формат выпуска",
                state: [
                    ["4-кома (Ёнкома)", 1],
                    ["Сборник", 2],
                    ["Додзинси", 3],
                    ["В цвете", 4],
                    ["Сингл", 5],
                    ["Веб", 6],
                    ["Вебтун", 7]
                ].map(x => ({ type_name: 'TriState', name: x[0], value: `${x[1]}` }))
            },
            {
                type_name: "SortFilter",
                type: "sort",
                name: "Сортировать",
                state: {
                    type_name: "SortState",
                    index: 0,
                    ascending: false
                },
                values: [
                    ['По популярности', ''],
                    ['По рейтингу', 'rate_avg'],
                    ['По просмотрам', 'views'],
                    ['Количество глав', 'chap_count'],
                    ['дата релиза', 'releaseDate'],
                    ['дата обновления', 'last_chapter_at'],
                    ['дата добавления', 'created_at'],
                    ['По названию (A-Z)', 'name'],
                    ['По названию (A-Я)', 'rus_name']
                ].map(x => ({ type_name: 'SelectOption', name: x[0], value: x[1] }))
            }
        ];
    }
    getSourcePreferences() {
        const imageServers = ['Первый', 'Второй', 'Сжатия', 'Скачивание', 'Crop pages'];
        const imageServerValuess = ['main', 'secondary', 'compress', 'download', 'crop'];
         return [
            {
                key: 'imageServer',
                listPreference: {
                    title: 'Image Server',
                    summary: '',
                    valueIndex: 0,
                    entries: imageServers,
                    entryValues: imageServerValuess
                }
            }
        ];
    }
}

function range (first, last, step) {
    if (last <= first)
        return [];
    if (!step) {
        step = 1;
    }
    if (!last) {
        last = first;
        first = 0;
    }
    const start = step > 0 ? first : last - 1;
    let length = Math.ceil((last - first) / Math.abs(step));
    return Array.from(new Array(length), (x, i) => start + i * step);
}
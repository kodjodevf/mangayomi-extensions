const mangayomiSources = [{
    "name": "绅士漫画",
    "lang": "zh",
    "baseUrl": "https://www.wnacg.com",
    "apiUrl": "",
    "iconUrl": "https://www.wnacg.com/favicon.ico",
    "typeSource": "single",
    "isManga": true,
    "isNsfw": true,
    "version": "0.0.2",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "manga/src/zh/wnacg.js"
}];

class DefaultExtension extends MProvider {
    url_strs = {
        "dojinshi": {
            "all": "albums-index-page-$-cate-5.html",
            "chi": "albums-index-page-$-cate-1.html",
            "jpa": "albums-index-page-$-cate-12.html",
            "eng": "albums-index-page-$-cate-16.html"
        },
        "tankobon": {
            "all": "albums-index-page-$-cate-6.html",
            "chi": "albums-index-page-$-cate-9.html",
            "jpa": "albums-index-page-$-cate-13.html",
            "eng": "albums-index-page-$-cate-17.html"
        },
        "magazine": {
            "all": "albums-index-page-$-cate-7.html",
            "chi": "albums-index-page-$-cate-10.html",
            "jpa": "albums-index-page-$-cate-14.html",
            "eng": "albums-index-page-$-cate-18.html"
        },
        "korea": {
            "all": "albums-index-page-$-cate-19.html",
            "chi": "albums-index-page-$-cate-20.html",
            "oth": "albums-index-page-$-cate-21.html"
        },
        "cg": {
            "all": "albums-index-page-$-cate-2.html"
        },
        "cosplay": {
            "all": "albums-index-page-$-cate-3.html"
        },
        "thridd": {
            "all": "albums-index-page-$-cate-22.html"
        },
        "home": {
            "all": ""
        }
    };

    dateStringToTimestamp(dateString) {
        var parts = dateString.split('-');
        var year = parseInt(parts[0]);
        var month = parseInt(parts[1]) - 1;
        var day = parseInt(parts[2]);
        var date = new Date(year, month, day);
        var timestamp = date.getTime();

        return timestamp;
    }

    async request(url_str, cookies) {
        const headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
            "Referer": this.source.baseUrl
        };
        if (cookies) {
            const preference = new SharedPreferences();
            headers["Cookie"] = `MPIC_bnS5=${preference.get("cookies")}`;
        }
        const res = await new Client().get(`${this.source.baseUrl}/${url_str}`, headers);
        return res;
    }

    async getFavorites(page) {
        const res = await this.request(`users-users_fav-page-${page}-c-0.html`, true);
        const doc = new Document(res.body);
        const elements = doc.select("div.asTB");
        const mangas = [];
        for (const element of elements) {
            const url = element.selectFirst("div.box_cel p.l_title a").attr("href");
            const title = element.selectFirst("div.box_cel p.l_title a").text;
            const cover = "https:" + element.selectFirst("img").attr("src");
            mangas.push({
                "name": title,
                "link": url,
                "imageUrl": cover
            });
        }
        return {
            "list": mangas,
            "hasNextPage": true
        };
    }

    async getMangas(url_str, page) {
        url_str = url_str.replace("$", page.toString());
        const res = await this.request(url_str, false);
        const doc = new Document(res.body);
        const elements = doc.select("li.gallary_item");
        const mangas = [];
        for (const element of elements) {
            const url = element.selectFirst("div.pic_box a").attr("href");
            let title = element.selectFirst("div.pic_box a").attr("title");
            title = title.replaceAll("<em>", "").replaceAll("</em>", "");
            const cover = "https:" + element.selectFirst("div.pic_box a img").attr("src");
            mangas.push({
                "name": title,
                "link": url,
                "imageUrl": cover
            });
        }
        return {
            "list": mangas,
            "hasNextPage": true
        };
    }

    async getPopular(page) {
        const result = await this.getMangas("", page);
        result["hasNextPage"] = false;
        return result;
    }

    async getLatestUpdates(page) {
        return await this.getMangas("albums-index-page-$.html", page);
    }

    async search(query, page, filters) {
        var url_str;
        var jump = false;
        if (query == "") {
            var category;
            var language;
            var jump_page;
            var djs_lang, tkb_lang, mgz_lang, kr_lang;
            for (const filter of filters) {
                if (filter["type"] == "CateFilter") {
                    category = filter["values"][filter["state"]]["value"];
                } 
                else if (filter["type"] == "LangFilter") {
                    for (const lang_filter of filter["state"]) {
                        if (lang_filter["type"] == "DJSFilter") {
                            djs_lang = lang_filter["values"][lang_filter["state"]]["value"];
                        } else if (lang_filter["type"] == "TKBFilter") {
                            tkb_lang = lang_filter["values"][lang_filter["state"]]["value"];
                        } else if (lang_filter["type"] == "MGZFilter") {
                            mgz_lang = lang_filter["values"][lang_filter["state"]]["value"];
                        } else if (lang_filter["type"] == "KRFilter") {
                            kr_lang = lang_filter["values"][lang_filter["state"]]["value"];
                        }
                    }
                }
                else if (filter["type"] == "PageFilter") {
                    jump_page = parseInt(filter["state"]);
                }
            }
            if (jump_page != 1) {
                page = jump_page;
                jump = true;
            }
            if (category == "dojinshi") {
                language = djs_lang;
            } else if (category == "tankobon") {
                language = tkb_lang;
            } else if (category == "magazine") {
                language = mgz_lang;
            } else if (category == "korea") {
                language = kr_lang;
            } else if (category == "fav") {
                return await this.getFavorites(page);
            } else {
                language = "all";
            }
            url_str = this.url_strs[category][language];
        } else {
            url_str = `search/index.php?q=${query}&m=&syn=yes&f=_all&s=create_time_DESC&p=$`;
        }
        const result = await this.getMangas(url_str, page);
        result["hasNextPage"] = !jump;
        return result;
    }

    async getDetail(url) {
        const res = await this.request(url.slice(1), false);
        const doc = new Document(res.body);
        const title = doc.selectFirst("h2").text;
        var cover = doc.selectFirst("div.uwthumb img").attr("src");
        if (cover[3] == "/") {
            cover = "https:" + cover.substring(2, cover.length);
        } else {
            cover = "https:" + cover;
        }
        const desc_ = doc.select("div.uwconn label").map(e => e.text);
        const desc = desc_.join("\n").replaceAll("+TAG\n", "").slice(0, -1) + doc.selectFirst("div.uwconn p").text;
        const id = url.match(/-aid-(.+?).html/)[1];
        const uploader = doc.selectFirst("div.uwuinfo p").text;
        const tags = doc.select("div.addtags a.tagshow").map(e => e.text);
        const uploaddate = this.dateStringToTimestamp(doc.selectFirst("div.info_col").text.replace("上傳於", ""));
        return {
            name: title,
            imageUrl: cover,
            description: desc,
            author: uploader,
            status: 1,
            genre: tags,
            episodes: [{
                name: title,
                url: `photos-gallery-aid-${id}.html`,
                "dateUpload": uploaddate.toString()
            }]
        }
    }

    async getPageList(url) {
        const res = await this.request(url, false);
        const html = res.body;
        const urls = [];
        let urls_str = html.substring(html.search("imglist") + 12, html.search("喜歡紳士漫畫的同學請加入收藏哦！") + 17);
        const url_list = urls_str.split("},{");
        for (let url_str of url_list) {
            urls.push("https:" + url_str.substring(url_str.search("img_host") + 11, url_str.search("\", ") - 1));
        }
        return urls.slice(0, -1);
    }

    getFilterList() {
        return [{
                "type": "HeaderFilter",
                "name": "选择类别",
                "type_name": "HeaderFilter"
            },
            {
                "type": "CateFilter",
                "type_name": "SelectFilter",
                "name": "分类",
                "values": [{
                        "value": "home",
                        "name": "主页",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "dojinshi",
                        "name": "同人志",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "tankobon",
                        "name": "单行本",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "magazine",
                        "name": "杂志&短篇",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "korea",
                        "name": "韩漫",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "cg",
                        "name": "CG畫集",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "cosplay",
                        "name": "Cosplay",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "thridd",
                        "name": "3D漫畫",
                        "type_name": "SelectOption"
                    },
                    {
                        "value": "fav",
                        "name": "收藏",
                        "type_name": "SelectOption"
                    }
                ]
            },
            {
                "type": "SeparatorFilter",
                "type_name": "SeparatorFilter"
            },
            {
                "type": "HeaderFilter",
                "name": "根据类别选择语言",
                "type_name": "HeaderFilter"
            },
            {
                "type": "LangFilter",
                "name": "语言",
                "type_name": "GroupFilter",
                "state": [{
                        "type": "DJSFilter",
                        "type_name": "SelectFilter",
                        "name": "同人志",
                        "values": [{
                                "value": "all",
                                "name": "全部",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "chi",
                                "name": "漢化",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "jpa",
                                "name": "日語",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "eng",
                                "name": "English",
                                "type_name": "SelectOption"
                            }
                        ]
                    },
                    {
                        "type": "TKBFilter",
                        "type_name": "SelectFilter",
                        "name": "单行本",
                        "values": [{
                                "value": "all",
                                "name": "全部",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "chi",
                                "name": "漢化",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "jpa",
                                "name": "日語",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "eng",
                                "name": "English",
                                "type_name": "SelectOption"
                            }
                        ]
                    },
                    {
                        "type": "MGZFilter",
                        "type_name": "SelectFilter",
                        "name": "杂志&短篇",
                        "values": [{
                                "value": "all",
                                "name": "全部",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "chi",
                                "name": "漢化",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "jpa",
                                "name": "日語",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "eng",
                                "name": "English",
                                "type_name": "SelectOption"
                            }
                        ]
                    },
                    {
                        "type": "KRFilter",
                        "type_name": "SelectFilter",
                        "name": "韩漫",
                        "values": [{
                                "value": "all",
                                "name": "全部",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "chi",
                                "name": "漢化",
                                "type_name": "SelectOption"
                            },
                            {
                                "value": "oth",
                                "name": "其他",
                                "type_name": "SelectOption"
                            }
                        ]
                    },
                ]
            }, {
                "type": "SeparatorFilter",
                "type_name": "SeparatorFilter"
            },
            {
                "type": "HeaderFilter",
                "name": "跳转页数",
                "type_name": "HeaderFilter"
            },
            {
                "type": "PageFilter",
                "name": "页数",
                "type_name": "TextFilter",
                "state": "1"
            }
        ];
    }

    getSourcePreferences() {
        return [{
            "key": "cookies",
            "editTextPreference": {
                "title": "用户Cookies",
                "summary": "用于读取用户收藏的Cookies（MPIC_bnS5）",
                "value": "",
                "dialogTitle": "Cookies",
                "dialogMessage": "",
            }
        }];
    }
}

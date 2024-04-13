const mangayomiSources = [{
  "name": "Jable",
  "lang": "zh",
  "baseUrl": "https://jable.tv",
  "apiUrl": "",
  "iconUrl": "https://assets-cdn.jable.tv/assets/icon/favicon-32x32.png",
  "typeSource": "single",
  "isManga": false,
  "isNsfw": true,
  "version": "0.0.2",
  "dateFormat": "",
  "dateFormatLocale": "",
  "pkgPath": "anime/src/zh/jable.js",
  "hasCloudflare": true
}];

class DefaultExtension extends MProvider {
  async getItems(url) {
    const res = await new Client().get(this.source.baseUrl + url);
    const doc = new Document(res.body);
    const elements = doc.select("div.video-img-box");
    const items = [];
    for (const element of elements) {
      const title = element.selectFirst("h6.title").text;
      const cover = element.selectFirst("div.img-box a img").attr("data-src");
      const url = element.selectFirst("a").attr("href");
      items.push({
        name: title,
        imageUrl: cover,
        link: url
      });
    }
    return {
      list: items,
      hasNextPage: true
    };
  }

  async getPopular(page) {
    return await this.getItems(`/hot/${page}/`);
  }

  async getLatestUpdates(page) {
    return await this.getItems(`/latest-updates/${page}/`);
  }

  async search(query, page, filters) {
    if (query != "") {
      return await this.getItems(`/search/${query}/?mode=async&function=get_block&block_id=list_videos_videos_list_search_result&q=${query}&sort_by=&from=${page}`);
    }
    var categories, sort;
    for (const filter of filters) {
      if (filter["type"] == "categories") {
        categories = filter["values"][filter["state"]]["value"];
      }
      else if (filter["type"] == "sort") {
        sort = filter["values"][filter["state"]]["value"];
      }
    }
    return await this.getItems(`${categories}?mode=async&function=get_block&block_id=list_videos_common_videos_list&sort_by=${sort}&from=${page}`);
  }

  async getDetail(url) {
    const res = await new Client().get(url);
    const doc = new Document(res.body);
    const title = doc.selectFirst("div.header-left h4").text;
    const cover = doc.selectFirst("video#player").attr("poster");
    const tags = doc.select("h5.tags a").map(e => e.text);
    const actor = doc.selectFirst("div.models span").attr("title");
    const vid_url = res.body.match(/hlsUrl\s*=\s*'([^']*)'/)[1];
    return {
      name: title,
      imageUrl: cover,
      genre: tags,
      author: actor,
      description: "",
      episodes: [{
        name: title,
        url: vid_url
      }]
    };
  }

  async getVideoList(url) {
    return [{
      url: url,
      originalUrl: url,
      quality: "HLS"
    }];
  }

  getFilterList() {
    return [{
      type: "categories",
      name: "主題",
      type_name: "SelectFilter",
      values: [{
          name: "角色劇情",
          value: "/categories/roleplay/",
          type_name: "SelectOption"
        },
        {
          name: "中文字幕",
          value: "/categories/chinese-subtitle/",
          type_name: "SelectOption"
        },
        {
          name: "制服誘惑",
          value: "/categories/uniform/",
          type_name: "SelectOption"
        },
        {
          name: "直接開啪",
          value: "/categories/sex-only/",
          type_name: "SelectOption"
        },
        {
          name: "絲襪美腿",
          value: "/categories/pantyhose/",
          type_name: "SelectOption"
        },
        {
          name: "主奴調教",
          value: "/categories/bdsm/",
          type_name: "SelectOption"
        },
        {
          name: "多P群交",
          value: "/categories/groupsex/",
          type_name: "SelectOption"
        },
        {
          name: "男友視角",
          value: "/categories/pov/",
          type_name: "SelectOption"
        },
        {
          name: "凌辱強暴",
          value: "/categories/rape/",
          type_name: "SelectOption"
        },
        {
          name: "無碼解放",
          value: "/categories/uncensored/",
          type_name: "SelectOption"
        },
        {
          name: "盜攝偷拍",
          value: "/categories/hidden-cam/",
          type_name: "SelectOption"
        },
        {
          name: "女同歡愉",
          value: "/categories/lesbian/",
          type_name: "SelectOption"
        },
        {
          name: "黑絲",
          value: "/tags/black-pantyhose/",
          type_name: "SelectOption"
        },
        {
          name: "過膝襪",
          value: "/tags/knee-socks/",
          type_name: "SelectOption"
        },
        {
          name: "運動裝",
          value: "/tags/sportswear/",
          type_name: "SelectOption"
        },
        {
          name: "肉絲",
          value: "/tags/flesh-toned-pantyhose/",
          type_name: "SelectOption"
        },
        {
          name: "絲襪",
          value: "/tags/pantyhose/",
          type_name: "SelectOption"
        },
        {
          name: "眼鏡娘",
          value: "/tags/glasses/",
          type_name: "SelectOption"
        },
        {
          name: "獸耳",
          value: "/tags/kemonomimi/",
          type_name: "SelectOption"
        },
        {
          name: "漁網",
          value: "/tags/fishnets/",
          type_name: "SelectOption"
        },
        {
          name: "水着",
          value: "/tags/swimsuit/",
          type_name: "SelectOption"
        },
        {
          name: "校服",
          value: "/tags/school-uniform/",
          type_name: "SelectOption"
        },
        {
          name: "旗袍",
          value: "/tags/cheongsam/",
          type_name: "SelectOption"
        },
        {
          name: "婚紗",
          value: "/tags/wedding-dress/",
          type_name: "SelectOption"
        },
        {
          name: "女僕",
          value: "/tags/maid/",
          type_name: "SelectOption"
        },
        {
          name: "和服",
          value: "/tags/kimono/",
          type_name: "SelectOption"
        },
        {
          name: "吊帶襪",
          value: "/tags/stockings/",
          type_name: "SelectOption"
        },
        {
          name: "兔女郎",
          value: "/tags/bunny-girl/",
          type_name: "SelectOption"
        },
        {
          name: "Cosplay",
          value: "/tags/Cosplay/",
          type_name: "SelectOption"
        },
        {
          name: "黑肉",
          value: "/tags/suntan/",
          type_name: "SelectOption"
        },
        {
          name: "長身",
          value: "/tags/tall/",
          type_name: "SelectOption"
        },
        {
          name: "軟體",
          value: "/tags/flexible-body/",
          type_name: "SelectOption"
        },
        {
          name: "貧乳",
          value: "/tags/small-tits/",
          type_name: "SelectOption"
        },
        {
          name: "蘿莉",
          value: "/tags/loli/",
          type_name: "SelectOption"
        },
        {
          name: "美腿",
          value: "/tags/beautiful-leg/",
          type_name: "SelectOption"
        },
        {
          name: "美尻",
          value: "/tags/beautiful-butt/",
          type_name: "SelectOption"
        },
        {
          name: "紋身",
          value: "/tags/tattoo/",
          type_name: "SelectOption"
        },
        {
          name: "短髮",
          value: "/tags/short-hair/",
          type_name: "SelectOption"
        },
        {
          name: "白虎",
          value: "/tags/hairless-pussy/",
          type_name: "SelectOption"
        },
        {
          name: "熟女",
          value: "/tags/mature-woman/",
          type_name: "SelectOption"
        },
        {
          name: "巨乳",
          value: "/tags/big-tits/",
          type_name: "SelectOption"
        },
        {
          name: "少女",
          value: "/tags/girl/",
          type_name: "SelectOption"
        },
        {
          name: "顏射",
          value: "/tags/facial/",
          type_name: "SelectOption"
        },
        {
          name: "腳交",
          value: "/tags/footjob/",
          type_name: "SelectOption"
        },
        {
          name: "肛交",
          value: "/tags/anal-sex/",
          type_name: "SelectOption"
        },
        {
          name: "痙攣",
          value: "/tags/spasms/",
          type_name: "SelectOption"
        },
        {
          name: "潮吹",
          value: "/tags/squirting/",
          type_name: "SelectOption"
        },
        {
          name: "深喉",
          value: "/tags/deep-throat/",
          type_name: "SelectOption"
        },
        {
          name: "接吻",
          value: "/tags/kiss/",
          type_name: "SelectOption"
        },
        {
          name: "口爆",
          value: "/tags/cum-in-mouth/",
          type_name: "SelectOption"
        },
        {
          name: "口交",
          value: "/tags/blowjob/",
          type_name: "SelectOption"
        },
        {
          name: "乳交",
          value: "/tags/tit-wank/",
          type_name: "SelectOption"
        },
        {
          name: "中出",
          value: "/tags/creampie/",
          type_name: "SelectOption"
        },
        {
          name: "露出",
          value: "/tags/outdoor/",
          type_name: "SelectOption"
        },
        {
          name: "輪姦",
          value: "/tags/gang-rape/",
          type_name: "SelectOption"
        },
        {
          name: "調教",
          value: "/tags/tune/",
          type_name: "SelectOption"
        },
        {
          name: "綑綁",
          value: "/tags/bondage/",
          type_name: "SelectOption"
        },
        {
          name: "瞬間插入",
          value: "/tags/quickie/",
          type_name: "SelectOption"
        },
        {
          name: "痴漢",
          value: "/tags/chikan/",
          type_name: "SelectOption"
        },
        {
          name: "痴女",
          value: "/tags/chizyo/",
          type_name: "SelectOption"
        },
        {
          name: "男M",
          value: "/tags/masochism-guy/",
          type_name: "SelectOption"
        },
        {
          name: "泥醉",
          value: "/tags/crapulence/",
          type_name: "SelectOption"
        },
        {
          name: "泡姬",
          value: "/tags/soapland/",
          type_name: "SelectOption"
        },
        {
          name: "母乳",
          value: "/tags/breast-milk/",
          type_name: "SelectOption"
        },
        {
          name: "放尿",
          value: "/tags/piss/",
          type_name: "SelectOption"
        },
        {
          name: "按摩",
          value: "/tags/massage/",
          type_name: "SelectOption"
        },
        {
          name: "強姦",
          value: "/tags/rape/",
          type_name: "SelectOption"
        },
        {
          name: "多P",
          value: "/tags/gangbang/",
          type_name: "SelectOption"
        },
        {
          name: "刑具",
          value: "/tags/torture/",
          type_name: "SelectOption"
        },
        {
          name: "凌辱",
          value: "/tags/insult/",
          type_name: "SelectOption"
        },
        {
          name: "一日十回",
          value: "/tags/10-times-a-day/",
          type_name: "SelectOption"
        },
        {
          name: "3P",
          value: "/tags/3p/",
          type_name: "SelectOption"
        },
        {
          name: "黑人",
          value: "/tags/black/",
          type_name: "SelectOption"
        },
        {
          name: "醜男",
          value: "/tags/ugly-man/",
          type_name: "SelectOption"
        },
        {
          name: "誘惑",
          value: "/tags/temptation/",
          type_name: "SelectOption"
        },
        {
          name: "童貞",
          value: "/tags/virginity/",
          type_name: "SelectOption"
        },
        {
          name: "時間停止",
          value: "/tags/time-stop/",
          type_name: "SelectOption"
        },
        {
          name: "復仇",
          value: "/tags/avenge/",
          type_name: "SelectOption"
        },
        {
          name: "年齡差",
          value: "/tags/age-difference/",
          type_name: "SelectOption"
        },
        {
          name: "巨漢",
          value: "/tags/giant/",
          type_name: "SelectOption"
        },
        {
          name: "媚藥",
          value: "/tags/love-potion/",
          type_name: "SelectOption"
        },
        {
          name: "夫目前犯",
          value: "/tags/sex-beside-husband/",
          type_name: "SelectOption"
        },
        {
          name: "出軌",
          value: "/tags/affair/",
          type_name: "SelectOption"
        },
        {
          name: "催眠",
          value: "/tags/hypnosis/",
          type_name: "SelectOption"
        },
        {
          name: "偷拍",
          value: "/tags/hidden-cam/",
          type_name: "SelectOption"
        },
        {
          name: "不倫",
          value: "/tags/incest/",
          type_name: "SelectOption"
        },
        {
          name: "下雨天",
          value: "/tags/rainy-day/",
          type_name: "SelectOption"
        },
        {
          name: "NTR",
          value: "/tags/ntr/",
          type_name: "SelectOption"
        },
        {
          name: "風俗娘",
          value: "/tags/club-hostess-and-sex-worker/",
          type_name: "SelectOption"
        },
        {
          name: "醫生",
          value: "/tags/doctor/",
          type_name: "SelectOption"
        },
        {
          name: "逃犯",
          value: "/tags/fugitive/",
          type_name: "SelectOption"
        },
        {
          name: "護士",
          value: "/tags/nurse/",
          type_name: "SelectOption"
        },
        {
          name: "老師",
          value: "/tags/teacher/",
          type_name: "SelectOption"
        },
        {
          name: "空姐",
          value: "/tags/flight-attendant/",
          type_name: "SelectOption"
        },
        {
          name: "球隊經理",
          value: "/tags/team-manager/",
          type_name: "SelectOption"
        },
        {
          name: "未亡人",
          value: "/tags/widow/",
          type_name: "SelectOption"
        },
        {
          name: "搜查官",
          value: "/tags/detective/",
          type_name: "SelectOption"
        },
        {
          name: "情侶",
          value: "/tags/couple/",
          type_name: "SelectOption"
        },
        {
          name: "家政婦",
          value: "/tags/housewife/",
          type_name: "SelectOption"
        },
        {
          name: "家庭教師",
          value: "/tags/private-teacher/",
          type_name: "SelectOption"
        },
        {
          name: "偶像",
          value: "/tags/idol/",
          type_name: "SelectOption"
        },
        {
          name: "人妻",
          value: "/tags/wife/",
          type_name: "SelectOption"
        },
        {
          name: "主播",
          value: "/tags/female-anchor/",
          type_name: "SelectOption"
        },
        {
          name: "OL",
          value: "/tags/ol/",
          type_name: "SelectOption"
        },
        {
          name: "魔鏡號",
          value: "/tags/magic-mirror/",
          type_name: "SelectOption"
        },
        {
          name: "電車",
          value: "/tags/tram/",
          type_name: "SelectOption"
        },
        {
          name: "處女",
          value: "/tags/first-night/",
          type_name: "SelectOption"
        },
        {
          name: "監獄",
          value: "/tags/prison/",
          type_name: "SelectOption"
        },
        {
          name: "溫泉",
          value: "/tags/hot-spring/",
          type_name: "SelectOption"
        },
        {
          name: "洗浴場",
          value: "/tags/bathing-place/",
          type_name: "SelectOption"
        },
        {
          name: "泳池",
          value: "/tags/swimming-pool/",
          type_name: "SelectOption"
        },
        {
          name: "汽車",
          value: "/tags/car/",
          type_name: "SelectOption"
        },
        {
          name: "廁所",
          value: "/tags/toilet/",
          type_name: "SelectOption"
        },
        {
          name: "學校",
          value: "/tags/school/",
          type_name: "SelectOption"
        },
        {
          name: "圖書館",
          value: "/tags/library/",
          type_name: "SelectOption"
        },
        {
          name: "健身房",
          value: "/tags/gym-room/",
          type_name: "SelectOption"
        },
        {
          name: "便利店",
          value: "/tags/store/",
          type_name: "SelectOption"
        },
        {
          name: "錄像",
          value: "/tags/video-recording/",
          type_name: "SelectOption"
        },
        {
          name: "處女作/引退作",
          value: "/tags/debut-retires/",
          type_name: "SelectOption"
        },
        {
          name: "綜藝",
          value: "/tags/variety-show/",
          type_name: "SelectOption"
        },
        {
          name: "節日主題",
          value: "/tags/festival/",
          type_name: "SelectOption"
        },
        {
          name: "感謝祭",
          value: "/tags/thanksgiving/",
          type_name: "SelectOption"
        },
        {
          name: "4小時以上",
          value: "/tags/more-than-4-hours/",
          type_name: "SelectOption"
        }
      ]
    },
    {
      type: "sort",
      name: "排序",
      type_name: "SelectFilter",
      values: [{
          name: "近期最佳",
          value: "post_date_and_popularity",
          type_name: "SelectOption"
        },
        {
          name: "最近更新",
          value: "post_date",
          type_name: "SelectOption"
        },
        {
          name: "最多觀看",
          value: "video_viewed",
          type_name: "SelectOption"
        },
        {
          name: "最高收藏",
          value: "most_favourited",
          type_name: "SelectOption"
        }
      ]
    }]
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }
}

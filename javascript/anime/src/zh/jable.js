const mangayomiSources = [{
  "name": "Jable",
  "lang": "zh",
  "baseUrl": "https://jable.tv",
  "apiUrl": "",
  "iconUrl": "https://assets-cdn.jable.tv/assets/icon/favicon-32x32.png",
  "typeSource": "single",
  "isManga": false,
  "isNsfw": true,
  "version": "0.0.1",
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
    for (const filter of filters) {
      if (filter["type"] == "categories") {
        const categories = filter["values"][filter["state"]]["value"];
        return await this.getItems(`/categories/${categories}/?mode=async&function=get_block&block_id=list_videos_common_videos_list&sort_by=post_date&from=${page}`);
      }
    }
    return {
      list: [],
      hasNextPage: false
    };
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
          value: "roleplay",
          type_name: "SelectOption"
        },
        {
          name: "中文字幕",
          value: "chinese-subtitle",
          type_name: "SelectOption"
        },
        {
          name: "制服誘惑",
          value: "uniform",
          type_name: "SelectOption"
        },
        {
          name: "直接開啪",
          value: "sex-only",
          type_name: "SelectOption"
        },
        {
          name: "絲襪美腿",
          value: "pantyhose",
          type_name: "SelectOption"
        },
        {
          name: "主奴調教",
          value: "bdsm",
          type_name: "SelectOption"
        },
        {
          name: "多P群交",
          value: "groupsex",
          type_name: "SelectOption"
        },
        {
          name: "男友視角",
          value: "pov",
          type_name: "SelectOption"
        },
        {
          name: "凌辱強暴",
          value: "rape",
          type_name: "SelectOption"
        },
        {
          name: "無碼解放",
          value: "uncensored",
          type_name: "SelectOption"
        }
      ]
    }]
  }

  getSourcePreferences() {
    throw new Error("getSourcePreferences not implemented");
  }
}
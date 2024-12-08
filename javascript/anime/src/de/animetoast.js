const mangayomiSources = [{
	"name": "AnimeToast",
	"lang": "de",
	"baseUrl": "https://www.animetoast.cc",
	"apiUrl": "",
	"iconUrl": "https://www.animetoast.cc/wp-content/uploads/2018/03/toastfavi-300x300.png",
	"typeSource": "single",
	"isManga": false,
	"isNsfw": false,
	"version": "0.0.1",
	"dateFormat": "",
	"dateFormatLocale": "",
	"pkgPath": ""
}];

class DefaultExtension extends MProvider {
	
	constructor () {
		super();
		this.client = new Client();
	}
	
	async getPopular(page) {
		const baseUrl = this.source.baseUrl;
		const res = await this.client.get(baseUrl);
		const document = new Document(res.body);
		const elements = document.select("div.row div.col-md-4 div.video-item");
		const list = await Promise.all(
			elements.map(async (element) => {
				const name = element.selectFirst("div.item-thumbnail a").attr("title");
				const fullLink = element.selectFirst("div.item-thumbnail a").attr("href");
				const link = fullLink.startsWith(baseUrl) ? fullLink.substring(baseUrl.length) : fullLink;
				const detailsRes = await this.client.get(fullLink);
				const detailsDoc = new Document(detailsRes.body);
				const imageUrl = detailsDoc.selectFirst(".item-content p img").attr("src");
				return { name, imageUrl, link };
			})
		);
		return {
			list: list,
			hasNextPage: false,
		};
	}
	
	get supportsLatest() {
		return false;
	}
	
	async search(query, page, filters) {
		const baseUrl = this.source.baseUrl;
		const res = await this.client.get(`${baseUrl}/page/${page}/?s=${query}`);
		const document = new Document(res.body);
		const hasNextPage = document.selectFirst("li.next a")?.attr("href") != null;
		const elements = document.select("div.item-thumbnail a[href]");
		const list = await Promise.all(
			elements.map(async (element) => {
				const name = element.attr("title");
				const fullLink = element.attr("href");
				const link = fullLink.startsWith(baseUrl) ? fullLink.substring(baseUrl.length) : fullLink;
				const detailsRes = await this.client.get(fullLink);
				const detailsDoc = new Document(detailsRes.body);
				const imageUrl = detailsDoc.selectFirst(".item-content p img").attr("src");
				return { name, imageUrl, link };
			})
		);
		return {
			list: list,
			hasNextPage,
		}
	}
	
	async getDetail(url) {
		const baseUrl = this.source.baseUrl;
		const res = await this.client.get(baseUrl + url);
		const document = new Document(res.body);
		const name = document.selectFirst("h1").text;
		const imageUrl = document.selectFirst(".item-content p img").attr("src");
		const description = document.selectFirst("div.item-content div + p").text;
		const genreText = document.xpathFirst('//p[contains(text(),"Genre:")]/text()') || "";
		const genre = genreText.replace("Genre:", "").split(",").map(tag => tag.trim());
		const categoryTag = document.xpath('//*[@rel="category tag"]/text()');
		const status = categoryTag.includes("Airing") ? 0 : 1;
		
		let episodes = [];
		const promises = [];
		promises.push(this.episodeFromElement(document, categoryTag));
		for (const p of (await Promise.allSettled(promises))) {
			if (p.status == 'fulfilled') {
				episodes.push(...p.value);
			}
		}
		episodes.reverse();
		return { description, genre, status, episodes, name, imageUrl };
	}
	
	async episodeFromElement(element, categoryTag) {
		const list = [];
		if (categoryTag.includes("Serie")) {
			const episodeElements = element.selectFirst("#multi_link_tab0")?.attr("id") != null
				? element.select("#multi_link_tab0 a")
				: element.select("#multi_link_tab1 a");
			for (const episodeElement of episodeElements) {
				const name = episodeElement.text.trim();
				const link = episodeElement.attr("href");
				const url = link.startsWith(this.source.baseUrl) ? link.substring(this.source.baseUrl.length) : link;
				if (name && url) {
					list.push({ name, url });
				}
			}
		} else {
			const name = element.selectFirst("h1.light-title").text
			const url = element.selectFirst("#multi_link_tab0 a").attr("href");
			if (name && url) {
				list.push({ name, url });
			}
		}
		return list;
	}
	
	async getVideoList(url) {
		const baseUrl = this.source.baseUrl;
		const res = await this.client.get(baseUrl + url);
		const document = new Document(res.body);
		const fEp = document.selectFirst("div.tab-pane");
		const videos = [];
		const ep = [];
		let epcu = 100;
		if (fEp.text.includes(":") || fEp.text.includes("-")) {
			const tx = document.select("div.tab-pane");

			for (let e of tx) {
				const sUrl = e.selectFirst("a").attr("href");
				const doc = new Document((await this.client.get(sUrl)).body);
				const nUrl = doc.selectFirst("#player-embed a").attr("href");
				const nDoc = new Document((await this.client.get(nUrl)).body);
				const currentLink = document.selectFirst("div.tab-pane a.current-link")?.text || "";
				const substringAfter = (text, delimiter) => {
					const index = text.indexOf(delimiter);
					return index !== -1 ? text.substring(index + delimiter.length) : "";
				};
				epcu = parseInt(substringAfter(currentLink, "Ep.")) || 100;
				ep = nDoc.select("div.tab-pane a");
			}
		} else {
			const currentLink = document.selectFirst("div.tab-pane a.current-link")?.text || "";
			const substringAfter = (text, delimiter) => {
				const index = text.indexOf(delimiter);
				return index !== -1 ? text.substring(index + delimiter.length) : "";
			};
			epcu = parseInt(substringAfter(currentLink, "Ep.")) || 100;
			ep = nDoc.select("div.tab-pane a");
		}
	}
	
	getFilterList() {
		throw new Error("getFilterList not implemented");
	}
	
	getSourcePreferences() {
		const hosts = ['VOE', 'DoodStream', 'Filemoon', 'Mp4Upload'];
		return [
            {
                key: 'preferred_hoster',
                listPreference: {
                    title: 'Standard-Hoster',
                    summary: '',
                    valueIndex: 0,
                    entries: hosts,
                    entryValues: hosts
                }
            },
			{
                key: "hoster_selection",
                multiSelectListPreference: {
                    title: "Hoster auswählen",
                    summary: "",
                    entries: hosts,
                    entryValues: hosts,
                    values: hosts
                }
            }
		];
	}
}

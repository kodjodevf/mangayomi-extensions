import 'package:mangayomi/bridge_lib.dart';

class Nyaa extends MProvider {
  Nyaa({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(
            "${source.baseUrl}/?f=0&c=${getPreferenceValue(source.id, "preferred_categorie_page")}&q=&s=downloads&o=desc&p=$page")))
        .body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse(
            "${source.baseUrl}/?f=0&c=${getPreferenceValue(source.id, "preferred_categorie_page")}&q=$page")))
        .body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    url =
        "${source.baseUrl}/?f=0&c=${getPreferenceValue(source.id, "preferred_categorie_page")}&q=${query.replaceAll(" ", "+")}&p=$page";
    for (var filter in filters) {
      if (filter.type == "SortFilter") {
        url += "${ll(url)}s=${filter.values[filter.state.index].value}";
        final asc = filter.state.ascending ? "&o=asc" : "&o=desc";
        url += "${ll(url)}$asc";
      }
    }
    final res = (await client.get(Uri.parse(url))).body;
    return parseAnimeList(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    MManga anime = MManga();
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    String description =
        (document.xpathFirst('//div[@class="panel-body"]/text()') ?? "")
            .replaceAll("\n", "");
    description +=
        "\n\n${(document.xpathFirst('//div[@class="panel panel-default"]/text()') ?? "").trim().replaceAll("\n", "")}";
    anime.description = description;
    MChapter ep = MChapter();
    ep.name = "Torrent";
    ep.url =
        "${source.baseUrl}/download/${substringAfterLast(url, '/')}.torrent";
    anime.chapters = [ep];
    return anime;
  }

  @override
  List<dynamic> getFilterList() {
    return [
      SortFilter("SortFilter", "Sort by", SortState(0, true), [
        SelectFilterOption("None", ""),
        SelectFilterOption("Size", "size"),
        SelectFilterOption("Date", "id"),
        SelectFilterOption("Seeders", "seeders"),
        SelectFilterOption("Leechers", "leechers"),
        SelectFilterOption("Download", "downloads")
      ])
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_categorie_page",
          title: "Preferred categorie page",
          summary: "",
          valueIndex: 0,
          entries: ["Anime", "Live Action"],
          entryValues: ["1_0", "4_0"]),
    ];
  }

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final document = parseHtml(res);

    final values = document
        .select("body > div > div.table-responsive > table > tbody > tr");
    for (var value in values) {
      MManga anime = MManga();
      anime.imageUrl =
          "${source.baseUrl}${getUrlWithoutDomain(value.selectFirst("td:nth-child(1) > a > img").getSrc)}";
      MElement firstElement = value
          .select("td > a")
          .where((MElement e) =>
              e.outerHtml.contains("/view/") &&
              !e.outerHtml.contains("#comments"))
          .toList()
          .first;
      anime.link =
          "${source.baseUrl}${getUrlWithoutDomain(firstElement.getHref)}";
      anime.name = firstElement.attr("title");
      animeList.add(anime);
    }

    final hasNextPage =
        xpath(res, '//ul[@class="pagination"]/li[contains(text(),"»")]/a/@href')
            .isNotEmpty;
    return MPages(animeList, hasNextPage);
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

Nyaa main(MSource source) {
  return Nyaa(source: source);
}

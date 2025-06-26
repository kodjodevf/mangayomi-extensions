import 'package:mangayomi/bridge_lib.dart';

class Nyaa extends MProvider {
  Nyaa({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(
      Uri.parse(
        "${getBaseUrl()}/?f=0&c=${getPreferenceValue(source.id, "preferred_categorie_page")}&q=&s=downloads&o=desc&p=$page",
      ),
    )).body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(
      Uri.parse(
        "${getBaseUrl()}/?f=0&c=${getPreferenceValue(source.id, "preferred_categorie_page")}&q=$page",
      ),
    )).body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    url =
        "${getBaseUrl()}/?f=0&c=${getPreferenceValue(source.id, "preferred_categorie_page")}&q=${query.replaceAll(" ", "+")}&p=$page";
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

  String extractPanelBody(MDocument document) {
    final panelBody = document.selectFirst('.panel-body');
    if (panelBody == null) return "";

    final rows = panelBody.select('.row');

    final Map<String, String> info = {};
    for (var row in rows) {
      final labels = row.select('.col-md-1');
      for (var label in labels) {
        final key = label.text.replaceAll(":", "").trim();
        final valueDiv = label.nextElementSibling;
        if (valueDiv == null) continue;

        final links = valueDiv.select('a');
        String value;
        if (links.isNotEmpty) {
          value = links.map((a) => a.text.trim()).join(' - ');
        } else {
          value = valueDiv.text.trim();
        }

        info[key] = value;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln("Torrent Info:\n");
    info.forEach((k, v) {
      buffer.writeln("${k.padRight(11)}: $v");
    });
    if (getPreferenceValue(source.id, "torrent_description_visible")) {
      buffer.writeln("\n\n");
      buffer.writeln("Torrent Description: \n");
      buffer.writeln(
        document
            .select("#torrent-description")
            .map((e) => e.text.trim())
            .join("\n\n"),
      );
    }

    return buffer.toString();
  }

  @override
  Future<MManga> getDetail(String url) async {
    MManga anime = MManga();
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);

    anime.description = extractPanelBody(document);

    List<MChapter> chapters = [];
    chapters.add(
      MChapter(
        name: "Torrent",
        url: "${getBaseUrl()}/download/${substringAfterLast(url, '/')}.torrent",
      ),
    );
    anime.chapters = chapters;

    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    var video = MVideo();
    video
      ..url = url
      ..originalUrl = url
      ..quality = "";
    return [video];
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
        SelectFilterOption("Download", "downloads"),
      ]),
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
        entryValues: ["1_0", "4_0"],
      ),
      SwitchPreferenceCompat(
        key: "torrent_description_visible",
        title: "Display Torrent Description",
        summary:
            "Enable to show the full torrent description in the details view.",
        value: false,
      ),
      EditTextPreference(
        key: "domain_url",
        title: 'Edit URL',
        summary: "",
        value: source.baseUrl,
        dialogTitle: "URL",
        dialogMessage: "",
      ),
    ];
  }

  String getBaseUrl() {
    final baseUrl = getPreferenceValue(source.id, "domain_url")?.trim();

    if (baseUrl == null || baseUrl.isEmpty) {
      return source.baseUrl;
    }

    return baseUrl.endsWith("/")
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final document = parseHtml(res);

    final values = document.select(
      "body > div > div.table-responsive > table > tbody > tr",
    );
    for (var value in values) {
      MManga anime = MManga();
      anime.imageUrl =
          "${getBaseUrl()}${getUrlWithoutDomain(value.selectFirst("td:nth-child(1) > a > img").getSrc)}";
      MElement firstElement = value
          .select("td > a")
          .where(
            (MElement e) =>
                e.outerHtml.contains("/view/") &&
                !e.outerHtml.contains("#comments"),
          )
          .toList()
          .first;
      anime.link =
          "${getBaseUrl()}${getUrlWithoutDomain(firstElement.getHref)}";
      anime.name = firstElement.attr("title");
      animeList.add(anime);
    }

    final hasNextPage = xpath(
      res,
      '//ul[@class="pagination"]/li[contains(text(),"»")]/a/@href',
    ).isNotEmpty;
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

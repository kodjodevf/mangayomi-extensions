import 'package:mangayomi/bridge_lib.dart';
import 'dart:math';

class AnimesVision extends MProvider {
  AnimesVision({required this.source});

  MSource source;

  final Client client = Client();

  @override
  String get baseUrl => source.baseUrl;

  @override
  Map<String, String> get headers => {
    "Referer": baseUrl,
    "Accept-Language": "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7",
  };

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(baseUrl), headers: headers)).body;
    final document = parseHtml(res);
    final elements = document.select(
      "div#anime-trending div.item > a.film-poster",
    );
    List<MManga> animeList = [];
    for (var element in elements) {
      var anime = MManga();
      var img = element.selectFirst("img");
      anime.name = img.attr("title");
      anime.link = getUrlWithoutDomain(element.attr("href"));
      anime.imageUrl = img.attr("src");
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage(document));
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(
          Uri.parse("$baseUrl/lancamentos?page=$page"),
          headers: headers,
        )).body;
    final document = parseHtml(res);
    final elements = document.select(
      "div.container div.screen-items > div.item",
    );
    List<MManga> animeList = [];
    for (var element in elements) {
      var anime = MManga();
      anime.name = substringAfter(element.selectFirst("h3").text, "-").trim();
      anime.link = getUrlWithoutDomain(element.selectFirst("a").attr("href"));
      anime.imageUrl = element.selectFirst("img")?.attr("src") ?? "";
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage(document));
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res =
        (await client.get(
          Uri.parse("$baseUrl/search-anime?nome=$query&page=$page"),
        )).body;
    final document = parseHtml(res);
    final elements = document.select("div.film_list-wrap div.film-poster");
    List<MManga> animeList = [];
    for (var element in elements) {
      var anime = MManga();
      final elementA = element.selectFirst("a");
      anime.name = elementA.attr("title");
      anime.link = getUrlWithoutDomain(elementA.attr("href"));
      anime.imageUrl = element.selectFirst("img").attr("data-src");
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage(document));
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Atualmente sendo exibido": 0, "Fim da exibição": 1},
    ];
    MManga anime = MManga();
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    var document = await getRealDoc(parseHtml(res), "$baseUrl$url");
    final content = document.selectFirst("div#ani_detail div.anis-content");
    final detail = content.selectFirst("div.anisc-detail");
    final infos = content.selectFirst("div.anisc-info");
    anime.imageUrl = content.selectFirst("img")?.attr("src");
    anime.name = detail.selectFirst("h2.film-name").text;
    anime.genre = getInfo(infos, "Gêneros").split(",");
    anime.author = getInfo(infos, "Produtores");
    anime.artist = getInfo(infos, "Estúdios");
    anime.status = parseStatus(getInfo(infos, "Status"), statusList);
    String description = getInfo(infos, "Sinopse");
    if (getInfo(infos, "Inglês").isNotEmpty)
      description += '\n\nTítulo em inglês: ${getInfo(infos, "Inglês")}';
    anime.description = description;
    if (getInfo(infos, "Japonês").isNotEmpty)
      description += '\nTítulo em Japonês: ${getInfo(infos, "Japonês")}';
    if (getInfo(infos, "Foi ao ar em").isNotEmpty)
      description += '\nFoi ao ar em: ${getInfo(infos, "Foi ao ar em")}';
    if (getInfo(infos, "Temporada").isNotEmpty)
      description += '\nTemporada: ${getInfo(infos, "Temporada")}';
    if (getInfo(infos, "Duração").isNotEmpty)
      description += '\nDuração: ${getInfo(infos, "Duração")}';
    if (getInfo(infos, "Fansub").isNotEmpty)
      description += '\nFansub: ${getInfo(infos, "Fansub")}';
    anime.description = description;
    List<MChapter> episodeList = [];
    for (var element
        in document.select("div.container div.screen-items > div.item") ?? []) {
      episodeList.add(episodeFromElement(element));
    }

    while (hasNextPage(document)) {
      if (episodeList.isNotEmpty) {
        final nextUrl = nextPageElements(
          document,
        )[0].selectFirst("a").attr("href");
        document = parseHtml((await client.get(Uri.parse(nextUrl))).body);
      }
      for (var element
          in document.select("div.container div.screen-items > div.item") ??
              []) {
        episodeList.add(episodeFromElement(element));
      }
    }
    anime.chapters = episodeList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    final encodedScript =
        document
            .selectFirst("div.player-frame div#playerglobalapi ~ script")
            .text;
    final decodedScript = decodeScriptFromString(encodedScript);
    List<MVideo> videos = [];
    for (RegExpMatch match in RegExp(
      r'"file":"(\S+?)",.*?"label":"(.*?)"',
    ).allMatches(decodedScript)) {
      final videoUrl = match.group(1)!.replaceAll('\\', '');
      final qualityName = match.group(2);
      var video = MVideo();
      video.url = videoUrl;
      video.headers = headers;
      video.quality = 'PlayerVision $qualityName';
      video.originalUrl = videoUrl;
      videos.add(video);
    }
    return videos;
  }

  bool hasNextPage(MDocument document) {
    return nextPageElements(document).isNotEmpty;
  }

  List<MElement> nextPageElements(MDocument document) {
    final elements =
        document
            .select("ul.pagination li.page-item")
            .where(
              (MElement e) =>
                  e.outerHtml.contains("›") &&
                  !e.outerHtml.contains("disabled"),
            )
            .toList();
    return elements;
  }

  Future<MDocument> getRealDoc(MDocument document, String originalUrl) async {
    if (["/episodio-", "/filme-"].any((e) => originalUrl.contains(e))) {
      final url = document.selectFirst("h2.film-name > a").attr("href");
      final res = (await client.get(Uri.parse(url))).body;
      return parseHtml(res);
    }
    return document;
  }

  String getInfo(MElement element, String key) {
    final divs =
        element
            .select("div.item")
            .where((MElement e) => e.outerHtml.contains(key))
            .toList();
    String text = "";
    if (divs.isNotEmpty) {
      MElement div = divs[0];
      var elementsA = div.select("a[href]");
      if (elementsA.isEmpty) {
        String selector =
            div.outerHtml.contains("w-hide") ? "div.text" : "span.name";
        text = div.selectFirst(selector).text.trim();
      } else {
        text = elementsA.map((MElement e) => e.text.trim()).toList().join(', ');
      }
    }
    return text;
  }

  MChapter episodeFromElement(MElement element) {
    var anime = MChapter();
    anime.url = getUrlWithoutDomain(element.selectFirst("a").attr("href"));
    anime.name = element.selectFirst("h3").text.trim();
    return anime;
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String quality = getPreferenceValue(sourceId, "preferred_quality");

    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;

      if (a.quality.contains(quality)) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.contains(quality)) {
        qualityMatchB = 1;
      }
      if (qualityMatchA != qualityMatchB) {
        return qualityMatchB - qualityMatchA;
      }

      final regex = RegExp(r'(\d+)p');
      final matchA = regex.firstMatch(a.quality);
      final matchB = regex.firstMatch(b.quality);
      final int qualityNumA = int.tryParse(matchA?.group(1) ?? '0') ?? 0;
      final int qualityNumB = int.tryParse(matchB?.group(1) ?? '0') ?? 0;
      return qualityNumB - qualityNumA;
    });
    return videos;
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
        key: "preferred_quality",
        title: "Qualidade preferida",
        summary: "",
        valueIndex: 1,
        entries: ["480p", "720p", "1080p", "4K"],
        entryValues: ["1080", "720", "480", "4K"],
      ),
    ];
  }

  int convertToNum(String thing, int limit) {
    int result = 0;
    int i = 0;
    for (var n in thing.split('').reversed.toList()) {
      final a = int.tryParse(n) ?? 0;
      result += a * pow(limit, i).toInt();
      i++;
    }
    return result;
  }

  String decodeScript(
    String encodedString,
    String magicStr,
    int offset,
    int limit,
  ) {
    RegExp regex = RegExp('\\w');
    List<String> parts = encodedString.split(magicStr[limit]);
    List<String> decodedParts = [];
    for (String part in parts.sublist(0, parts.length - 1)) {
      String replaced = part;
      for (Match match in regex.allMatches(part)) {
        replaced = replaced.replaceFirst(
          match.group(0)!,
          magicStr.indexOf(match.group(0)!).toString(),
        );
      }
      int charInt = convertToNum(replaced, limit) - offset;
      decodedParts.add(String.fromCharCode(charInt));
    }
    return decodedParts.join('');
  }

  String decodeScriptFromString(String script) {
    RegExp regex = RegExp(r'\}\("(\w+)",.*?"(\w+)",(\d+),(\d+),.*?\)');
    Match? match = regex.firstMatch(script);
    if (match != null) {
      return decodeScript(
        match.group(1)!,
        match.group(2)!,
        int.tryParse(match.group(3)!) ?? 0,
        int.tryParse(match.group(4)!) ?? 0,
      );
    } else {
      return script;
    }
  }
}

AnimesVision main(MSource source) {
  return AnimesVision(source: source);
}

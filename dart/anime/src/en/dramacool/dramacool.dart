import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class DramaCool extends MProvider {
  DramaCool({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  String get baseUrl => getPreferenceValue(source.id, "overrideBaseUrl");

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(Uri.parse("$baseUrl/most-popular-drama?page=$page")))
            .body;
    final document = parseHtml(res);
    return animeFromElement(document.select("ul.list-episode-item li a"),
        document.selectFirst("li.next a")?.attr("href") != null);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(Uri.parse("$baseUrl/recently-added?page=$page")))
            .body;
    final document = parseHtml(res);
    return animeFromElement(document.select("ul.switch-block a"),
        document.selectFirst("li.next a")?.attr("href") != null);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res = (await client
            .get(Uri.parse("$baseUrl/search?keyword=$query&page=$page")))
        .body;
    final document = parseHtml(res);
    return animeFromElement(document.select("ul.list-episode-item li a"),
        document.selectFirst("li.next a")?.attr("href") != null);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1}
    ];
    url = getUrlWithoutDomain(url);
    if (url.contains("-episode-") && url.endsWith(".html")) {
      final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
      url = parseHtml(res).selectFirst("div.category a").attr("href");
    }
    url = getUrlWithoutDomain(url);

    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    MManga anime = MManga();
    anime.description = document
        .selectFirst("div.info")
        .select("p")
        .map((MElement e) {
          if (!e.outerHtml.contains("<span")) {
            return e.text;
          }
          return "";
        })
        .toList()
        .join("\n");
    final author =
        xpath(res, '//p[contains(text(),"Original Network:")]/a/text()');
    if (author.isNotEmpty) {
      anime.author = author.first;
    }
    anime.genre = xpath(res, '//p[contains(text(),"Genre:")]/a/text()');
    final status = xpath(res, '//p[contains(text(),"Status")]/a/text()');
    if (status.isNotEmpty) {
      anime.status = parseStatus(status.first, statusList);
    }
    List<MChapter> episodesList = [];
    final episodeListElements = document.select("ul.all-episode li a");

    for (var element in episodeListElements) {
      var epNum =
          substringAfterLast(element.selectFirst("h3").text, "Episode ");
      var type = element.selectFirst("span.type")?.text ?? "RAW";
      var date = element.selectFirst("span.time")?.text ?? "";
      MChapter ep = MChapter();
      ep.name = "$type: Episode $epNum".trim();
      ep.url = element.getHref;
      if (date.isNotEmpty)
        ep.dateUpload = parseDates([element.selectFirst("span.time")?.text],
                "yyyy-MM-dd HH:mm:ss", "en")
            .first;
      episodesList.add(ep);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    url = getUrlWithoutDomain(url);

    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    String iframeUrl = document.selectFirst("iframe")?.getSrc ?? "";
    if (iframeUrl.isEmpty) return [];
    if (iframeUrl.startsWith("//")) {
      iframeUrl = "https:$iframeUrl";
    }
    var iframeDoc = parseHtml((await client.get(Uri.parse(iframeUrl))).body);
    final serverElements = iframeDoc.select("ul.list-server-items li");
    List<MVideo> videos = [];
    for (var serverElement in serverElements) {
      var url = serverElement.attr("data-video");
      List<MVideo> a = [];
      if (url.contains("dood")) {
        a = await doodExtractor(url, "DoodStream");
      } else if (url.contains("dwish")) {
        a = await streamWishExtractor(url, "StreamWish");
      } else if (url.contains("streamtape")) {
        a = await streamTapeExtractor(url, "StreamTape");
      }
      videos.addAll(a);
    }
    return sortVideos(videos, source.id);
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
          key: "overrideBaseUrl",
          title: "Override BaseUrl",
          summary: "",
          value: "https://dramacool.pa",
          dialogTitle: "Override BaseUrl",
          dialogMessage: "",
          text: "https://dramacool.pa"),
      ListPreference(
          key: "preferred_quality",
          title: "Preferred quality",
          summary: "",
          valueIndex: 0,
          entries: [
            "1080p",
            "720p",
            "480p",
            "360p",
            "Doodstream",
            "StreamTape"
          ],
          entryValues: [
            "1080",
            "720",
            "480",
            "360",
            "Doodstream",
            "StreamTape"
          ])
    ];
  }

  MPages animeFromElement(List<MElement> elements, bool hasNextPage) {
    List<MManga> animeList = [];
    for (var element in elements) {
      MManga anime = MManga();
      anime.name = element.selectFirst("h3")?.text ?? "Serie";
      anime.imageUrl = (element.selectFirst("img")?.attr("data-original") ?? "")
              .replaceAll(" ", "%20") ??
          "";
      anime.link = element.getHref;
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage);
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
}

DramaCool main(MSource source) {
  return DramaCool(source: source);
}

import 'package:mangayomi/bridge_lib.dart';

class AnimeToast extends MProvider {
  AnimeToast({required this.source});

  MSource source;

  final Client client = Client();

  @override
  bool get supportsLatest => false;

  @override
  String get baseUrl => source.baseUrl;

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(baseUrl))).body;
    final document = parseHtml(res);
    final elements = document.select("div.row div.col-md-4 div.video-item");
    List<MManga> animeList = [];
    for (var element in elements) {
      MManga anime = MManga();
      anime.name = element.selectFirst("div.item-thumbnail a").attr("title");
      anime.link = getUrlWithoutDomain(
        element.selectFirst("div.item-thumbnail a").attr("href"),
      );
      anime.imageUrl = element
          .selectFirst("div.item-thumbnail a img")
          .attr("src");
      animeList.add(anime);
    }
    return MPages(animeList, false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res =
        (await client.get(Uri.parse("$baseUrl/page/$page/?s=$query"))).body;
    final document = parseHtml(res);
    final elements = document.select("div.item-thumbnail a[href]");
    List<MManga> animeList = [];
    for (var element in elements) {
      MManga anime = MManga();
      anime.name = element.attr("title");
      anime.link = getUrlWithoutDomain(element.attr("href"));
      anime.imageUrl = element.selectFirst("a img").attr("src");
      animeList.add(anime);
    }
    return MPages(
      animeList,
      document.selectFirst("li.next a")?.attr("href") != null,
    );
  }

  @override
  Future<MManga> getDetail(String url) async {
    MManga anime = MManga();
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    anime.imageUrl = document.selectFirst(".item-content p img").attr("src");
    anime.genre =
        (document.xpathFirst('//p[contains(text(),"Genre:")]/text()') ?? "")
            .replaceAll("Genre:", "")
            .split(",");
    anime.description = document.selectFirst("div.item-content div + p").text;
    final categoryTag = document.xpath('//*[@rel="category tag"]/text()');
    if (categoryTag.isNotEmpty) {
      if (categoryTag.contains("Airing")) {
        anime.status = MStatus.ongoing;
      } else {
        anime.status = MStatus.completed;
      }
    }
    List<MChapter>? episodesList = [];
    if (categoryTag.contains("Serie")) {
      List<MElement> elements = [];
      if (document.selectFirst("#multi_link_tab0")?.attr("id") != null) {
        elements = document.select("#multi_link_tab0");
      } else {
        elements = document.select("#multi_link_tab1");
      }

      for (var element in elements) {
        final episodeElement = element.selectFirst("a");
        final epT = episodeElement.text;
        if (epT.contains(":") || epT.contains("-")) {
          final url = episodeElement.attr("href");
          final document = parseHtml((await client.get(Uri.parse(url))).body);
          final nUrl = document.selectFirst("#player-embed a").attr("href");
          final nDoc = parseHtml((await client.get(Uri.parse(nUrl))).body);
          final nEpEl = nDoc.select("div.tab-pane a");
          for (var epElement in nEpEl) {
            MChapter ep = MChapter();
            ep.name = epElement.text;
            ep.url = getUrlWithoutDomain(epElement.attr("href"));
            episodesList.add(ep);
          }
        } else {
          final episodeElements = element.select("a");
          for (var epElement in episodeElements) {
            MChapter ep = MChapter();
            ep.name = epElement.text;
            ep.url = getUrlWithoutDomain(epElement.attr("href"));
            episodesList.add(ep);
          }
        }
      }
    } else {
      MChapter ep = MChapter();
      ep.name = document.selectFirst("h1.light-title")?.text ?? "Film";
      ep.url = getUrlWithoutDomain(
        document.selectFirst("link[rel=canonical]").attr("href"),
      );
      episodesList.add(ep);
    }
    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  List<String> preferenceHosterSelection() {
    return getPreferenceValue(source.id, "hoster_selection");
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    final fEp = document.selectFirst("div.tab-pane");
    List<MVideo> videos = [];
    List<MElement> ep = [];
    int epcu = 100;

    if (fEp.text.contains(":") || fEp.text.contains("-")) {
      final tx = document.select("div.tab-pane");

      for (var e in tx) {
        final sUrl = e.selectFirst("a").attr("href");
        final doc = parseHtml((await client.get(Uri.parse(sUrl))).body);
        final nUrl = doc.selectFirst("#player-embed a").attr("href");
        final nDoc = parseHtml((await client.get(Uri.parse(nUrl))).body);
        epcu =
            int.tryParse(
              substringAfter(
                document.selectFirst("div.tab-pane a.current-link")?.text ?? "",
                "Ep.",
              ),
            ) ??
            100;
        ep = nDoc.select("div.tab-pane a");
      }
    } else {
      epcu =
          int.tryParse(
            substringAfter(
              document.selectFirst("div.tab-pane a.current-link")?.text ?? "",
              "Ep.",
            ),
          ) ??
          100;
      ep = document.select("div.tab-pane a");
    }
    final hosterSelection = preferenceHosterSelection();
    for (var e in ep) {
      if (int.tryParse(substringAfter(e.text, "Ep.")) == epcu) {
        final epUrl = e.attr("href");
        final newdoc = parseHtml((await client.get(Uri.parse(epUrl))).body);
        final elements = newdoc.select("#player-embed");
        for (var element in elements) {
          final link = element.selectFirst("a").getHref ?? "";
          if (link.contains("https://voe.sx") &&
              hosterSelection.contains("voe")) {
            videos.addAll(await voeExtractor(link, "Voe"));
          }
        }
        for (var element in elements) {
          List<MVideo> a = [];
          final link = element.selectFirst("iframe").getSrc ?? "";
          if ((link.contains("https://dood") ||
                  link.contains("https://ds2play") ||
                  link.contains("https://d0")) &&
              hosterSelection.contains("dood")) {
            a = await doodExtractor(link, "DoodStream");
          } else if (link.contains("filemoon") &&
              hosterSelection.contains("filemoon")) {
            a = await filemoonExtractor(link, "", "");
          } else if (link.contains("mp4upload") &&
              hosterSelection.contains("mp4upload")) {
            a = await mp4UploadExtractor(url, null, "", "");
          }
          videos.addAll(a);
        }
      }
    }
    return sortVideos(videos);
  }

  List<MVideo> sortVideos(List<MVideo> videos) {
    String server = getPreferenceValue(source.id, "preferred_hoster");

    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;
      if (a.quality.toLowerCase().contains(server)) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.toLowerCase().contains(server)) {
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
        key: "preferred_hoster",
        title: "Standard-Hoster",
        summary: "",
        valueIndex: 0,
        entries: ["Voe", "DoodStream", "Filemoon", "Mp4upload"],
        entryValues: ["voe", "doodStream", "filemoon", "mp4upload"],
      ),
      MultiSelectListPreference(
        key: "hoster_selection",
        title: "Hoster auswählen",
        summary: "",
        entries: ["Voe", "DoodStream", "Filemoon", "Mp4upload"],
        entryValues: ["voe", "dood", "filemoon", "mp4upload"],
        values: ["voe", "dood", "filemoon", "mp4upload"],
      ),
    ];
  }
}

AnimeToast main(MSource source) {
  return AnimeToast(source: source);
}

import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AnimeOnlineNinja extends MProvider {
  AnimeOnlineNinja({required this.source});

  MSource source;

  final Client client = Client();

  @override
  bool get supportsLatest => false;

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(Uri.parse("${source.baseUrl}/tendencias"))).body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    String pageStr = page == 1 ? "" : "page/$page/";
    final res =
        (await client.get(
          Uri.parse(
            "${source.baseUrl}/$pageStr?s=${query.replaceAll(" ", "+")}",
          ),
        )).body;
    return parseAnimeList(
      res,
      selector: "div.result-item div.image a",
      hasNextPage:
          parseHtml(res)
              .selectFirst(
                "div.pagination > *:last-child:not(span):not(.current)",
              )
              ?.text !=
          null,
    );
  }

  @override
  Future<MManga> getDetail(String url) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}$url"))).body;
    MManga anime = MManga();
    final document = parseHtml(res);
    anime.description = document.selectFirst("div#info").text;
    anime.genre =
        document
            .selectFirst("div.sheader")
            .select("div.data > div.sgeneros > a")
            .map((e) => e.text)
            .toList();

    List<MChapter>? episodesList = [];
    final seasonElements = document.select("div#seasons > div");
    if (seasonElements.isEmpty) {
      MChapter episode = MChapter();
      episode.name = "Película";
      episode.url = getUrlWithoutDomain(url);
      episodesList.add(episode);
    } else {
      for (var seasonElement in seasonElements) {
        final seasonName = seasonElement.selectFirst("span.se-t").text;
        for (var epElement in seasonElement.select("ul.episodios > li")) {
          final href = epElement.selectFirst("a[href]");
          final epNum = epElement.selectFirst('div.numerando')?.text ?? "0 - 0";
          MChapter episode = MChapter();
          episode.name =
              "Season $seasonName x ${substringAfter(epNum, '- ')} ${href.text}";
          episode.url = getUrlWithoutDomain(href!.getHref);
          episodesList.add(episode);
        }
      }
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}$url"))).body;
    final document = parseHtml(res);
    final players = document.select("ul#playeroptionsul li");
    List<MVideo> videos = [];
    for (var player in players) {
      final name = player.selectFirst("span.title").text;
      final type = player.attr("data-type");
      final id = player.attr("data-post");
      final num = player.attr("data-nume");
      final resUrl =
          (await client.get(
            Uri.parse(
              "${source.baseUrl}/wp-json/dooplayer/v1/post/$id?type=$type&source=$num",
            ),
          )).body;
      final url = substringBefore(
        substringAfter(resUrl, "\"embed_url\":\""),
        "\",",
      ).replaceAll("\\", "");
      videos.addAll(await extractVideos(url, name));
    }
    return sortVideos(videos, source.id);
  }

  Future<List<MVideo>> extractVideos(String url, String lang) async {
    List<MVideo> videos = [];
    List<MVideo> a = [];
    if (url.contains("saidochesto.top") || lang == "MULTISERVER") {
      return await extractFromMulti(url);
    } else if (["filemoon", "moon", "filemooon"].any((a) => url.contains(a))) {
      a = await filemoonExtractor(url, "$lang Filemoon - ", "");
    } else if ([
      "https://dood",
      "https://ds2play",
      "https://d0",
    ].any((a) => url.contains(a))) {
      a = await doodExtractor(url, "$lang DoodStream");
    } else if (["streamtape", "stp", "stape"].any((a) => url.contains(a))) {
      a = await streamTapeExtractor(url, "$lang StreamTape");
    } else if (url.contains("uqload")) {
      a = await uqloadExtractor(url, lang);
    } else if (url.contains("wolfstream")) {
      final resUrl = (await client.get(Uri.parse(url))).body;
      final jsData =
          parseHtml(resUrl).selectFirst("script:contains(sources)").text;
      final videoUrl = substringBefore(
        substringAfter(jsData, "{file:\""),
        "\"",
      );

      MVideo video = MVideo();
      video
        ..url = videoUrl
        ..originalUrl = videoUrl
        ..quality = "$lang WolfStream";

      a = [video];
    } else if ([
      "wishembed",
      "streamwish",
      "strwish",
      "wish",
    ].any((a) => url.contains(a))) {
      a = await streamWishExtractor(url, "$lang StreamWish");
    } else if (url.contains("mp4upload")) {
      a = await mp4UploadExtractor(url, null, "$lang", "");
    } else if ([
      "vidhide",
      "filelions.top",
      "vid.",
    ].any((a) => url.contains(a))) {
      a = await streamHideExtractor(url, lang);
    }
    videos.addAll(a);

    return videos;
  }

  Future<List<MVideo>> streamHideExtractor(String url, String prefix) async {
    final res = (await client.get(Uri.parse(url))).body;
    final masterUrl = substringBefore(
      substringAfter(
        substringAfter(substringAfter(unpackJs(res), "sources:"), "file:\""),
        "src:\"",
      ),
      '"',
    );
    final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;
    List<MVideo> videos = [];
    for (var it in substringAfter(
      masterPlaylistRes,
      "#EXT-X-STREAM-INF:",
    ).split("#EXT-X-STREAM-INF:")) {
      final quality =
          "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

      String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

      if (!videoUrl.startsWith("http")) {
        videoUrl =
            "${masterUrl.split("/").sublist(0, masterUrl.split("/").length - 1).join("/")}/$videoUrl";
      }

      MVideo video = MVideo();
      video
        ..url = videoUrl
        ..originalUrl = videoUrl
        ..quality = "$prefix StreamHideVid - $quality";
      videos.add(video);
    }
    return videos;
  }

  Future<List<MVideo>> uqloadExtractor(String url, String lang) async {
    final Client client = Client(
      source,
      json.encode({"useDartHttpClient": true}),
    );
    final res = (await client.get(Uri.parse(url))).body;
    final js = xpath(res, '//script[contains(text(), "sources:")]/text()');
    if (js.isEmpty) {
      return [];
    }

    final videoUrl = substringBefore(
      substringAfter(js.first, "sources: [\""),
      '"',
    );
    MVideo video = MVideo();
    video
      ..url = videoUrl
      ..originalUrl = videoUrl
      ..quality = "$lang Uqload"
      ..headers = {"Referer": "${Uri.parse(url).origin}/"};
    return [video];
  }

  Future<List<MVideo>> extractFromMulti(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);

    final prefLang = getPreferenceValue(source.id, "preferred_lang");
    String langSelector = "";
    if (prefLang.isEmpty) {
      langSelector = "div";
    } else {
      langSelector = "div.OD_$prefLang";
    }
    List<MVideo> videos = [];
    for (var element in document.select("div.ODDIV $langSelector > li")) {
      final hosterUrl = substringBefore(
        substringAfter(element.attr("onclick"), "('"),
        "')",
      );
      String lang = "";
      if (langSelector == "div") {
        lang = substringBefore(
          substringAfter(element.parent?.attr("class"), "OD_", ""),
          " ",
        );
      } else {
        lang = prefLang;
      }
      videos.addAll(await extractVideos(hosterUrl, lang));
    }

    return videos;
  }

  MPages parseAnimeList(
    String res, {
    String selector = "article.w_item_a > a",
    bool hasNextPage = false,
  }) {
    final elements = parseHtml(res).select(selector);
    List<MManga> animeList = [];
    for (var element in elements) {
      final url = getUrlWithoutDomain(element.getHref);
      if (!url.startsWith("/episodio/")) {
        MManga anime = MManga();
        final img = element.selectFirst("img");
        anime.name = img.attr("alt");
        anime.imageUrl =
            img?.attr("data-src") ??
            img?.attr("data-lazy-src") ??
            img?.attr("srcset") ??
            img?.getSrc;
        anime.link = url;
        animeList.add(anime);
      }
    }
    return MPages(animeList, hasNextPage);
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
        key: "preferred_lang",
        title: "Preferred language",
        summary: "",
        valueIndex: 0,
        entries: ["SUB", "All", "ES", "LAT"],
        entryValues: ["SUB", "", "ES", "LAT"],
      ),
      ListPreference(
        key: "preferred_server1",
        title: "Preferred server",
        summary: "",
        valueIndex: 0,
        entries: [
          "Filemoon",
          "DoodStream",
          "StreamTape",
          "Uqload",
          "WolfStream",
          "saidochesto.top",
          "VidHide",
          "StreamWish",
          "Mp4Upload",
        ],
        entryValues: [
          "Filemoon",
          "DoodStream",
          "StreamTape",
          "Uqload",
          "WolfStream",
          "saidochesto.top",
          "VidHide",
          "StreamWish",
          "Mp4Upload",
        ],
      ),
    ];
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String prefLang = getPreferenceValue(source.id, "preferred_lang");
    String server = getPreferenceValue(sourceId, "preferred_server1");
    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;

      if (a.quality.toLowerCase().contains(prefLang.toLowerCase()) &&
          a.quality.toLowerCase().contains(server.toLowerCase())) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.toLowerCase().contains(prefLang.toLowerCase()) &&
          b.quality.toLowerCase().contains(server.toLowerCase())) {
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

AnimeOnlineNinja main(MSource source) {
  return AnimeOnlineNinja(source: source);
}

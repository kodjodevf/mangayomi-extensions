import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Filma24 extends MProvider {
  Filma24({required this.source});

  MSource source;

  @override
  String get baseUrl => getPreferenceValue(source.id, "pref_domain_new");

  @override
  Future<MPages> getPopular(int page) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
    String pageNu = page == 1 ? "" : "/page/$page/";
    final res = (await client.get(Uri.parse("$baseUrl$pageNu"))).body;
    return animeFromRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
    String pageNu = page == 1 ? "" : "page/$page/";
    final res =
        (await client.get(Uri.parse("$baseUrl/$pageNu?sort=trendy"))).body;
    return animeFromRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
    final filters = filterList.filters;
    String url = "";
    String pageNu = page == 1 ? "" : "page/$page/";
    if (query.isNotEmpty) {
      url += "$baseUrl/search/$query/";
    } else {
      for (var filter in filters) {
        if (filter.type == "ReleaseFilter") {
          final year = filter.values[filter.state].value;
          if (year.isNotEmpty) {
            url = "/released-year/?release=$year/";
          }
        } else if (filter.type == "GenreFilter") {
          final genre = filter.values[filter.state].value;
          if (genre.isNotEmpty) {
            url = genre;
          }
        }
      }
      url = "$baseUrl$url";
    }

    url += pageNu;

    final res = (await client.get(Uri.parse(url))).body;
    return animeFromRes(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
    List<MChapter>? episodesList = [];
    if (!url.contains("seriale")) {
      MChapter episode = MChapter();
      episode.name = "Filma";
      episode.url = url;
      episodesList.add(episode);
    } else {
      final res = (await client.get(Uri.parse(url))).body;
      final document = parseHtml(res);
      final resultElements = document.select("div.row");

      for (var result in resultElements) {
        final elements = result?.select("div.movie-thumb") ?? [];

        for (var i = 0; i < elements.length; i++) {
          MChapter ep = MChapter();
          ep.name = elements[i].selectFirst("div > span").text;
          ep.url = elements[i].selectFirst("a").getHref;
          episodesList.add(ep);
        }
      }
    }

    MManga anime = MManga();
    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
    final res = (await client.get(Uri.parse(url))).body;
    List<MVideo> videos = [];
    final serverUrls = xpath(res, '//*[@class="player"]/div[1]/a/@href');
    for (var serverUrl in serverUrls) {
      List<MVideo> a = [];
      final serVres = (await client.get(Uri.parse("$url/$serverUrl"))).body;
      List<String> iframe = xpath(serVres, '//*[@id="plx"]/p/iframe/@src');
      if (iframe.isNotEmpty) {
        String i = iframe.first;
        if (i.startsWith("//")) {
          i = "https:$i";
        }
        if (i.contains("vidmoly")) {
          a = await vidmolyExtractor(i);
        } else if (i.contains("dood")) {
          a = await doodExtractor(i, "DoodStream");
        } else if (i.contains("oneupload")) {
          a = await oneuploadExtractor(i);
        } else if (i.contains("uqload")) {
          a = await uqloadExtractor(i);
        } else if (i.contains("voe.sx")) {
          a = await voeExtractor(i, "Voe");
        }
        videos.addAll(a);
      }
    }
    return videos;
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
        key: "pref_domain_new",
        title: "Domeni i përdorur aktualisht",
        summary: "",
        value: "https://www.filma24.band",
        dialogTitle: "Domeni i përdorur aktualisht",
        dialogMessage: "",
        text: "https://www.filma24.band",
      ),
    ];
  }

  @override
  List<dynamic> getFilterList() {
    return [
      SelectFilter("ReleaseFilter", "Viti", 0, [
        SelectFilterOption("<Select>", ""),
        SelectFilterOption("2024", "2024"),
        SelectFilterOption("2023", "2023"),
        SelectFilterOption("2022", "2022"),
        SelectFilterOption("2021", "2021"),
        SelectFilterOption("2020", "2020"),
        SelectFilterOption("2019", "2019"),
        SelectFilterOption("2018", "2018"),
        SelectFilterOption("2017", "2017"),
        SelectFilterOption("2016", "2016"),
        SelectFilterOption("2011-2015", "2011-2015"),
        SelectFilterOption("2006-2010", "2006-2010"),
        SelectFilterOption("2001-2005", "2001-2005"),
        SelectFilterOption("1991-2000", "1991-2000"),
        SelectFilterOption("1900-1990", "1900-1990"),
      ]),
      SelectFilter("GenreFilter", "Zhanri", 0, [
        SelectFilterOption("<Select>", ""),
        SelectFilterOption("SË SHPEJTI", "/se-shpejti/"),
        SelectFilterOption("Aksion", "/aksion/"),
        SelectFilterOption("Animuar", "/animuar/"),
        SelectFilterOption("Aventurë", "/aventure/"),
        SelectFilterOption("Aziatik", "/aziatik/"),
        SelectFilterOption("Biografi", "/biografi/"),
        SelectFilterOption("Nordik", "/nordik/"),
        SelectFilterOption("Dokumentar", "/dokumentar/"),
        SelectFilterOption("Dramë", "/drame/"),
        SelectFilterOption("Erotik +18", "/erotik/"),
        SelectFilterOption("Familjar", "/familjar/"),
        SelectFilterOption("Fantashkencë", "/fantashkence/"),
        SelectFilterOption("Fantazi", "/fantazi/"),
        SelectFilterOption("Francez", "/francez/"),
        SelectFilterOption("Gjerman", "/gjerman/"),
        SelectFilterOption("Hindi", "/hindi/"),
        SelectFilterOption("Histori", "/histori/"),
        SelectFilterOption("Horror", "/horror/"),
        SelectFilterOption("Italian", "/italian/"),
        SelectFilterOption("Komedi", "/komedi/"),
        SelectFilterOption("Krim", "/krim/"),
        SelectFilterOption("Luftë", "/lufte/"),
        SelectFilterOption("Mister", "/mister/"),
        SelectFilterOption("Muzikë", "/muzik/"),
        SelectFilterOption("NETFLIX", "/netflix/"),
        SelectFilterOption("Romancë", "/romance/"),
        SelectFilterOption("Rus", "/rus/"),
        SelectFilterOption("Shqiptar", "/shqiptar/"),
        SelectFilterOption("Spanjoll", "/spanjoll/"),
        SelectFilterOption("Sport", "/sport/"),
        SelectFilterOption("Thriller", "/thriller/"),
        SelectFilterOption("Turk", "/turk/"),
        SelectFilterOption("Western", "/western/"),
      ]),
    ];
  }

  Future<List<MVideo>> vidmolyExtractor(String url) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
    final headers = {'Referer': 'https://vidmoly.to'};
    List<MVideo> videos = [];
    final playListUrlResponse = (await client.get(Uri.parse(url))).body;
    final playlistUrl =
        RegExp(r'file:"(\S+?)"').firstMatch(playListUrlResponse)?.group(1) ??
        "";
    if (playlistUrl.isEmpty) return [];
    final masterPlaylistRes = await client.get(
      Uri.parse(playlistUrl),
      headers: headers,
    );

    if (masterPlaylistRes.statusCode == 200) {
      for (var it in substringAfter(
        masterPlaylistRes.body,
        "#EXT-X-STREAM-INF:",
      ).split("#EXT-X-STREAM-INF:")) {
        final quality =
            "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

        String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

        MVideo video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = "Vidmoly $quality"
          ..headers = headers;
        videos.add(video);
      }
    }

    return videos;
  }

  Future<List<MVideo>> oneuploadExtractor(String url) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
    List<MVideo> videos = [];
    final playListUrlResponse = (await client.get(Uri.parse(url))).body;
    final playlistUrl =
        RegExp(r'file:"(\S+?)"').firstMatch(playListUrlResponse)?.group(1) ??
        "";
    if (playlistUrl.isEmpty) return [];
    final masterPlaylistRes = (await client.get(Uri.parse(playlistUrl))).body;
    for (var it in substringAfter(
      masterPlaylistRes,
      "#EXT-X-STREAM-INF:",
    ).split("#EXT-X-STREAM-INF:")) {
      final quality =
          "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

      String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

      MVideo video = MVideo();
      video
        ..url = videoUrl
        ..originalUrl = videoUrl
        ..quality = "OneUploader $quality";
      videos.add(video);
    }
    return videos;
  }

  Future<List<MVideo>> uqloadExtractor(String url) async {
    final client = Client(source, json.encode({"useDartHttpClient": true}));
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
      ..quality = "Uqload"
      ..headers = {"Referer": "${Uri.parse(url).origin}/"};
    return [video];
  }

  MPages animeFromRes(String res) {
    final document = parseHtml(res);
    final result = document.selectFirst("div.row");
    final elements = result?.select("div.movie-thumb") ?? [];
    List<MManga> mangaList = [];

    for (var i = 0; i < elements.length; i++) {
      MManga manga = MManga();
      manga.name = elements[i].selectFirst("div > a > h4").text;
      manga.imageUrl = elements[i].selectFirst("a").getSrc;
      manga.link = elements[i].selectFirst("a").getHref;
      mangaList.add(manga);
    }

    return MPages(
      mangaList,
      document.selectFirst("div > a.nextpostslink")?.attr("href") != null,
    );
  }
}

Filma24 main(MSource source) {
  return Filma24(source: source);
}

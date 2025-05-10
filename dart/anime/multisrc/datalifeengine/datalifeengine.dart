import 'dart:convert';
import 'package:mangayomi/bridge_lib.dart';

class DataLifeEngine extends MProvider {
  DataLifeEngine({required this.source});

  MSource source;

  final Client client = Client();

  @override
  bool get supportsLatest => false;

  @override
  String get baseUrl => getPreferenceValue(source.id, "overrideBaseUrl");

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(
          Uri.parse("$baseUrl${getPath(source)}page/$page"),
        )).body;
    return animeFromElement(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    return MPages([], false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String res = "";
    if (query.isNotEmpty) {
      if (query.length < 4)
        throw "La recherche est suspendue! La chaîne de recherche est vide ou contient moins de 4 caractères.";
      final headers = {
        "Host": Uri.parse(baseUrl).host,
        "Origin": baseUrl,
        "Referer": "$baseUrl/",
      };
      final cleanQuery = query.replaceAll(" ", "+");
      if (page == 1) {
        res =
            (await client.post(
              Uri.parse(
                "$baseUrl?do=search&subaction=search&story=$cleanQuery",
              ),
              headers: headers,
            )).body;
      } else {
        res =
            (await client.post(
              Uri.parse(
                "$baseUrl?do=search&subaction=search&search_start=$page&full_search=0&result_from=11&story=$cleanQuery",
              ),
              headers: headers,
            )).body;
      }
    } else {
      String url = "";
      for (var filter in filters) {
        if (filter.type == "CategoriesFilter") {
          if (filter.state != 0) {
            url = "$baseUrl${filter.values[filter.state].value}page/$page/";
          }
        } else if (filter.type == "GenresFilter") {
          if (filter.state != 0) {
            url = "$baseUrl${filter.values[filter.state].value}page/$page/";
          }
        }
      }
      res = (await client.get(Uri.parse(url))).body;
    }

    return animeFromElement(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    String res =
        (await client.get(
          Uri.parse("$baseUrl${getUrlWithoutDomain(url)}"),
        )).body;
    MManga anime = MManga();
    final description = xpath(res, '//span[@itemprop="description"]/text()');
    anime.description = description.isNotEmpty ? description.first : "";
    anime.genre = xpath(res, '//span[@itemprop="genre"]/a/text()');

    List<MChapter>? episodesList = [];

    if (source.name == "French Anime") {
      final epsData = xpath(res, '//div[@class="eps"]/text()');
      for (var epData in epsData.first.split('\n')) {
        final data = epData.split('!');
        MChapter ep = MChapter();
        ep.name = "Episode ${data.first}";
        ep.url = data.last;
        episodesList.add(ep);
      }
    } else {
      final doc = parseHtml(res);
      final elements =
          doc
              .select(".hostsblock div:has(a)")
              .where(
                (MElement e) => e.outerHtml.contains("loadVideo('https://"),
              )
              .toList();
      if (elements.isNotEmpty) {
        for (var element in elements) {
          element = element as MElement;
          MChapter ep = MChapter();
          ep.name = element.className
              .replaceAll("ep", "Episode ")
              .replaceAll("vs", " VOSTFR")
              .replaceAll("vf", " VF");
          ep.url = element
              .select("a")
              .map(
                (MElement e) => substringBefore(
                  substringAfter(e.attr('onclick'), "loadVideo('"),
                  "')",
                ),
              )
              .toList()
              .join(",")
              .replaceAll("/vd.php?u=", "");
          ep.scanlator = element.className.contains('vf') ? 'VF' : 'VOSTFR';
          episodesList.add(ep);
        }
      } else {
        MChapter ep = MChapter();
        ep.name = "Film";
        ep.url = doc
            .select("a")
            .where((MElement e) => e.outerHtml.contains("loadVideo('https://"))
            .map(
              (MElement e) => substringBefore(
                substringAfter(e.attr('onclick'), "loadVideo('"),
                "')",
              ),
            )
            .toList()
            .join(",")
            .replaceAll("/vd.php?u=", "");
        episodesList.add(ep);
      }
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    List<MVideo> videos = [];
    final sUrls = url.split(',');
    for (var sUrl in sUrls) {
      List<MVideo> a = [];
      if (sUrl.contains("dood") || sUrl.contains("d000")) {
        a = await doodExtractor(sUrl, "DoodStream");
      } else if ([
        "streamhide",
        "guccihide",
        "streamvid",
        "dhtpre",
      ].any((a) => sUrl.contains(a))) {
        a = await streamHideExtractor(sUrl);
      } else if (sUrl.contains("uqload")) {
        a = await uqloadExtractor(sUrl);
      } else if (sUrl.contains("upstream")) {
        a = await upstreamExtractor(sUrl);
      } else if (sUrl.contains("sibnet")) {
        a = await sibnetExtractor(sUrl);
      } else if (sUrl.contains("ok.ru")) {
        a = await okruExtractor(sUrl);
      } else if (sUrl.contains("vidmoly")) {
        a = await vidmolyExtractor(sUrl);
      } else if (sUrl.contains("streamtape")) {
        a = await streamTapeExtractor(sUrl, "");
      } else if (sUrl.contains("voe.sx")) {
        a = await voeExtractor(sUrl, "");
      }
      videos.addAll(a);
    }
    return videos;
  }

  MPages animeFromElement(String res) {
    final htmls = parseHtml(res).select("div#dle-content > div.mov");
    List<MManga> animeList = [];
    for (var h in htmls) {
      final html = h.innerHtml;
      final url = xpath(html, '//a/@href').first;
      final name = xpath(html, '//a/text()').first;
      final image = xpath(html, '//div[contains(@class,"mov")]/img/@src').first;
      final season = xpath(html, '//div/span[@class="block-sai"]/text()');
      MManga anime = MManga();
      anime.name =
          "$name ${season.isNotEmpty ? season.first.replaceAll("\n", " ") : ""}";
      anime.imageUrl = "$baseUrl$image";
      anime.link = url;
      animeList.add(anime);
    }
    final hasNextPage = xpath(res, '//span[@class="pnext"]/a/@href').isNotEmpty;
    return MPages(animeList, hasNextPage);
  }

  Future<List<MVideo>> streamHideExtractor(String url) async {
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
        ..quality = "StreamHideVid - $quality";
      videos.add(video);
    }
    return videos;
  }

  Future<List<MVideo>> upstreamExtractor(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    final js = xpath(res, '//script[contains(text(), "m3u8")]/text()');
    if (js.isEmpty) {
      return [];
    }
    final masterUrl = substringBefore(
      substringAfter(unpackJs(js.first), "{file:\""),
      "\"}",
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
        ..quality = "Upstream - $quality";
      videos.add(video);
    }
    return videos;
  }

  Future<List<MVideo>> uqloadExtractor(String url) async {
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

  Future<List<MVideo>> vidmolyExtractor(String url) async {
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

  String getPath() {
    if (source.name == "French Anime") return "/animes-vostfr/";
    return "/serie-en-streaming/";
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      if (source.name == "Wiflix")
        EditTextPreference(
          key: "overrideBaseUrl",
          title: "Changer l'url de base",
          summary: "",
          value: "https://wiflix-hd.vip",
          dialogTitle: "Changer l'url de base",
          dialogMessage: "",
          text: "https://wiflix-hd.vip",
        ),
      if (source.name == "French Anime")
        EditTextPreference(
          key: "overrideBaseUrl",
          title: "Changer l'url de base",
          summary: "",
          value: "https://french-anime.com",
          dialogTitle: "Changer l'url de base",
          dialogMessage: "",
          text: "https://french-anime.com",
        ),
    ];
  }

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("La recherche de texte ignore les filtres"),
      if (source.name == "French Anime")
        SelectFilter("CategoriesFilter", "Catégories", 0, [
          SelectFilterOption("<Sélectionner>", ""),
          SelectFilterOption("Action", "/genre/action/"),
          SelectFilterOption("Aventure", "/genre/aventure/"),
          SelectFilterOption("Arts martiaux", "/genre/arts-martiaux/"),
          SelectFilterOption("Combat", "/genre/combat/"),
          SelectFilterOption("Comédie", "/genre/comedie/"),
          SelectFilterOption("Drame", "/genre/drame/"),
          SelectFilterOption("Epouvante", "/genre/epouvante/"),
          SelectFilterOption("Fantastique", "/genre/fantastique/"),
          SelectFilterOption("Fantasy", "/genre/fantasy/"),
          SelectFilterOption("Mystère", "/genre/mystere/"),
          SelectFilterOption("Romance", "/genre/romance/"),
          SelectFilterOption("Shonen", "/genre/shonen/"),
          SelectFilterOption("Surnaturel", "/genre/surnaturel/"),
          SelectFilterOption("Sci-Fi", "/genre/sci-fi/"),
          SelectFilterOption("School life", "/genre/school-life/"),
          SelectFilterOption("Ninja", "/genre/ninja/"),
          SelectFilterOption("Seinen", "/genre/seinen/"),
          SelectFilterOption("Horreur", "/genre/horreur/"),
          SelectFilterOption("Tranche de vie", "/genre/tranchedevie/"),
          SelectFilterOption("Psychologique", "/genre/psychologique/"),
        ]),
      if (source.name == "French Anime")
        SelectFilter("GenresFilter", "Genres", 0, [
          SelectFilterOption("<Sélectionner>", ""),
          SelectFilterOption("Animes VF", "/animes-vf/"),
          SelectFilterOption("Animes VOSTFR", "/animes-vostfr/"),
          SelectFilterOption("Films VF et VOSTFR", "/films-vf-vostfr/"),
        ]),
      if (source.name == "Wiflix")
        SelectFilter("CategoriesFilter", "Catégories", 0, [
          SelectFilterOption("<Sélectionner>", ""),
          SelectFilterOption("Séries", "/serie-en-streaming/"),
          SelectFilterOption("Films", "/film-en-streaming/"),
        ]),
      if (source.name == "Wiflix")
        SelectFilter("GenresFilter", "Genres", 0, [
          SelectFilterOption("<Sélectionner>", ""),
          SelectFilterOption("Action", "/film-en-streaming/action/"),
          SelectFilterOption("Animation", "/film-en-streaming/animation/"),
          SelectFilterOption(
            "Arts Martiaux",
            "/film-en-streaming/arts-martiaux/",
          ),
          SelectFilterOption("Aventure", "/film-en-streaming/aventure/"),
          SelectFilterOption("Biopic", "/film-en-streaming/biopic/"),
          SelectFilterOption("Comédie", "/film-en-streaming/comedie/"),
          SelectFilterOption(
            "Comédie Dramatique",
            "/film-en-streaming/comedie-dramatique/",
          ),
          SelectFilterOption(
            "Épouvante Horreur",
            "/film-en-streaming/horreur/",
          ),
          SelectFilterOption("Drame", "/film-en-streaming/drame/"),
          SelectFilterOption(
            "Documentaire",
            "/film-en-streaming/documentaire/",
          ),
          SelectFilterOption("Espionnage", "/film-en-streaming/espionnage/"),
          SelectFilterOption("Famille", "/film-en-streaming/famille/"),
          SelectFilterOption("Fantastique", "/film-en-streaming/fantastique/"),
          SelectFilterOption("Guerre", "/film-en-streaming/guerre/"),
          SelectFilterOption("Historique", "/film-en-streaming/historique/"),
          SelectFilterOption("Musical", "/film-en-streaming/musical/"),
          SelectFilterOption("Policier", "/film-en-streaming/policier/"),
          SelectFilterOption("Romance", "/film-en-streaming/romance/"),
          SelectFilterOption(
            "Science-Fiction",
            "/film-en-streaming/science-fiction/",
          ),
          SelectFilterOption("Spectacles", "/film-en-streaming/spectacles/"),
          SelectFilterOption("Thriller", "/film-en-streaming/thriller/"),
          SelectFilterOption("Western", "/film-en-streaming/western/"),
        ]),
    ];
  }
}

DataLifeEngine main(MSource source) {
  return DataLifeEngine(source: source);
}

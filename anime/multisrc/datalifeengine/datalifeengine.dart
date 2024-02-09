import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class DataLifeEngine extends MProvider {
  DataLifeEngine({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  bool get supportsLatest => false;

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}${getPath(source)}page/$page")))
        .body;
    return animeFromElement(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    return MPages([], false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    final baseUrl = source.baseUrl;
    String res = "";
    if (query.isNotEmpty) {
      if (query.length < 4) return MPages([], false);
      final headers = {
        "Host": Uri.parse(baseUrl).host,
        "Origin": baseUrl,
        "Referer": "$baseUrl/"
      };
      final cleanQuery = query.replaceAll(" ", "+");
      if (page == 1) {
        res = (await client.post(
                Uri.parse(
                    "$baseUrl?do=search&subaction=search&story=$cleanQuery"),
                headers: headers))
            .body;
      } else {
        res = (await client.post(
                Uri.parse(
                    "$baseUrl?do=search&subaction=search&search_start=$page&full_search=0&result_from=11&story=$cleanQuery"),
                headers: headers))
            .body;
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
    String res = (await client.get(Uri.parse(url))).body;
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
      final eps = xpath(res,
          '//*[@class="hostsblock"]/div/a[contains(@href,"https")]/parent::div/@class');
      if (eps.isNotEmpty) {
        for (var i = 0; i < eps.length; i++) {
          final epUrls = xpath(res,
              '//*[@class="hostsblock"]/div[@class="${eps[i]}"]/a[contains(@href,"https")]/@href');
          MChapter ep = MChapter();
          ep.name = "Episode ${i + 1}";
          ep.url = epUrls.join(",").replaceAll("/vd.php?u=", "");
          ep.scanlator = eps[i].contains('vf') ? 'VF' : 'VOSTFR';
          episodesList.add(ep);
        }
      } else {
        anime.status = MStatus.completed;
        final epUrls = xpath(res,
            '//*[contains(@class,"filmlinks")]/div/a[contains(@href,"https")]/@href');
        MChapter ep = MChapter();
        ep.name = "Film";
        ep.url = epUrls.join(",").replaceAll("/vd.php?u=", "");
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
      if (sUrl.contains("dood")) {
        a = await doodExtractor(sUrl, "DoodStream");
      } else if (sUrl.contains("voe.sx")) {
        a = await voeExtractor(sUrl, "Voe");
      } else if (sUrl.contains("streamvid") ||
          sUrl.contains("guccihide") ||
          sUrl.contains("streamhide")) {
        a = await streamHideExtractor(sUrl);
      } else if (sUrl.contains("uqload")) {
        a = await uqloadExtractor(sUrl);
      } else if (sUrl.contains("upstream")) {
        a = await upstreamExtractor(sUrl);
      } else if (sUrl.contains("sibnet")) {
        a = await sibnetExtractor(sUrl);
      } else if (sUrl.contains("ok.ru")) {
        a = await okruExtractor(sUrl);
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
      anime.imageUrl = "${source.baseUrl}$image";
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
            substringAfter(
                substringAfter(unpackJs(res), "sources:"), "file:\""),
            "src:\""),
        '"');
    final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;
    List<MVideo> videos = [];
    for (var it in substringAfter(masterPlaylistRes, "#EXT-X-STREAM-INF:")
        .split("#EXT-X-STREAM-INF:")) {
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
    final masterUrl =
        substringBefore(substringAfter(unpackJs(js.first), "{file:\""), "\"}");
    final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;
    List<MVideo> videos = [];
    for (var it in substringAfter(masterPlaylistRes, "#EXT-X-STREAM-INF:")
        .split("#EXT-X-STREAM-INF:")) {
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

    final videoUrl =
        substringBefore(substringAfter(js.first, "sources: [\""), '"');
    MVideo video = MVideo();
    video
      ..url = videoUrl
      ..originalUrl = videoUrl
      ..quality = "Uqload"
      ..headers = {"Referer": "${Uri.parse(url).origin}/"};
    return [video];
  }

  String getPath() {
    if (source.name == "French Anime") return "/animes-vostfr/";
    return "/serie-en-streaming/";
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
          SelectFilterOption("Psychologique", "/genre/psychologique/")
        ]),
      if (source.name == "French Anime")
        SelectFilter("GenresFilter", "Genres", 0, [
          SelectFilterOption("<Sélectionner>", ""),
          SelectFilterOption("Animes VF", "/animes-vf/"),
          SelectFilterOption("Animes VOSTFR", "/animes-vostfr/"),
          SelectFilterOption("Films VF et VOSTFR", "/films-vf-vostfr/")
        ]),
      if (source.name == "Wiflix")
        SelectFilter("CategoriesFilter", "Catégories", 0, [
          SelectFilterOption("<Sélectionner>", ""),
          SelectFilterOption("Séries", "/serie-en-streaming/"),
          SelectFilterOption("Films", "/film-en-streaming/")
        ]),
      if (source.name == "Wiflix")
        SelectFilter("GenresFilter", "Genres", 0, [
          SelectFilterOption("<Sélectionner>", ""),
          SelectFilterOption("Action", "/film-en-streaming/action/"),
          SelectFilterOption("Animation", "/film-en-streaming/animation/"),
          SelectFilterOption(
              "Arts Martiaux", "/film-en-streaming/arts-martiaux/"),
          SelectFilterOption("Aventure", "/film-en-streaming/aventure/"),
          SelectFilterOption("Biopic", "/film-en-streaming/biopic/"),
          SelectFilterOption("Comédie", "/film-en-streaming/comedie/"),
          SelectFilterOption(
              "Comédie Dramatique", "/film-en-streaming/comedie-dramatique/"),
          SelectFilterOption(
              "Épouvante Horreur", "/film-en-streaming/horreur/"),
          SelectFilterOption("Drame", "/film-en-streaming/drame/"),
          SelectFilterOption(
              "Documentaire", "/film-en-streaming/documentaire/"),
          SelectFilterOption("Espionnage", "/film-en-streaming/espionnage/"),
          SelectFilterOption("Famille", "/film-en-streaming/famille/"),
          SelectFilterOption("Fantastique", "/film-en-streaming/fantastique/"),
          SelectFilterOption("Guerre", "/film-en-streaming/guerre/"),
          SelectFilterOption("Historique", "/film-en-streaming/historique/"),
          SelectFilterOption("Musical", "/film-en-streaming/musical/"),
          SelectFilterOption("Policier", "/film-en-streaming/policier/"),
          SelectFilterOption("Romance", "/film-en-streaming/romance/"),
          SelectFilterOption(
              "Science-Fiction", "/film-en-streaming/science-fiction/"),
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

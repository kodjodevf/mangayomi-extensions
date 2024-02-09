import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class OtakuFr extends MProvider {
  OtakuFr({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(Uri.parse("${source.baseUrl}/en-cours/page/$page")))
            .body;
    List<MManga> animeList = [];
    final urls =
        xpath(res, '//*[@class="list"]/article/div/div/figure/a/@href');
    final names =
        xpath(res, '//*[@class="list"]/article/div/div/figure/a/img/@title');
    final images =
        xpath(res, '//*[@class="list"]/article/div/div/figure/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@class="next page-link"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(Uri.parse("${source.baseUrl}/page/$page/"))).body;

    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="episode"]/div/a/@href');
    final namess = xpath(res, '//*[@class="episode"]/div/a/text()');
    List<String> names = [];
    for (var name in namess) {
      names.add(regExp(
              name,
              r'(?<=\bS\d\s*|)\d{2}\s*(?=\b(Vostfr|vostfr|VF|Vf|vf|\(VF\)|\(vf\)|\(Vf\)|\(Vostfr\)\b))?',
              '',
              0,
              0)
          .replaceAll(' vostfr', '')
          .replaceAll(' Vostfr', '')
          .replaceAll(' VF', '')
          .replaceAll(' Vf', '')
          .replaceAll(' vf', '')
          .replaceAll(' (VF)', '')
          .replaceAll(' (vf)', '')
          .replaceAll(' (vf)', '')
          .replaceAll(' (Vf)', '')
          .replaceAll(' (Vostfr)', ''));
    }
    final images = xpath(res, '//*[@class="episode"]/div/figure/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@class="next page-link"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    if (query.isNotEmpty) {
      url = "${source.baseUrl}/toute-la-liste-affiches/page/$page/?q=$query";
    } else {
      for (var filter in filters) {
        if (filter.type == "GenreFilter") {
          if (filter.state != 0) {
            url =
                "${source.baseUrl}/${filter.values[filter.state].value}page/$page";
          }
        } else if (filter.type == "SubPageFilter") {
          if (url.isEmpty) {
            if (filter.state != 0) {
              url =
                  "${source.baseUrl}/${filter.values[filter.state].value}page/$page";
            }
          }
        }
      }
    }

    final res = (await client.get(Uri.parse(url))).body;

    List<MManga> animeList = [];
    final urls =
        xpath(res, '//*[@class="list"]/article/div/div/figure/a/@href');
    final names =
        xpath(res, '//*[@class="list"]/article/div/div/figure/a/img/@title');
    final images =
        xpath(res, '//*[@class="list"]/article/div/div/figure/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@class="next page-link"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"En cours": 0, "Terminé": 1}
    ];
    String res = (await client.get(Uri.parse(url))).body;
    MManga anime = MManga();
    final originalUrl = xpath(res,
        '//*[@class="breadcrumb"]/li[@class="breadcrumb-item"][2]/a/@href');
    if (originalUrl.isNotEmpty) {
      res = (await client.get(Uri.parse(originalUrl.first))).body;
    }
    final description =
        xpath(res, '//*[@class="episode fz-sm synop"]/p/text()');
    if (description.isNotEmpty) {
      anime.description = description.first.replaceAll("Synopsis:", "");
    }
    final status = xpath(res,
        '//*[@class="list-unstyled"]/li[contains(text(),"Statut")]/text()');
    if (status.isNotEmpty) {
      anime.status =
          parseStatus(status.first.replaceAll("Statut: ", ""), statusList);
    }

    anime.genre = xpath(res,
        '//*[@class="list-unstyled"]/li[contains(text(),"Genre")]/ul/li/a/text()');

    final epUrls = xpath(res, '//*[@class="list-episodes list-group"]/a/@href');
    final dates =
        xpath(res, '//*[@class="list-episodes list-group"]/a/span/text()');
    final names = xpath(res, '//*[@class="list-episodes list-group"]/a/text()');
    List<String> episodes = [];

    for (var i = 0; i < names.length; i++) {
      final date = dates[i];
      final name = names[i];
      episodes.add(
          "Episode ${regExp(name.replaceAll(date, ""), r".* (\d*) [VvfF]{1,1}", '', 1, 1)}");
    }
    final dateUploads = parseDates(dates, "dd MMMM yyyy", "fr");

    List<MChapter>? episodesList = [];
    for (var i = 0; i < episodes.length; i++) {
      MChapter episode = MChapter();
      episode.name = episodes[i];
      episode.url = epUrls[i];
      episode.dateUpload = dateUploads[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse(url))).body;

    final servers = xpath(res, '//*[@id="nav-tabContent"]/div/iframe/@src');
    List<MVideo> videos = [];
    final hosterSelection = preferenceHosterSelection(source.id);
    for (var url in servers) {
      final resServer = (await client.get(Uri.parse(fixUrl(url)),
              headers: {"X-Requested-With": "XMLHttpRequest"}))
          .body;
      final serverUrl =
          fixUrl(regExp(resServer, r"data-url='([^']+)'", '', 1, 1));
      List<MVideo> a = [];
      if (serverUrl.contains("https://streamwish") &&
          hosterSelection.contains("Streamwish")) {
        a = await streamWishExtractor(serverUrl, "StreamWish");
      } else if (serverUrl.contains("sibnet") &&
          hosterSelection.contains("Sibnet")) {
        a = await sibnetExtractor(serverUrl);
      } else if (serverUrl.contains("https://doo") &&
          hosterSelection.contains("Doodstream")) {
        a = await doodExtractor(serverUrl);
      } else if (serverUrl.contains("https://voe.sx") &&
          hosterSelection.contains("Voe")) {
        a = await voeExtractor(serverUrl, null);
      } else if (serverUrl.contains("https://ok.ru") &&
          hosterSelection.contains("Okru")) {
        a = await okruExtractor(serverUrl);
      } else if (serverUrl.contains("vadbam") &&
          hosterSelection.contains("Vidbm")) {
        a = await vidbmExtractor(serverUrl);
      } else if (serverUrl.contains("upstream") &&
          hosterSelection.contains("Upstream")) {
        a = await upstreamExtractor(serverUrl);
      } else if (serverUrl.contains("sendvid") &&
          hosterSelection.contains("Sendvid")) {
        a = await sendVidExtractor(serverUrl, null, "");
      }
      videos.addAll(a);
    }

    return videos;
  }

  String fixUrl(String url) {
    return regExp(url, r"^(?:(?:https?:)?//|www\.)", 'https://', 0, 0);
  }

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("La recherche de texte ignore les filtres"),
      SelectFilter("GenreFilter", "Genre", 0, [
        SelectFilterOption("<Selectionner>", ""),
        SelectFilterOption("Action", "/genre/action/"),
        SelectFilterOption("Aventure", "/genre/aventure/"),
        SelectFilterOption("Comedie", "/genre/comedie/"),
        SelectFilterOption("Crime", "/genre/crime/"),
        SelectFilterOption("Démons", "/genre/demons/"),
        SelectFilterOption("Drame", "/genre/drame/"),
        SelectFilterOption("Ecchi", "/genre/ecchi/"),
        SelectFilterOption("Espace", "/genre/espace/"),
        SelectFilterOption("Fantastique", "/genre/fantastique/"),
        SelectFilterOption("Gore", "/genre/gore/"),
        SelectFilterOption("Harem", "/genre/harem/"),
        SelectFilterOption("Historique", "/genre/historique/"),
        SelectFilterOption("Horreur", "/genre/horreur/"),
        SelectFilterOption("Isekai", "/genre/isekai/"),
        SelectFilterOption("Jeux", "/genre/jeu/"),
        SelectFilterOption("L'école", "/genre/lecole/"),
        SelectFilterOption("Magical girls", "/genre/magical-girls/"),
        SelectFilterOption("Magie", "/genre/magie/"),
        SelectFilterOption("Martial Arts", "/genre/martial-arts/"),
        SelectFilterOption("Mecha", "/genre/mecha/"),
        SelectFilterOption("Militaire", "/genre/militaire/"),
        SelectFilterOption("Musique", "/genre/musique/"),
        SelectFilterOption("Mysterieux", "/genre/mysterieux/"),
        SelectFilterOption("Parodie", "/genre/Parodie/"),
        SelectFilterOption("Police", "/genre/police/"),
        SelectFilterOption("Psychologique", "/genre/psychologique/"),
        SelectFilterOption("Romance", "/genre/romance/"),
        SelectFilterOption("Samurai", "/genre/samurai/"),
        SelectFilterOption("Sci-Fi", "/genre/sci-fi/"),
        SelectFilterOption("Seinen", "/genre/seinen/"),
        SelectFilterOption("Shoujo", "/genre/shoujo/"),
        SelectFilterOption("Shoujo Ai", "/genre/shoujo-ai/"),
        SelectFilterOption("Shounen", "/genre/shounen/"),
        SelectFilterOption("Shounen Ai", "/genre/shounen-ai/"),
        SelectFilterOption("Sport", "/genre/sport/"),
        SelectFilterOption("Super Power", "/genre/super-power/"),
        SelectFilterOption("Surnaturel", "/genre/surnaturel/"),
        SelectFilterOption("Suspense", "/genre/suspense/"),
        SelectFilterOption("Thriller", "/genre/thriller/"),
        SelectFilterOption("Tranche de vie", "/genre/tranche-de-vie/"),
        SelectFilterOption("Vampire", "/genre/vampire/")
      ]),
      SelectFilter("SubPageFilter", "Sous page", 0, [
        SelectFilterOption("<Selectionner>", ""),
        SelectFilterOption("Terminé", "/termine/"),
        SelectFilterOption("Film", "/film/"),
      ])
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_quality",
          title: "Qualité préférée",
          summary: "",
          valueIndex: 1,
          entries: ["1080p", "720p", "480p", "360p"],
          entryValues: ["1080", "720", "480", "360"]),
      MultiSelectListPreference(
          key: "hoster_selection",
          title: "Enable/Disable Hosts",
          summary: "",
          entries: [
            "Streamwish",
            "Doodstream",
            "Sendvid",
            "Vidbm",
            "Okru",
            "Voe",
            "Sibnet",
            "Upstream"
          ],
          entryValues: [
            "Streamwish",
            "Doodstream",
            "Sendvid",
            "Vidbm",
            "Okru",
            "Voe",
            "Sibnet",
            "Upstream"
          ],
          values: [
            "Streamwish",
            "Doodstream",
            "Sendvid",
            "Vidbm",
            "Okru",
            "Voe",
            "Sibnet",
            "Upstream"
          ]),
    ];
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

  List<String> preferenceHosterSelection(int sourceId) {
    return getPreferenceValue(sourceId, "hoster_selection");
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

  Future<List<MVideo>> vidbmExtractor(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    final js = xpath(res,
        '//script[contains(text(), "m3u8") or contains(text(), "mp4")]/text()');
    if (js.isEmpty) {
      return [];
    }
    final masterUrl = substringBefore(substringAfter(js.first, "source"), "\"");
    final quality = substringBefore(
        substringAfter(
            substringBefore(
                substringAfter(substringAfter(js.first, "source"), "file"),
                "]"),
            "label:\""),
        "\"");
    List<MVideo> videos = [];
    if (masterUrl.contains("m3u8")) {
      final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;

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
          ..quality = "Vidbm - $quality";
        videos.add(video);
      }
      return videos;
    } else {
      MVideo video = MVideo();
      video
        ..url = masterUrl
        ..originalUrl = masterUrl
        ..quality = "Vidbm - $quality";
      videos.add(video);
    }
    return videos;
  }
}

OtakuFr main(MSource source) {
  return OtakuFr(source: source);
}

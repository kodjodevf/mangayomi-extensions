import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class FrAnime extends MProvider {
  FrAnime({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res = await dataBase();

    return animeResList(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = await dataBase();

    List list = json.decode(res);
    return animeResList(json.encode(list.reversed.toList()));
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res = await dataBase();

    return animeSeachFetch(res, query);
  }

  @override
  Future<MManga> getDetail(String url) async {
    MManga anime = MManga();
    String language = "vo".toString();
    if (url.contains("lang=")) {
      language = substringBefore(substringAfter(url, "lang="), "&");
    }
    String stem = substringBefore(substringAfterLast(url, "/"), "?");
    final res = await dataBase();

    final animeByTitleOJson = databaseAnimeByTitleO(res, stem);
    final seasons = json.decode(animeByTitleOJson)["saisons"];

    var seasonsJson = seasons.first;

    if (url.contains("s=")) {
      int seasonNumber = int.parse(
        substringBefore(substringAfter(url, "s="), "&"),
      );
      seasonsJson = seasons[seasonNumber - 1];
    }

    List<MChapter>? episodesList = [];

    final episodes = seasonsJson["episodes"];

    for (int i = 0; i < episodes.length; i++) {
      final ep = episodes[i];

      final lang = ep["lang"];

      final vo = lang["vo"];
      final vf = lang["vf"];
      bool hasVostfr = vo["lecteurs"].isNotEmpty;
      bool hasVf = vf["lecteurs"].isNotEmpty;
      bool playerIsNotEmpty = false;

      if (language == "vo" && hasVostfr) {
        playerIsNotEmpty = true;
      } else if (language == "vf" && hasVf) {
        playerIsNotEmpty = true;
      }
      if (playerIsNotEmpty) {
        MChapter episode = MChapter();
        episode.url = "$url&ep=${i + 1}";
        String title = ep["title"];
        episode.name = title.replaceAll('"', "");
        episodesList.add(episode);
      }
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    String language = "vo";
    String videoBaseUrl = "https://api.franime.fr/api/anime";
    if (url.contains("lang=")) {
      language = substringBefore(substringAfter(url, "lang="), "&");
    }
    String stem = substringBefore(substringAfterLast(url, "/"), "?");
    final res = await dataBase();

    final animeByTitleOJson = databaseAnimeByTitleO(res, stem);
    final animeId = json.decode(animeByTitleOJson)["id"];
    final seasons = json.decode(animeByTitleOJson)["saisons"];

    var seasonsJson = seasons.first;

    videoBaseUrl += "/$animeId/";

    if (url.contains("s=")) {
      int seasonNumber = int.parse(
        substringBefore(substringAfter(url, "s="), "&"),
      );
      videoBaseUrl += "${seasonNumber - 1}/";
      seasonsJson = seasons[seasonNumber - 1];
    } else {
      videoBaseUrl += "0/";
    }
    final episodesJson = seasonsJson["episodes"];
    var episode = episodesJson.first;
    if (url.contains("ep=")) {
      int episodeNumber = int.parse(substringAfter(url, "ep="));
      episode = episodesJson[episodeNumber - 1];
      videoBaseUrl += "${episodeNumber - 1}";
    } else {
      videoBaseUrl += "0";
    }
    final lang = episode["lang"];

    final vo = lang["vo"];
    final vf = lang["vf"];
    bool hasVostfr = vo["lecteurs"].isNotEmpty;
    bool hasVf = vf["lecteurs"].isNotEmpty;
    List<String> vostfrPlayers = vo["lecteurs"];
    List<String> vfPlayers = vf["lecteurs"];
    List<String> players = [];
    if (language == "vo" && hasVostfr) {
      players = vostfrPlayers;
    } else if (language == "vf" && hasVf) {
      players = vfPlayers;
    }

    List<MVideo> videos = [];
    for (var i = 0; i < players.length; i++) {
      String apiUrl = "$videoBaseUrl/$language/$i";
      String playerName = players[i];

      MVideo video = MVideo();

      final playerUrl =
          (await client.get(
            Uri.parse(apiUrl),
            headers: {"Referer": "https://franime.fr/"},
          )).body;

      List<MVideo> a = [];
      print(playerName);
      if (playerName.contains("vido")) {
        videos.add(
          video
            ..url = playerUrl
            ..originalUrl = playerUrl
            ..quality = "FRAnime (Vido)",
        );
      } else if (playerName.contains("sendvid")) {
        a = await sendVidExtractorr(playerUrl, "");
      } else if (playerName.contains("sibnet")) {
        a = await sibnetExtractor(playerUrl);
      }
      videos.addAll(a);
    }

    return videos;
  }

  MPages animeResList(String res) {
    final statusList = [
      {"EN COURS": 0, "TERMINÉ": 1},
    ];
    List<MManga> animeList = [];

    var jsonResList = json.decode(res);

    for (var animeJson in jsonResList) {
      final seasons = animeJson["saisons"];
      List<bool> vostfrListName = [];
      List<bool> vfListName = [];
      for (var season in seasons) {
        for (var episode in season["episodes"]) {
          final lang = episode["lang"];
          final vo = lang["vo"];
          final vf = lang["vf"];
          vostfrListName.add(vo["lecteurs"].isNotEmpty);
          vfListName.add(vf["lecteurs"].isNotEmpty);
        }
      }

      String titleO = animeJson["titleO"];
      final title = animeJson["title"];
      final genre = animeJson["themes"];
      final description = animeJson["description"];
      final status = parseStatus(animeJson["status"], statusList);
      final imageUrl = animeJson["affiche"];
      bool hasVostfr = vostfrListName.contains(true);
      bool hasVf = vfListName.contains(true);
      if (hasVostfr || hasVf) {
        for (int i = 0; i < seasons.length; i++) {
          MManga anime = MManga();
          int ind = i + 1;
          anime.genre = genre;
          anime.description = description;
          String seasonTitle = "".toString();
          String lang = "";
          if (title.isEmpty) {
            seasonTitle = titleO;
          } else {
            seasonTitle = title;
          }
          if (seasons.length > 1) {
            seasonTitle += " S$ind";
          }
          if (hasVf) {
            seasonTitle += " VF";
            lang = "vf".toString();
          }
          if (hasVostfr) {
            seasonTitle += " VOSTFR";
            lang = "vo".toString();
          }

          anime.status = status;
          anime.name = seasonTitle;
          anime.imageUrl = imageUrl;
          anime.link =
              "/anime/${titleO.replaceAll(RegExp("[^A-Za-z0-9 ]"), "").replaceAll(" ", "-").toLowerCase()}?lang=$lang&s=$ind";

          animeList.add(anime);
        }
      }
    }
    return MPages(animeList, true);
  }

  MPages animeSeachFetch(String res, String query) {
    final statusList = [
      {"EN COURS": 0, "TERMINÉ": 1},
    ];
    List<MManga> animeList = [];
    final jsonResList = json.decode(res);
    for (var animeJson in jsonResList) {
      MManga anime = MManga();

      final titleO = getMapValue(json.encode(animeJson), "titleO");
      final titleAlt = getMapValue(
        json.encode(animeJson),
        "titles",
        encode: true,
      );
      final containsEn = getMapValue(
        titleAlt,
        "en",
      ).toString().toLowerCase().contains(query.toLowerCase());
      final containsEnJp = getMapValue(
        titleAlt,
        "en_jp",
      ).toString().toLowerCase().contains(query.toLowerCase());
      final containsJaJp = getMapValue(
        titleAlt,
        "ja_jp",
      ).toString().toLowerCase().contains(query.toLowerCase());
      final containsTitleO = titleO.toLowerCase().contains(query.toLowerCase());

      if (containsEn || containsEnJp || containsJaJp || containsTitleO) {
        final seasons = animeJson["saisons"];
        List<bool> vostfrListName = [];
        List<bool> vfListName = [];
        for (var season in seasons) {
          for (var episode in season["episodes"]) {
            final lang = episode["lang"];
            final vo = lang["vo"];
            final vf = lang["vf"];
            vostfrListName.add(vo["lecteurs"].isNotEmpty);
            vfListName.add(vf["lecteurs"].isNotEmpty);
          }
        }
        String titleO = animeJson["titleO"];
        final title = animeJson["title"];
        final genre = animeJson["themes"];
        final description = animeJson["description"];
        final status = parseStatus(animeJson["status"], statusList);
        final imageUrl = animeJson["affiche"];

        bool hasVostfr = vostfrListName.contains(true);
        bool hasVf = vfListName.contains(true);
        if (hasVostfr || hasVf) {
          for (int i = 0; i < seasons.length; i++) {
            MManga anime = MManga();
            int ind = i + 1;
            anime.genre = genre;
            anime.description = description;
            String seasonTitle = "".toString();
            String lang = "";
            if (title.isEmpty) {
              seasonTitle = titleO;
            } else {
              seasonTitle = title;
            }
            if (seasons.length > 1) {
              seasonTitle += " S$ind";
            }
            if (hasVf) {
              seasonTitle += " VF";
              lang = "vf".toString();
            }
            if (hasVostfr) {
              seasonTitle += " VOSTFR";
              lang = "vo".toString();
            }

            anime.status = status;
            anime.name = seasonTitle;
            anime.imageUrl = imageUrl;
            anime.link =
                "/anime/${titleO.replaceAll(RegExp("[^A-Za-z0-9 ]"), "").replaceAll(" ", "-").toLowerCase()}?lang=$lang&s=$ind";

            animeList.add(anime);
          }
        }
      }
    }
    return MPages(animeList, true);
  }

  Future<String> dataBase() async {
    return (await client.get(
      Uri.parse("https://api.franime.fr/api/animes/"),
      headers: {"Referer": "https://franime.fr/"},
    )).body;
  }

  String databaseAnimeByTitleO(String res, String titleO) {
    final datas = json.decode(res) as List<Map<String, dynamic>>;
    for (var data in datas) {
      String title = (data["titleO"] as String).replaceAll(
        RegExp("[^A-Za-z0-9 ]"),
        "",
      );
      if (title.replaceAll(" ", "-").toLowerCase() == "${titleO}") {
        return json.encode(data);
      }
    }
    return "";
  }

  Future<List<MVideo>> sendVidExtractorr(String url, String prefix) async {
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    final masterUrl = document.selectFirst("source#video_source")?.attr("src");
    if (masterUrl == null) return [];
    final masterHeaders = {
      "Accept": "*/*",
      "Host": Uri.parse(masterUrl).host,
      "Origin": "https://${Uri.parse(url).host}",
      "Referer": "https://${Uri.parse(url).host}/",
    };
    List<MVideo> videos = [];
    if (masterUrl.contains(".m3u8")) {
      final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;

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
        final videoHeaders = {
          "Accept": "*/*",
          "Host": Uri.parse(videoUrl).host,
          "Origin": "https://${Uri.parse(url).host}",
          "Referer": "https://${Uri.parse(url).host}/",
        };
        var video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = prefix + "Sendvid:$quality"
          ..headers = videoHeaders;
        videos.add(video);
      }
    } else {
      var video = MVideo();
      video
        ..url = masterUrl
        ..originalUrl = masterUrl
        ..quality = prefix + "Sendvid:default"
        ..headers = masterHeaders;
      videos.add(video);
    }

    return videos;
  }
}

FrAnime main(MSource source) {
  return FrAnime(source: source);
}

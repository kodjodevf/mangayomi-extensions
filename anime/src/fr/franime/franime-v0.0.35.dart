import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class FrAnime extends MProvider {
  FrAnime();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {
      "url": "https://api.franime.fr/api/animes/",
      "headers": {"Referer": "https://franime.fr/"}
    };
    final res = await http('GET', json.encode(data));

    return animeResList(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final res = await dataBase();

    List list = json.decode(res);
    return animeResList(json.encode(list.reversed.toList()));
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    final res = await dataBase();

    return animeSeachFetch(res, query);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
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
      int seasonNumber =
          int.parse(substringBefore(substringAfter(url, "s="), "&"));
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
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    String language = "vo".toString();
    String videoBaseUrl = "https://api.franime.fr/api/anime".toString();
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
      int seasonNumber =
          int.parse(substringBefore(substringAfter(url, "s="), "&"));
      print(seasonNumber);
      videoBaseUrl += "${seasonNumber - 1}/";
      seasonsJson = seasons[seasonNumber - 1];
    } else {
      videoBaseUrl += "0/";
    }
    final episodesJson = seasonsJson["episodes"];
    var episode = episodesJson.first;
    if (url.contains("ep=")) {
      int episodeNumber = int.parse(substringAfter(url, "ep="));
      print(episodeNumber);
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

      final data = {
        "url": apiUrl,
        "headers": {"Referer": "https://franime.fr/"}
      };
      final playerUrl = await http('GET', json.encode(data));

      List<MVideo> a = [];
      if (playerName.contains("vido")) {
        videos.add(video
          ..url = playerUrl
          ..originalUrl = playerUrl
          ..quality = "FRAnime (Vido)");
      } else if (playerName.contains("myvi")) {
        a = await myTvExtractor(playerUrl);
      } else if (playerName.contains("sendvid")) {
        a = await sendVidExtractor(
            playerUrl, json.encode({"Referer": "https://franime.fr/"}), "");
      } else if (playerName.contains("sibnet")) {
        a = await sibnetExtractor(playerUrl);
      }
      videos.addAll(a);
    }

    return videos;
  }

  MPages animeResList(String res) {
    final statusList = [
      {"EN COURS": 0, "TERMINÉ": 1}
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

      final titleO = animeJson["titleO"];
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
              "/anime/${regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=$lang&s=$ind";

          animeList.add(anime);
        }
      }
    }
    return MPages(animeList, true);
  }

  MPages animeSeachFetch(String res, String query) {
    final statusList = [
      {"EN COURS": 0, "TERMINÉ": 1}
    ];
    List<MManga> animeList = [];
    final jsonResList = json.decode(res);
    for (var animeJson in jsonResList) {
      MManga anime = MManga();

      final titleO = getMapValue(json.encode(animeJson), "titleO");
      final titleAlt =
          getMapValue(json.encode(animeJson), "titles", encode: true);
      final containsEn = getMapValue(titleAlt, "en")
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
      final containsEnJp = getMapValue(titleAlt, "en_jp")
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
      final containsJaJp = getMapValue(titleAlt, "ja_jp")
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
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
        final titleO = animeJson["titleO"];
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
                "/anime/${regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=$lang&s=$ind";

            animeList.add(anime);
          }
        }
      }
    }
    return MPages(animeList, true);
  }

  Future<String> dataBase() async {
    final data = {
      "url": "https://api.franime.fr/api/animes/",
      "headers": {"Referer": "https://franime.fr/"}
    };

    return await http('GET', json.encode(data));
  }

  String databaseAnimeByTitleO(String res, String titleO) {
    print(titleO);
    final datas = json.decode(res) as List;
    for (var data in datas) {
      if (regExp(data["titleO"], "[^A-Za-z0-9 ]", "", 0, 0)
              .replaceAll(" ", "-")
              .toLowerCase() ==
          "${titleO}") {
        return json.encode(data);
      }
    }
    return "";
  }
}

FrAnime main() {
  return FrAnime();
}

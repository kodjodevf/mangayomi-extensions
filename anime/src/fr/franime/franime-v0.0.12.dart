import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

Future<String> dataBase(int sourceId) async {
  final data = {
    "url": "https://api.franime.fr/api/animes/",
    "headers": {"Referer": "https://franime.fr/"},
    "sourceId": sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  return res;
}

getPopularAnime(MangaModel anime) async {
  final data = {
    "url": "https://api.franime.fr/api/animes/",
    "headers": {"Referer": "https://franime.fr/"},
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return [];
  }
  List<MangaModel> animeList = animeResList(res);

  return animeList;
}

List<MangaModel> animeResList(String res) {
  final statusList = [
    {"EN COURS": 0, "TERMINÉ": 1}
  ];
  List<MangaModel> animeList = [];
  final langs =
      MBridge.jsonPathToList(res, r'$..saisons[*].episodes[*].lang', 1);
  int index = 0;
  List<String> jsonResList = MBridge.jsonDecodeToList(res, 1);
  for (var animeJson in jsonResList) {
    MangaModel anime = MangaModel();
    List<String> seasons = MBridge.jsonDecodeToList(
        MBridge.getMapValue(animeJson, "saisons", 1), 1);
    final titleO = MBridge.getMapValue(animeJson, "titleO", 0);
    final vo = MBridge.getMapValue(MBridge.listParse(langs, 0)[index], "vo", 1);
    final vf = MBridge.getMapValue(MBridge.listParse(langs, 0)[index], "vf", 1);
    final hasVostfr = MBridge.isEmptyOrIsNotEmpty(
        MBridge.jsonDecodeToList(MBridge.getMapValue(vo, "lecteurs", 1), 0), 1);
    final hasVf = MBridge.isEmptyOrIsNotEmpty(
        MBridge.jsonDecodeToList(MBridge.getMapValue(vf, "lecteurs", 1), 0), 1);
    String title = MBridge.getMapValue(animeJson, "title", 0);
    final genre = MBridge.jsonDecodeToList(
        MBridge.getMapValue(animeJson, "themes", 1), 0);
    final description = MBridge.getMapValue(animeJson, "description", 0);
    final status = MBridge.parseStatus(
        MBridge.getMapValue(animeJson, "status", 0), statusList);
    final imageUrl = MBridge.getMapValue(animeJson, "affiche", 0);
    if (hasVostfr) {
      for (int i = 0; i < seasons.length; i++) {
        int ind = i + 1;

        anime.genre = genre;

        anime.description = description;
        String seasonTitle = title;
        if (seasons.length > 1) {
          seasonTitle += " S$ind";
        }
        if (hasVostfr) {
          seasonTitle += " VOSTFR";
        }
        anime.status = status;
        anime.name = seasonTitle;
        anime.imageUrl = imageUrl;
        anime.link =
            "/anime/${MBridge.regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=vo&s=$ind";
        ind++;
      }
    } else if (hasVf) {
      for (int i = 0; i < seasons.length; i++) {
        int ind = i + 1;
        anime.genre = genre;
        anime.description = description;
        String seasonTitle = title;
        if (seasons.length > 1) {
          seasonTitle += " S$ind";
        }
        if (hasVf) {
          seasonTitle += " VF";
        }
        anime.status = status;
        anime.name = seasonTitle;
        anime.imageUrl = imageUrl;
        anime.link =
            "/anime/${MBridge.regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=vo&s=$ind";
        ind++;
      }
    }
    animeList.add(anime);
    index++;
  }
  return animeList;
}

String databaseAnimeByTitleO(String res, String titleO) {
  print(titleO);
  List<String> datas = MBridge.jsonDecodeToList(res, 1);
  for (var data in datas) {
    if (MBridge.regExp(MBridge.getMapValue(data, "titleO", 0), "[^A-Za-z0-9 ]",
                "", 0, 0)
            .replaceAll(" ", "-")
            .toLowerCase() ==
        "${titleO}") {
      return data;
    }
  }
  return "";
}

getAnimeDetail(MangaModel anime) async {
  String language = "vo".toString();
  if (anime.link.contains("lang=")) {
    language = MBridge.listParse(
        MBridge.listParse(anime.link.split("lang="), 2)[0].split("&"), 1)[0];
    print(language);
  }
  String stem = MBridge.listParse(
      MBridge.listParse(anime.link.split("/"), 2)[0].split("?"), 1)[0];
  final res = await dataBase(anime.sourceId);
  if (res.isEmpty) {
    return anime;
  }
  final animeByTitleOJson = databaseAnimeByTitleO(res, stem);
  if (animeByTitleOJson.isEmpty) {
    return anime;
  }
  String seasonsJson =
      MBridge.jsonPathToList(animeByTitleOJson, r'$..saisons', 1)[0];
  List<String> seasons = MBridge.jsonDecodeToList(seasonsJson, 1);

  if (anime.link.contains("s=")) {
    int seasonNumber =
        MBridge.intParse(MBridge.listParse(anime.link.split("s="), 2)[0]);
    seasonsJson = MBridge.listParse(seasons, 0)[seasonNumber - 1];
  } else {
    seasonsJson = MBridge.listParse(seasons, 0)[0];
  }
  final episodesJson =
      MBridge.jsonPathToList(seasonsJson, r'$..episodes', 1)[0];
  List<String> episodes = MBridge.jsonDecodeToList(episodesJson, 1);
  List<String> episodesNames = [];
  List<String> episodesUrls = [];
  for (int i = 0; i < episodes.length; i++) {
    String episode = MBridge.listParse(episodes, 0)[i];
    final lang = MBridge.getMapValue(episode, "lang", 1);
    final vo = MBridge.getMapValue(lang, "vo", 1);
    final vf = MBridge.getMapValue(lang, "vf", 1);
    final hasVostfr = MBridge.isEmptyOrIsNotEmpty(
        MBridge.jsonDecodeToList(MBridge.getMapValue(vo, "lecteurs", 1), 0), 1);
    final hasVf = MBridge.isEmptyOrIsNotEmpty(
        MBridge.jsonDecodeToList(MBridge.getMapValue(vf, "lecteurs", 1), 0), 1);
    bool playerIsNotEmpty = false;
    if (language == "vo" && hasVostfr) {
      playerIsNotEmpty = true;
    } else if (language == "vf" && hasVf) {
      playerIsNotEmpty = true;
    }
    if (playerIsNotEmpty) {
      episodesUrls.add("${anime.link}&ep=${i + 1}");
      final title = MBridge.getMapValue(episode, "title", 1);
      episodesNames.add(title.replaceAll('"', ""));
    }
  }

  anime.urls = episodesUrls;
  anime.names = episodesNames;
  anime.chaptersDateUploads = [];
  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final res = await dataBase(anime.sourceId);

  if (res.isEmpty) {
    return anime;
  }
  List<String> reversed =
      MBridge.listParse(MBridge.jsonDecodeToList(res, 1), 5);
  String reversedJson = "".toString();
  for (int i = 0; i < reversed.length; i++) {
    final va = MBridge.listParse(reversed, 0)[i];
    String vg = "".toString();
    if (reversedJson.isNotEmpty) {
      vg = ",".toString();
    }
    reversedJson += "$vg$va";
  }
  List<MangaModel> animeList = animeResList("[${reversedJson}]");

  return animeList;
}

searchAnime(MangaModel anime) async {
  final res = await dataBase(anime.sourceId);

  if (res.isEmpty) {
    return anime;
  }
  List<MangaModel> animeList = animeSeachFetch(res, anime.query);
  return animeList;
}

List<MangaModel> animeSeachFetch(String res, query) {
  final statusList = [
    {"EN COURS": 0, "TERMINÉ": 1}
  ];
  List<MangaModel> animeList = [];
  final langs =
      MBridge.jsonPathToList(res, r'$..saisons[*].episodes[*].lang', 1);
  int index = 0;
  List<String> jsonResList = MBridge.jsonDecodeToList(res, 1);
  for (var animeJson in jsonResList) {
    MangaModel anime = MangaModel();

    final titleO = MBridge.getMapValue(animeJson, "titleO", 0);

    final titleAlt = MBridge.getMapValue(animeJson, "titles", 1);
    final enContains = MBridge.getMapValue(titleAlt, "en", 0)
        .toString()
        .toLowerCase()
        .contains(query);
    final enJpContains = MBridge.getMapValue(titleAlt, "en_jp", 0)
        .toString()
        .toLowerCase()
        .contains(query);
    final jaJpContains = MBridge.getMapValue(titleAlt, "ja_jp", 0)
        .toString()
        .toLowerCase()
        .contains(query);
    final titleOContains = titleO.toLowerCase().contains(query);
    bool contains = false;
    if (enContains) {
      contains = true;
    }
    if (enJpContains) {
      contains = true;
    }
    if (jaJpContains) {
      contains = true;
    }
    if (titleOContains) {
      contains = true;
    }
    if (contains) {
      List<String> seasons = MBridge.jsonDecodeToList(
          MBridge.getMapValue(animeJson, "saisons", 1), 1);
      final vo =
          MBridge.getMapValue(MBridge.listParse(langs, 0)[index], "vo", 1);
      final vf =
          MBridge.getMapValue(MBridge.listParse(langs, 0)[index], "vf", 1);
      final hasVostfr = MBridge.isEmptyOrIsNotEmpty(
          MBridge.jsonDecodeToList(MBridge.getMapValue(vo, "lecteurs", 1), 0),
          1);
      final hasVf = MBridge.isEmptyOrIsNotEmpty(
          MBridge.jsonDecodeToList(MBridge.getMapValue(vf, "lecteurs", 1), 0),
          1);
      String title = MBridge.getMapValue(animeJson, "title", 0);
      final genre = MBridge.jsonDecodeToList(
          MBridge.getMapValue(animeJson, "themes", 1), 0);
      final description = MBridge.getMapValue(animeJson, "description", 0);
      final status = MBridge.parseStatus(
          MBridge.getMapValue(animeJson, "status", 0), statusList);
      final imageUrl = MBridge.getMapValue(animeJson, "affiche", 0);
      if (hasVostfr) {
        for (int i = 0; i < seasons.length; i++) {
          int ind = i + 1;

          anime.genre = genre;
          anime.description = description;
          String seasonTitle = title;
          if (seasons.length > 1) {
            seasonTitle += " S$ind";
          }
          if (hasVostfr) {
            seasonTitle += " VOSTFR";
          }
          anime.status = status;
          anime.name = seasonTitle;
          anime.imageUrl = imageUrl;
          anime.link =
              "/anime/${MBridge.regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=vo&s=$ind";
          ind++;
        }
      } else if (hasVf) {
        for (int i = 0; i < seasons.length; i++) {
          int ind = i + 1;
          anime.genre = genre;
          anime.description = description;
          String seasonTitle = title;
          if (seasons.length > 1) {
            seasonTitle += " S$ind";
          }
          if (hasVf) {
            seasonTitle += " VF";
          }
          anime.status = status;
          anime.name = seasonTitle;
          anime.imageUrl = imageUrl;
          anime.link =
              "/anime/${MBridge.regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=vf&s=$ind";
          ind++;
        }
      }
      animeList.add(anime);
    }

    index++;
  }
  return animeList;
}

getVideoList(MangaModel anime) async {
  String language = "vo".toString();
  String videoBaseUrl = "https://api.franime.fr/api/anime".toString();
  if (anime.link.contains("lang=")) {
    language = MBridge.listParse(
        MBridge.listParse(anime.link.split("lang="), 2)[0].split("&"), 1)[0];
    print(language);
  }
  String stem = MBridge.listParse(
      MBridge.listParse(anime.link.split("/"), 2)[0].split("?"), 1)[0];
  final res = await dataBase(anime.sourceId);
  final animeByTitleOJson = databaseAnimeByTitleO(res, stem);
  final animeId = MBridge.getMapValue(animeByTitleOJson, "id", 0);
  videoBaseUrl += "/$animeId/";

  String seasonsJson =
      MBridge.jsonPathToList(animeByTitleOJson, r'$..saisons', 1)[0];
  List<String> seasons = MBridge.jsonDecodeToList(seasonsJson, 1);
  if (anime.link.contains("s=")) {
    int seasonNumber = MBridge.intParse(MBridge.listParse(
        MBridge.listParse(anime.link.split("s="), 2)[0].split("&"), 1)[0]);
    print(seasonNumber);
    videoBaseUrl += "${seasonNumber - 1}/";
    seasonsJson = MBridge.listParse(seasons, 0)[seasonNumber - 1];
  } else {
    seasonsJson = MBridge.listParse(seasons, 0)[0];
    videoBaseUrl += "0/";
  }
  final episodesJson =
      MBridge.jsonPathToList(seasonsJson, r'$..episodes', 1)[0];
  List<String> episodes = MBridge.jsonDecodeToList(episodesJson, 1);
  String episode = "".toString();
  if (anime.link.contains("ep=")) {
    int episodeNumber =
        MBridge.intParse(MBridge.listParse(anime.link.split("ep="), 2)[0]);
    print(episodeNumber);
    episode = MBridge.listParse(episodes, 0)[episodeNumber - 1];
    videoBaseUrl += "${episodeNumber - 1}";
  } else {
    episode = MBridge.listParse(episodes, 0)[0];
    videoBaseUrl += "0";
  }
  final lang = MBridge.getMapValue(episode, "lang", 1);
  final vo = MBridge.getMapValue(lang, "vo", 1);
  final vf = MBridge.getMapValue(lang, "vf", 1);
  final vostfrPlayers =
      MBridge.jsonDecodeToList(MBridge.getMapValue(vo, "lecteurs", 1), 0);
  final vfPlayers =
      MBridge.jsonDecodeToList(MBridge.getMapValue(vf, "lecteurs", 1), 0);
  final hasVostfr = MBridge.isEmptyOrIsNotEmpty(vostfrPlayers, 1);
  final hasVf = MBridge.isEmptyOrIsNotEmpty(vfPlayers, 1);
  List<String> players = [];
  if (language == "vo" && hasVostfr) {
    players = vostfrPlayers;
    print(players);
  } else if (language == "vf" && hasVf) {
    players = vfPlayers;
    print(players);
  }
  List<VideoModel> videos = [];
  for (int i = 0; i < players.length; i++) {
    String apiUrl = "$videoBaseUrl/$language/$i";
    String playerName = MBridge.listParse(players, 0)[i];
    final data = {
      "url": apiUrl,
      "headers": {"Referer": "https://franime.fr/"},
      "sourceId": anime.sourceId
    };
    final playerUrl = await MBridge.http(json.encode(data), 0);
    List<VideoModel> a = [];
    if (playerName.contains("franime_myvi")) {
      a = MBridge.toVideos(playerUrl, "FRAnime", playerUrl, null);
    } else if (playerName.contains("myvi")) {
      a = await MBridge.myTvExtractor(playerUrl);
    } else if (playerName.contains("sendvid")) {
      a = await MBridge.sendVidExtractor(
          playerUrl, json.encode({"Referer": "https://franime.fr/"}), "");
    } else if (playerName.contains("sibnet")) {
      a = await MBridge.sibnetExtractor(playerUrl);
    } else if (playerName.contains("sbfull")) {}
    for (var vi in a) {
      videos.add(vi);
    }
  }

  return videos;
}

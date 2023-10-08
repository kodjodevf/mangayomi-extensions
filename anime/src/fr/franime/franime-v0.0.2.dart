import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

Future<String> dataBase(int sourceId) async {
  final data = {
    "url": "https://api.franime.fr/api/animes/",
    "headers": {"Referer": "https://franime.fr/"}
  };
  final res = await MBridge.http('GET', json.encode(data));
  return res;
}

getPopularAnime(MangaModel anime) async {
  final data = {
    "url": "https://api.franime.fr/api/animes/",
    "headers": {"Referer": "https://franime.fr/"}
  };
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  List<MangaModel> animeList = animeResList(res);

  return animeList;
}

List<MangaModel> animeResList(String res) {
  final statusList = [
    {"EN COURS": 0, "TERMINÉ": 1}
  ];
  List<MangaModel> animeList = [];

  final jsonResList = json.decode(res);

  for (var animeJson in jsonResList) {
    MangaModel anime = MangaModel();
    final seasons = animeJson["saisons"];
    List vostfrListName = [];
    List vfListName = [];
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
    final status = MBridge.parseStatus(animeJson["status"], statusList);
    final imageUrl = animeJson["affiche"];

    if (vostfrListName.contains(true)) {
      for (int i = 0; i < seasons.length; i++) {
        int ind = i + 1;
        anime.genre = genre;
        anime.description = description;
        String seasonTitle = title.isEmpty ? titleO : title;
        if (seasons.length > 1) {
          seasonTitle += " S$ind";
        }
        if (vostfrListName.contains(true)) {
          seasonTitle += " VOSTFR";
        }
        anime.status = status;
        anime.name = seasonTitle;
        anime.imageUrl = imageUrl;
        anime.link =
            "/anime/${MBridge.regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=vo&s=$ind";
        ind++;
      }
    } else if (vfListName.contains(true)) {
      for (int i = 0; i < seasons.length; i++) {
        int ind = i + 1;
        anime.genre = genre;
        anime.description = description;
        String seasonTitle = title.isEmpty ? titleO : title;
        if (seasons.length > 1) {
          seasonTitle += " S$ind";
        }
        if (vfListName.contains(true)) {
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
  }
  return animeList;
}

String databaseAnimeByTitleO(String res, String titleO) {
  final datas = MBridge.jsonDecodeToList(res, 1);
  for (var data in datas) {
    if (MBridge.regExp(
                MBridge.getMapValue(data, "titleO"), "[^A-Za-z0-9 ]", "", 0, 0)
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
    language = MBridge.substringBefore(
        MBridge.substringAfter(anime.link, "lang="), "&");
  }
  String stem =
      MBridge.substringBefore(MBridge.substringAfterLast(anime.link, "/"), "?");
  final res = await dataBase(anime.sourceId);
  if (res.isEmpty) {
    return anime;
  }
  final animeByTitleOJson = databaseAnimeByTitleO(res, stem);
  if (animeByTitleOJson.isEmpty) {
    return anime;
  }
  final seasons = json.decode(animeByTitleOJson)["saisons"];

  var seasonsJson = seasons.first;

  if (anime.link.contains("s=")) {
    int seasonNumber = MBridge.intParse(
        MBridge.substringBefore(MBridge.substringAfter(anime.link, "s="), "&"));
    seasonsJson = seasons[seasonNumber - 1];
  }

  final episodes = seasonsJson["episodes"];

  List<String> episodesNames = [];
  List<String> episodesUrls = [];
  for (int i = 0; i < episodes.length; i++) {
    final episode = episodes[i];

    final lang = episode["lang"];

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
      episodesUrls.add("${anime.link}&ep=${i + 1}");
      String title = episode["title"];
      episodesNames.add(title.replaceAll('"', ""));
    }
  }

  anime.urls = episodesUrls.reversed.toList();
  anime.names = episodesNames.reversed.toList();
  anime.chaptersDateUploads = [];
  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final res = await dataBase(anime.sourceId);

  if (res.isEmpty) {
    return anime;
  }
  List list = json.decode(res);
  List reversedList = list.reversed.toList();
  List<MangaModel> animeList = animeResList(json.encode(reversedList));

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
  final jsonResList = json.decode(res);
  for (var animeJson in jsonResList) {
    MangaModel anime = MangaModel();

    final titleO = MBridge.getMapValue(json.encode(animeJson), "titleO");
    final titleAlt =
        MBridge.getMapValue(json.encode(animeJson), "titles", encode: true);
    final enContains = MBridge.getMapValue(titleAlt, "en")
        .toString()
        .toLowerCase()
        .contains(query);
    final enJpContains = MBridge.getMapValue(titleAlt, "en_jp")
        .toString()
        .toLowerCase()
        .contains(query);
    final jaJpContains = MBridge.getMapValue(titleAlt, "ja_jp")
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
      final seasons = animeJson["saisons"];
      List hasVostfr = [];
      List hasVf = [];
      for (var season in seasons) {
        for (var episode in season["episodes"]) {
          final lang = episode["lang"];
          final vo = lang["vo"];
          final vf = lang["vf"];
          hasVostfr.add(vo["lecteurs"].isNotEmpty);
          hasVf.add(vf["lecteurs"].isNotEmpty);
        }
      }
      final titleO = animeJson["titleO"];
      final title = animeJson["title"];
      final genre = animeJson["themes"];
      final description = animeJson["description"];
      final status = MBridge.parseStatus(animeJson["status"], statusList);
      final imageUrl = animeJson["affiche"];

      if (hasVostfr.contains(true)) {
        for (int i = 0; i < seasons.length; i++) {
          int ind = i + 1;
          anime.genre = genre;
          anime.description = description;
          String seasonTitle = title.isEmpty ? titleO : title;
          if (seasons.length > 1) {
            seasonTitle += " S$ind";
          }
          if (hasVostfr.contains(true)) {
            seasonTitle += " VOSTFR";
          }
          anime.status = status;
          anime.name = seasonTitle;
          anime.imageUrl = imageUrl;
          anime.link =
              "/anime/${MBridge.regExp(titleO, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}?lang=vo&s=$ind";
          ind++;
        }
      } else if (hasVf.contains(true)) {
        for (int i = 0; i < seasons.length; i++) {
          int ind = i + 1;
          anime.genre = genre;
          anime.description = description;
          String seasonTitle = title.isEmpty ? titleO : title;
          if (seasons.length > 1) {
            seasonTitle += " S$ind";
          }
          if (hasVf.contains(true)) {
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
    }
  }
  return animeList;
}

getVideoList(MangaModel anime) async {
  String language = "vo".toString();
  String videoBaseUrl = "https://api.franime.fr/api/anime".toString();
  if (anime.link.contains("lang=")) {
    language = MBridge.substringBefore(
        MBridge.substringAfter(anime.link, "lang="), "&");
    print(language);
  }
  String stem =
      MBridge.substringBefore(MBridge.substringAfterLast(anime.link, "/"), "?");
  final res = await dataBase(anime.sourceId);
  if (res.isEmpty) {
    return anime;
  }
  final animeByTitleOJson = databaseAnimeByTitleO(res, stem);
  if (animeByTitleOJson.isEmpty) {
    return anime;
  }
  final animeId = json.decode(animeByTitleOJson)["id"];
  final seasons = json.decode(animeByTitleOJson)["saisons"];

  var seasonsJson = seasons.first;

  videoBaseUrl += "/$animeId/";

  if (anime.link.contains("s=")) {
    int seasonNumber = MBridge.intParse(
        MBridge.substringBefore(MBridge.substringAfter(anime.link, "s="), "&"));
    print(seasonNumber);
    videoBaseUrl += "${seasonNumber - 1}/";
    seasonsJson = seasons[seasonNumber - 1];
  } else {
    videoBaseUrl += "0/";
  }
  final episodesJson = seasonsJson["episodes"];
  var episode = episodesJson.first;
  if (anime.link.contains("ep=")) {
    int episodeNumber =
        MBridge.intParse(MBridge.substringAfter(anime.link, "ep="));
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
  final vostfrPlayers = vo["lecteurs"];
  final vfPlayers = vf["lecteurs"];
  var players = [];
  if (language == "vo" && hasVostfr) {
    players = vostfrPlayers;
  } else if (language == "vf" && hasVf) {
    players = vfPlayers;
  }
  List<VideoModel> videos = [];
  for (int i = 0; i < players.length; i++) {
    String apiUrl = "$videoBaseUrl/$language/$i";
    String playerName = players[i];
    final data = {
      "url": apiUrl,
      "headers": {"Referer": "https://franime.fr/"},
      "sourceId": anime.sourceId
    };
    final playerUrl = await MBridge.http('GET', json.encode(data));
    List<VideoModel> a = [];
    if (playerName.contains("franime_myvi")) {
      videos.add(
          MBridge.toVideo(playerUrl, "FRAnime", playerUrl, null, null, null));
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

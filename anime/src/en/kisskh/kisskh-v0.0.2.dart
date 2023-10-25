import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MManga anime) async {
  final data = {
    "url":
        "${anime.baseUrl}/api/DramaList/List?page=${anime.page}&type=0&sub=0&country=0&status=0&order=1&pageSize=40"
  };
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  final jsonRes = json.decode(res);
  final datas = jsonRes["data"] as List;
  anime.names = datas.map((e) => e["title"]).toList();
  anime.images = datas.map((e) => e["thumbnail"] ?? "").toList();
  anime.urls = datas
      .map((e) => "${anime.baseUrl}/api/DramaList/Drama/${e["id"]}?isq=false")
      .toList();
  final lastPage = jsonRes["totalCount"] as int;
  final page = jsonRes["page"] as int;

  anime.hasNextPage = page < lastPage;
  return anime;
}

getLatestUpdatesAnime(MManga anime) async {
  final data = {
    "url":
        "${anime.baseUrl}/api/DramaList/List?page=${anime.page}&type=0&sub=0&country=0&status=0&order=12&pageSize=40"
  };
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  final jsonRes = json.decode(res);
  final datas = jsonRes["data"] as List;
  anime.names = datas.map((e) => e["title"]).toList();
  anime.images = datas.map((e) => e["thumbnail"] ?? "").toList();
  anime.urls = datas
      .map((e) => "${anime.baseUrl}/api/DramaList/Drama/${e["id"]}?isq=false")
      .toList();
  final lastPage = jsonRes["totalCount"] as int;
  final page = jsonRes["page"] as int;

  anime.hasNextPage = page < lastPage;

  return anime;
}

getAnimeDetail(MManga anime) async {
  final statusList = [
    {
      "Ongoing": 0,
      "Completed": 1,
    }
  ];

  final data = {"url": anime.link};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  final jsonRes = json.decode(res);
  final status = jsonRes["status"] ?? "";
  print(status);
  anime.description = jsonRes["description"];
  anime.status = MBridge.parseStatus(status, statusList);
  anime.imageUrl = jsonRes["thumbnail"];
  var episodes = jsonRes["episodes"];
  String type = jsonRes["type"];
  final episodesCount = jsonRes["episodesCount"] as int;
  List<String> episodesNames = [];
  List<String> episodesUrls = [];
  final containsAnime = type.contains("Anime") as bool;
  final containsTVSeries = type.contains("TVSeries") as bool;
  final containsHollywood = type.contains("Hollywood") as bool;
  final containsMovie = type.contains("Movie") as bool;
  for (var a in episodes) {
    String number = (a["number"] as double).toString().replaceAll(".0", "");
    final id = a["id"];
    if (containsAnime || containsTVSeries) {
      episodesNames.add("Episode $number");
    } else if (containsHollywood && episodesCount == 1 || containsMovie) {
      episodesNames.add("Movie");
    } else if (containsHollywood && episodesCount > 1) {
      episodesNames.add("Episode $number");
    }

    episodesUrls.add(
        "${anime.baseUrl}/api/DramaList/Episode/$id.png?err=false&ts=&time=");
  }
  anime.urls = episodesUrls;
  anime.names = episodesNames;
  anime.chaptersDateUploads = [];
  return anime;
}

getVideoList(MManga anime) async {
  final datas = {"url": anime.link};

  final response = await MBridge.http('GET', json.encode(datas));

  if (response.hasError) {
    return response;
  }
  String res = response.body;
  final id = MBridge.substringAfter(
      MBridge.substringBefore(anime.link, ".png"), "Episode/");
  final jsonRes = json.decode(res);
  final subRes = await MBridge.http(
      'GET', json.encode({"url": "${anime.baseUrl}/api/Sub/$id"}));
  var jsonSubRes = json.decode(subRes.body);

  List<MTrack> subtitles = [];

  for (var sub in jsonSubRes) {
    try {
      final subUrl = sub["src"];
      final label = sub["label"];
      MTrack subtitle = MTrack();
      subtitle
        ..label = label
        ..file = subUrl;
      subtitles.add(subtitle);
    } catch (_) {}
  }

  final videoUrl = jsonRes["Video"];
  MVideo video = MVideo();
  video
    ..url = videoUrl
    ..originalUrl = videoUrl
    ..quality = "kisskh"
    ..subtitles = subtitles
    ..headers = {
      "referer": "https://kisskh.me/",
      "origin": "https://kisskh.me"
    };
  return [video];
}

searchAnime(MManga anime) async {
  final data = {
    "url": "${anime.baseUrl}/api/DramaList/Search?q=${anime.query}&type=0"
  };
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  var jsonRes = json.decode(res) as List;
  anime.names = jsonRes.map((e) => e["title"]).toList();
  anime.images = jsonRes.map((e) => e["thumbnail"] ?? "").toList();
  anime.urls = jsonRes
      .map((e) => "${anime.baseUrl}/api/DramaList/Drama/${e["id"]}?isq=false")
      .toList();

  return anime;
}

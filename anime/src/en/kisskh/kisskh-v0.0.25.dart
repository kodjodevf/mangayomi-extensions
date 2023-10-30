import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class KissKh extends MSourceProvider {
  KissKh();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final data = {
      "url":
          "${sourceInfo.baseUrl}/api/DramaList/List?page=$page&type=0&sub=0&country=0&status=0&order=1&pageSize=40"
    };
    final res = await MBridge.http('GET', json.encode(data));
    final jsonRes = json.decode(res);
    final datas = jsonRes["data"] as List;
    List<MManga> animeList = [];

    for (var data in datas) {
      MManga anime = MManga();
      anime.name = data["title"];
      anime.imageUrl = data["thumbnail"] ?? "";
      anime.link =
          "${sourceInfo.baseUrl}/api/DramaList/Drama/${data["id"]}?isq=false";
      animeList.add(anime);
    }

    int lastPage = jsonRes["totalCount"];
    int pages = jsonRes["page"];
    return MPages(animeList, pages < lastPage);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final data = {
      "url":
          "${sourceInfo.baseUrl}/api/DramaList/List?page=$page&type=0&sub=0&country=0&status=0&order=12&pageSize=40",
      "header": {"ee": "eee"}
    };
    final res = await MBridge.http('GET', json.encode(data));
    final jsonRes = json.decode(res);
    final datas = jsonRes["data"] as List;

    List<MManga> animeList = [];

    for (var data in datas) {
      MManga anime = MManga();
      anime.name = data["title"];
      anime.imageUrl = data["thumbnail"] ?? "";
      anime.link =
          "${sourceInfo.baseUrl}/api/DramaList/Drama/${data["id"]}?isq=false";
      animeList.add(anime);
    }

    int lastPage = jsonRes["totalCount"];
    int pages = jsonRes["page"];
    return MPages(animeList, pages < lastPage);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final data = {
      "url": "${sourceInfo.baseUrl}/api/DramaList/Search?q=$query&type=0"
    };
    final res = await MBridge.http('GET', json.encode(data));
    final jsonRes = json.decode(res);
    List<MManga> animeList = [];
    for (var data in jsonRes) {
      MManga anime = MManga();
      anime.name = data["title"];
      anime.imageUrl = data["thumbnail"] ?? "";
      anime.link =
          "${sourceInfo.baseUrl}/api/DramaList/Drama/${data["id"]}?isq=false";
      animeList.add(anime);
    }
    return MPages(animeList, false);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {
        "Ongoing": 0,
        "Completed": 1,
      }
    ];
    final data = {"url": url};
    final res = await MBridge.http('GET', json.encode(data));
    MManga anime = MManga();
    final jsonRes = json.decode(res);
    final status = jsonRes["status"] ?? "";
    print(status);
    anime.description = jsonRes["description"];
    anime.status = MBridge.parseStatus(status, statusList);
    anime.imageUrl = jsonRes["thumbnail"];
    var episodes = jsonRes["episodes"];
    String type = jsonRes["type"];
    final episodesCount = jsonRes["episodesCount"];
    final containsAnime = type.contains("Anime");
    final containsTVSeries = type.contains("TVSeries");
    final containsHollywood = type.contains("Hollywood");
    final containsMovie = type.contains("Movie");
    List<MChapter>? episodesList = [];

    for (var a in episodes) {
      MChapter episode = MChapter();
      String number = (a["number"] as double).toString().replaceAll(".0", "");
      final id = a["id"];
      if (containsAnime || containsTVSeries) {
        episode.name = "Episode $number";
      } else if (containsHollywood && episodesCount == 1 || containsMovie) {
        episode.name = "Movie";
      } else if (containsHollywood && episodesCount > 1) {
        episode.name = "Episode $number";
      }
      episode.url =
          "${sourceInfo.baseUrl}/api/DramaList/Episode/$id.png?err=false&ts=&time=";
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    final datas = {"url": url};

    final res = await MBridge.http('GET', json.encode(datas));
    final id = MBridge.substringAfter(
        MBridge.substringBefore(url, ".png"), "Episode/");
    final jsonRes = json.decode(res);

    final subRes = await MBridge.http(
        'GET', json.encode({"url": "${sourceInfo.baseUrl}/api/Sub/$id"}));
    var jsonSubRes = json.decode(subRes);

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

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    return [];
  }
}

KissKh main() {
  return KissKh();
}

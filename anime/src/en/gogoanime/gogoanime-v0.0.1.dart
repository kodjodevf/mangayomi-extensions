import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/popular.html?page=${anime.page}",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  anime.urls =
      MBridge.xpath(res, '//*[@class="img"]/a/@href', '._').split('._');

  anime.names =
      MBridge.xpath(res, '//*[@class="img"]/a/@title', '._').split('._');

  anime.images =
      MBridge.xpath(res, '//*[@class="img"]/a/img/@src', '._').split('._');

  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final url =
      "https://ajax.gogo-load.com/ajax/page-recent-release-ongoing.html?page=${anime.page}&type=1";
  final data = {"url": url, "headers": null, "sourceId": anime.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(
          res, '//*[@class="added_series_body popular"]/ul/li/a[1]/@href', '._')
      .split('._');

  anime.names = MBridge.xpath(res,
          '//*[//*[@class="added_series_body popular"]/ul/li/a[1]/@title', '._')
      .split('._');
  List<String> images = [];
  List<String> imagess = MBridge.xpath(
          res,
          '//*[//*[@class="added_series_body popular"]/ul/li/a/div[@class="thumbnail-popular"]/@style',
          '._')
      .split('._');
  for (var url in MBridge.listParse(imagess, 0)) {
    images.add(url.replaceAll("background: url('", "").replaceAll("');", ""));
  }

  anime.images = images;

  return anime;
}

getAnimeDetail(MangaModel anime) async {
  final statusList = [
    {
      "Ongoing": 0,
      "Completed": 1,
    }
  ];
  final url = "${anime.baseUrl}${anime.link}";
  final data = {"url": url, "headers": null};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  final status = MBridge.xpath(res,
          '//*[@class="anime_info_body_bg"]/p[@class="type"][5]/text()', '')
      .replaceAll("Status: ", "");

  anime.description = MBridge.xpath(res,
          '//*[@class="anime_info_body_bg"]/p[@class="type"][2]/text()', '')
      .replaceAll("Plot Summary: ", "");

  anime.status = MBridge.parseStatus(status, statusList);
  anime.genre = MBridge.listParse(
      MBridge.xpath(res,
              '//*[@class="anime_info_body_bg"]/p[@class="type"][3]/text()', '')
          .replaceAll("Genre: ", "")
          .split(","),
      4);

  final id = MBridge.xpath(res, '//*[@id="movie_id"]/@value', '');
  final urlEp =
      "https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=4000&id=$id";
  final dataEp = {"url": urlEp, "headers": null};
  final resEp = await MBridge.http(json.encode(dataEp), 0);
  anime.urls =
      MBridge.xpath(resEp, '//*[@id="episode_related"]/li/a/@href', '._')
          .split("._");
  List<String> names = MBridge.xpath(resEp,
          '//*[@id="episode_related"]/li/a/div[@class="name"]/text()', '._')
      .split("._");

  List<String> episodes = [];
  for (var a in MBridge.listParse(names, 0)) {
    episodes.add("Episode ${MBridge.subString(a, ' ', 1)}");
  }

  anime.names = episodes;
  anime.chaptersDateUploads = [];
  return anime;
}

getChapterUrl(MangaModel anime) async {
  final datas = {
    "url": "${anime.baseUrl}${anime.link}",
    "headers": null,
    "sourceId": anime.sourceId
  };

  final res = await MBridge.http(json.encode(datas), 0);

  if (res.isEmpty) {
    return [];
  }

  final serverUrls = MBridge.xpath(
          res, '//*[@class="anime_muti_link"]/ul/li/a/@data-video', ".-")
      .split(".-");
  List<String> classNames =
      MBridge.xpath(res, '//*[@class="anime_muti_link"]/ul/li/@class', ".-")
          .split(".-");
  print(serverUrls);
  List<VideoModel> videos = [];
  for (var i = 0; i < classNames.length; i++) {
    final name = MBridge.listParse(classNames, 0)[i].toString();
    final url = MBridge.listParse(serverUrls, 0)[i].toString();
    print(url);
    List<VideoModel> a = [];
    if (name.contains("anime")) {
      a = await MBridge.gogoCdnExtractor(url);
    } else if (name.contains("vidcdn")) {
      a = await MBridge.gogoCdnExtractor(url);
    } else if (name.contains("doodstream")) {
      a = await MBridge.doodExtractor(url);
    } else if (name.contains("mp4upload")) {
      a = await MBridge.mp4UploadExtractor(url, null, "", "");
    } else if (name.contains("streamsb")) {
      // print("streamsb");
      // print(url);
    }
    for (var vi in a) {
      videos.add(vi);
    }
  }

  return videos;
}

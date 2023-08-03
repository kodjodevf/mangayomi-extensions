import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  final data = {"url": "${anime.baseUrl}/", "headers": null};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(
          res,
          '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/@href',
          '._')
      .split('._');

  anime.names = MBridge.xpath(
          res,
          '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@title',
          '._')
      .split('._');

  anime.images = MBridge.xpath(
          res,
          '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@data-src',
          '._')
      .split('._');
  anime.hasNextPage = false;
  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  anime.urls = MBridge.xpath(
          res,
          '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@href',
          '._')
      .split('._');

  anime.names = MBridge.xpath(
          res,
          '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@title',
          '._')
      .split('._');

  anime.images = MBridge.xpath(
          res,
          '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/img/@data-src',
          '._')
      .split('._');
  anime.hasNextPage = false;
  return anime;
}

searchAnime(MangaModel anime) async {
  final url =
      "${anime.baseUrl}/?story=${anime.query}&do=search&subaction=search";
  final data = {"url": url, "headers": null};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  anime.urls =
      MBridge.xpath(res, '//*[@class="film-poster"]/a/@href', '._').split('._');

  anime.names = MBridge.xpath(res, '//*[@class="film-poster"]/a/@title', '._')
      .split('._');
  anime.images =
      MBridge.xpath(res, '//*[@class="film-poster"]/img/@data-src', '._')
          .split('._');
  anime.hasNextPage = false;
  return anime;
}

getAnimeDetail(MangaModel anime) async {
  final statusList = [
    {
      "En cours": 0,
      "Terminé": 1,
    }
  ];
  final url = anime.link;
  final data = {"url": url, "headers": null};
  String res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  anime.description =
      MBridge.xpath(res, '//*[@class="film-description m-hide"]/text()', '');

  final status = MBridge.xpath(
      res,
      '//*[@class="item item-title" and contains(text(),"Status:")]/span[2]/text()',
      '');

  anime.status = MBridge.parseStatus(status, statusList);

  anime.genre = MBridge.xpath(
          res,
          '//*[@class="item item-list" and contains(text(),"Genres:")]/a/text()',
          '._')
      .split('._');
  anime.author = MBridge.xpath(
      res,
      '//*[@class="item item-title" and contains(text(),"Studio:")]/span[2]/text()',
      '');
  final urlEp = anime.link.replaceAll('.html', '/episode-1.html');
  final resEpWebview =
      await MBridge.getHtmlViaWebview(urlEp, '//*[@class="ss-list"]/a/@href');
  anime.urls = MBridge.listParse(
      MBridge.xpath(resEpWebview, '//*[@class="ss-list"]/a/@href', '._')
          .split("._"),
      5);

  anime.names = MBridge.listParse(
      MBridge.xpath(
              resEpWebview,
              '//*[@class="ss-list"]/a/div[@class="ssli-detail"]/div/text()',
              '._')
          .split("._"),
      5);
  anime.chaptersDateUploads = [];
  return anime;
}

getVideoList(MangaModel anime) async {
  final resWebview = await MBridge.getHtmlViaWebview(
      anime.link, '//*[@class="ps__-list"]/div/@data-server-id');

  final serverIds = MBridge.xpath(
          resWebview, '//*[@class="ps__-list"]/div/@data-server-id', ".-")
      .split(".-");
  final serverNames =
      MBridge.xpath(resWebview, '//*[@class="ps__-list"]/div/a/text()', ".-")
          .split(".-");
  List<String> serverUrls = [];
  for (var id in MBridge.listParse(serverIds, 0)) {
    final serversUrls =
        MBridge.xpath(resWebview, '//*[@id="content_player_${id}"]/text()', "");
    serverUrls.add(serversUrls);
  }

  List<VideoModel> videos = [];
  for (var i = 0; i < serverNames.length; i++) {
    final name = MBridge.listParse(serverNames, 0)[i].toString();
    final url = MBridge.listParse(serverUrls, 0)[i].toString();

    List<VideoModel> a = [];
    if (name.contains("Sendvid")) {
      a = await MBridge.sendVidExtractor(
          url.replaceAll("https:////", "https://"),
          json.encode({"Referer": "${anime.baseUrl}/"}),
          "");
    } else if (name.contains("Sibnet")) {
      a = await MBridge.sibnetExtractor(
          "https://video.sibnet.ru/shell.php?videoid=$url");
    } else if (name.contains("Mytv")) {
      a = await MBridge.myTvExtractor("https://www.myvi.tv/embed/$url");
    }
    for (var vi in a) {
      videos.add(vi);
    }
  }

  return videos;
}

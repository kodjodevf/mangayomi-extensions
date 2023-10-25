import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MManga anime) async {
  final data = {"url": "${anime.baseUrl}/"};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  anime.urls = MBridge.xpath(res,
      '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/@href');
  anime.names = MBridge.xpath(res,
      '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@title');
  anime.images = MBridge.xpath(res,
      '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@data-src');
  anime.hasNextPage = false;
  return anime;
}

getLatestUpdatesAnime(MManga anime) async {
  final data = {"url": "${anime.baseUrl}/"};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;

  anime.urls = MBridge.xpath(res,
      '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@href');
  anime.names = MBridge.xpath(res,
      '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@title');
  anime.images = MBridge.xpath(res,
      '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/img/@data-src');
  anime.hasNextPage = false;
  return anime;
}

searchAnime(MManga anime) async {
  final url =
      "${anime.baseUrl}/?story=${anime.query}&do=search&subaction=search";
  final data = {"url": url};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  anime.urls = MBridge.xpath(res, '//*[@class="film-poster"]/a/@href');
  anime.names = MBridge.xpath(res, '//*[@class="film-poster"]/a/@title');
  anime.images = MBridge.xpath(res, '//*[@class="film-poster"]/img/@data-src');
  anime.hasNextPage = false;
  return anime;
}

getAnimeDetail(MManga anime) async {
  final statusList = [
    {
      "En cours": 0,
      "Terminé": 1,
    }
  ];
  final url = anime.link;
  final data = {"url": url};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  anime.description =
      MBridge.xpath(res, '//*[@class="film-description m-hide"]/text()').first;

  final status = MBridge.xpath(res,
          '//*[@class="item item-title" and contains(text(),"Status:")]/span[2]/text()')
      .first;
  anime.status = MBridge.parseStatus(status, statusList);
  anime.genre = MBridge.xpath(res,
      '//*[@class="item item-list" and contains(text(),"Genres:")]/a/text()');
  anime.author = MBridge.xpath(res,
          '//*[@class="item item-title" and contains(text(),"Studio:")]/span[2]/text()')
      .first;
  final urlEp = anime.link.replaceAll('.html', '/episode-1.html');
  final resEpWebview =
      await MBridge.getHtmlViaWebview(urlEp, '//*[@class="ss-list"]/a/@href');
  anime.urls = MBridge.xpath(resEpWebview, '//*[@class="ss-list"]/a/@href')
      .reversed
      .toList();
  anime.names = MBridge.xpath(resEpWebview,
          '//*[@class="ss-list"]/a/div[@class="ssli-detail"]/div/text()')
      .reversed
      .toList();
  anime.chaptersDateUploads = [];
  return anime;
}

getVideoList(MManga anime) async {
  final resWebview = await MBridge.getHtmlViaWebview(
      anime.link, '//*[@class="ps__-list"]/div/@data-server-id');

  final serverIds =
      MBridge.xpath(resWebview, '//*[@class="ps__-list"]/div/@data-server-id');
  final serverNames =
      MBridge.xpath(resWebview, '//*[@class="ps__-list"]/div/a/text()');
  List<String> serverUrls = [];
  for (var id in serverIds) {
    final serversUrls =
        MBridge.xpath(resWebview, '//*[@id="content_player_${id}"]/text()')
            .first;
    serverUrls.add(serversUrls);
  }
  List<MVideo> videos = [];
  for (var i = 0; i < serverNames.length; i++) {
    final name = serverNames[i];
    final url = serverUrls[i];

    List<MVideo> a = [];
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

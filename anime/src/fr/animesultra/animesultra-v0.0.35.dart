import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AnimesUltra extends MSourceProvider {
  AnimesUltra();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final data = {"url": "${sourceInfo.baseUrl}/"};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res,
        '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/@href');
    final names = MBridge.xpath(res,
        '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@title');
    final images = MBridge.xpath(res,
        '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@data-src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, false);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final data = {"url": "${sourceInfo.baseUrl}/"};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res,
        '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@href');
    final names = MBridge.xpath(res,
        '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@title');
    final images = MBridge.xpath(res,
        '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/img/@data-src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, false);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final data = {"url": "${sourceInfo.baseUrl}/"};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res, '//*[@class="film-poster"]/a/@href');
    final names = MBridge.xpath(res, '//*[@class="film-poster"]/a/@title');
    final images =
        MBridge.xpath(res, '//*[@class="film-poster"]/img/@data-src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, false);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {
        "En cours": 0,
        "Terminé": 1,
      }
    ];
    final data = {"url": url};
    final res = await MBridge.http('GET', json.encode(data));
    MManga anime = MManga();
    anime.description =
        MBridge.xpath(res, '//*[@class="film-description m-hide"]/text()')
            .first;

    final status = MBridge.xpath(res,
            '//*[@class="item item-title" and contains(text(),"Status:")]/span[2]/text()')
        .first;
    anime.status = MBridge.parseStatus(status, statusList);
    anime.genre = MBridge.xpath(res,
        '//*[@class="item item-list" and contains(text(),"Genres:")]/a/text()');
    anime.author = MBridge.xpath(res,
            '//*[@class="item item-title" and contains(text(),"Studio:")]/span[2]/text()')
        .first;
    final urlEp = url.replaceAll('.html', '/episode-1.html');
    final resEpWebview =
        await MBridge.getHtmlViaWebview(urlEp, '//*[@class="ss-list"]/a/@href');
    final epUrls = MBridge.xpath(resEpWebview, '//*[@class="ss-list"]/a/@href')
        .reversed
        .toList();
    final names = MBridge.xpath(resEpWebview,
            '//*[@class="ss-list"]/a/div[@class="ssli-detail"]/div/text()')
        .reversed
        .toList();

    List<MChapter>? episodesList = [];
    for (var i = 0; i < names.length; i++) {
      MChapter episode = MChapter();
      episode.name = names[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    final resWebview = await MBridge.getHtmlViaWebview(
        url, '//*[@class="ps__-list"]/div/@data-server-id');

    final serverIds = MBridge.xpath(
        resWebview, '//*[@class="ps__-list"]/div/@data-server-id');
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
            json.encode({"Referer": "${sourceInfo.baseUrl}/"}),
            "");
      } else if (name.contains("Sibnet")) {
        a = await MBridge.sibnetExtractor(
            "https://video.sibnet.ru/shell.php?videoid=$url");
      } else if (name.contains("Mytv")) {
        a = await MBridge.myTvExtractor("https://www.myvi.tv/embed/$url");
      }
      videos.addAll(a);
    }

    return videos;
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    return [];
  }
}

AnimesUltra main() {
  return AnimesUltra();
}

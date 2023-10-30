import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class OkAnime extends MSourceProvider {
  OkAnime();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final data = {"url": sourceInfo.baseUrl};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res,
        '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');
    final names = MBridge.xpath(res,
        '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');
    final images = MBridge.xpath(res,
        '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-image")]/img/@src');

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
    final data = {"url": "${sourceInfo.baseUrl}/espisode-list?page=$page"};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');
    final names = MBridge.xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');
    final images = MBridge.xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="episode-image")]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage =
        MBridge.xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    String url = "${sourceInfo.baseUrl}/search/?s=$query";
    if (page > 1) {
      url += "&page=$page";
    }
    final data = {"url": url};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');
    final names = MBridge.xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');
    final images = MBridge.xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-image")]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage =
        MBridge.xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {"يعرض الان": 0, "مكتمل": 1}
    ];
    final data = {"url": url};
    final res = await MBridge.http('GET', json.encode(data));
    MManga anime = MManga();
    final status = MBridge.xpath(res,
        '//*[@class="full-list-info" and contains(text(),"حالة الأنمي")]/small/a/text()');
    if (status.isNotEmpty) {
      anime.status = MBridge.parseStatus(status.first, statusList);
    }
    anime.description =
        MBridge.xpath(res, '//*[@class="review-content"]/text()').first;

    anime.genre =
        MBridge.xpath(res, '//*[@class="review-author-info"]/a/text()');
    final epUrls = MBridge.xpath(res,
            '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/@href')
        .reversed
        .toList();
    final names = MBridge.xpath(res,
            '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/text()')
        .reversed
        .toList();

    List<MChapter>? episodesList = [];
    for (var i = 0; i < epUrls.length; i++) {
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
    final res = await MBridge.http('GET', json.encode({"url": url}));

    final urls = MBridge.xpath(res, '//*[@id="streamlinks"]/a/@data-src');
    final qualities =
        MBridge.xpath(res, '//*[@id="streamlinks"]/a/span/text()');

    List<MVideo> videos = [];
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      final quality = getQuality(qualities[i]);
      List<MVideo> a = [];

      if (url.contains("https://doo")) {
        a = await MBridge.doodExtractor(url, "DoodStream - $quality");
      } else if (url.contains("mp4upload")) {
        a = await MBridge.mp4UploadExtractor(url, null, "", "");
      } else if (url.contains("ok.ru")) {
        a = await MBridge.okruExtractor(url);
      } else if (url.contains("voe.sx")) {
        a = await MBridge.voeExtractor(url, "VoeSX $quality");
      } else if (containsVidBom(url)) {
        a = await MBridge.vidBomExtractor(url);
      }
      videos.addAll(a);
    }
    return videos;
  }

  String getQuality(String quality) {
    quality = quality.replaceAll(" ", "");
    if (quality == "HD") {
      return "720p";
    } else if (quality == "FHD") {
      return "1080p";
    } else if (quality == "SD") {
      return "480p";
    }
    return "240p";
  }

  bool containsVidBom(String url) {
    url = url;
    final list = ["vidbam", "vadbam", "vidbom", "vidbm"];
    for (var n in list) {
      if (url.contains(n)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    return [];
  }
}

OkAnime main() {
  return OkAnime();
}

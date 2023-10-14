import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  final data = {"url": anime.baseUrl};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(res,
      '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');

  anime.names = MBridge.xpath(res,
      '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');

  anime.images = MBridge.xpath(res,
      '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-image")]/img/@src');
  anime.hasNextPage = false;
  return anime;
}

getAnimeDetail(MangaModel anime) async {
  final statusList = [
    {"يعرض الان": 0, "مكتمل": 1}
  ];
  final data = {"url": anime.link};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }

  final status = MBridge.xpath(res,
      '//*[@class="full-list-info" and contains(text(),"حالة الأنمي")]/small/a/text()');
  if (status.isNotEmpty) {
    anime.status = MBridge.parseStatus(status.first, statusList);
  }
  anime.description =
      MBridge.xpath(res, '//*[@class="review-content"]/text()').first;
  final genre = MBridge.xpath(res, '//*[@class="review-author-info"]/a/text()');
  anime.genre = genre;

  anime.urls = MBridge.xpath(res,
          '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/@href')
      .reversed
      .toList();

  anime.names = MBridge.xpath(res,
          '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/text()')
      .reversed
      .toList();
  anime.chaptersDateUploads = [];
  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final data = {"url": "${anime.baseUrl}/espisode-list?page=${anime.page}"};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');

  anime.names = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');

  anime.images = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="episode-image")]/img/@src');
  final nextPage =
      MBridge.xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

searchAnime(MangaModel anime) async {
  String url = "${anime.baseUrl}/search/?s=${anime.query}";
  if (anime.page > 1) {
    url += "&page=${anime.page}";
  }
  final data = {"url": url};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');

  anime.names = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');

  anime.images = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-image")]/img/@src');
  final nextPage =
      MBridge.xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

getVideoList(MangaModel anime) async {
  final datas = {"url": anime.link};
  print(anime.link);
  final res = await MBridge.http('GET', json.encode(datas));

  if (res.isEmpty) {
    return [];
  }
  final urls = MBridge.xpath(res, '//*[@id="streamlinks"]/a/@data-src');
  final qualities = MBridge.xpath(res, '//*[@id="streamlinks"]/a/span/text()');

  List<VideoModel> videos = [];
  for (var i = 0; i < urls.length; i++) {
    final url = urls[i];
    final quality = getQuality(qualities[i]);
    List<VideoModel> a = [];

    if (url.contains("https://doo")) {
      a = await MBridge.doodExtractor(url, "DoodStream - $quality");
    } else if (url.contains("mp4upload")) {
      a = await MBridge.mp4UploadExtractor(url, null, "", "");
    } else if (url.contains("ok.ru")) {
      a = await MBridge.okruExtractor(url);
    } else if (url.contains("voe.sx")) {
      a = await MBridge.voeExtractor(url, "VoeSX ($quality)");
    } else if (containsVidBom(url)) {
      a = await MBridge.vidBomExtractor(url);
    }
    if (a.isNotEmpty) {
      videos.addAll(a);
    }
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
    return false;
  }
}

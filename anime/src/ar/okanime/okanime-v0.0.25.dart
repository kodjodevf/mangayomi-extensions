import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class OkAnime extends MProvider {
  OkAnime();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": source.baseUrl};
    final res = await http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = xpath(res,
        '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res,
        '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res,
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
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/espisode-list?page=$page"};
    final res = await http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="episode-image")]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage =
        xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    String url = "${source.baseUrl}/search/?s=$query";
    if (page > 1) {
      url += "&page=$page";
    }
    final data = {"url": url};
    final res = await http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res,
        '//*[contains(@class,"anime-card")]/div[@class="anime-image")]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage =
        xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"يعرض الان": 0, "مكتمل": 1}
    ];
    final data = {"url": url};
    final res = await http('GET', json.encode(data));
    MManga anime = MManga();
    final status = xpath(res,
        '//*[@class="full-list-info" and contains(text(),"حالة الأنمي")]/small/a/text()');
    if (status.isNotEmpty) {
      anime.status = parseStatus(status.first, statusList);
    }
    anime.description = xpath(res, '//*[@class="review-content"]/text()').first;

    anime.genre = xpath(res, '//*[@class="review-author-info"]/a/text()');
    final epUrls = xpath(res,
            '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/@href')
        .reversed
        .toList();
    final names = xpath(res,
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
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    final res = await http('GET', json.encode({"url": url}));

    final urls = xpath(res, '//*[@id="streamlinks"]/a/@data-src');
    final qualities = xpath(res, '//*[@id="streamlinks"]/a/span/text()');

    List<MVideo> videos = [];
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      final quality = getQuality(qualities[i]);
      List<MVideo> a = [];

      if (url.contains("https://doo")) {
        a = await doodExtractor(url, "DoodStream - $quality");
      } else if (url.contains("mp4upload")) {
        a = await mp4UploadExtractor(url, null, "", "");
      } else if (url.contains("ok.ru")) {
        a = await okruExtractor(url);
      } else if (url.contains("voe.sx")) {
        a = await voeExtractor(url, "VoeSX $quality");
      } else if (containsVidBom(url)) {
        a = await vidBomExtractor(url);
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
}

OkAnime main() {
  return OkAnime();
}

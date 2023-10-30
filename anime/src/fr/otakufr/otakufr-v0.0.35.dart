import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class OtakuFr extends MSourceProvider {
  OtakuFr();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final data = {
      "url": "${sourceInfo.baseUrl}/toute-la-liste-affiches/page/$page/?q=."
    };
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls =
        MBridge.xpath(res, '//*[@class="list"]/article/div/div/figure/a/@href');
    final names = MBridge.xpath(
        res, '//*[@class="list"]/article/div/div/figure/a/img/@title');
    final images = MBridge.xpath(
        res, '//*[@class="list"]/article/div/div/figure/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final data = {"url": "${sourceInfo.baseUrl}/page/$page/"};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res, '//*[@class="episode"]/div/a/@href');
    final namess = MBridge.xpath(res, '//*[@class="episode"]/div/a/text()');
    List<String> names = [];
    for (var name in namess) {
      names.add(MBridge.regExp(
              name,
              r'(?<=\bS\d\s*|)\d{2}\s*(?=\b(Vostfr|vostfr|VF|Vf|vf|\(VF\)|\(vf\)|\(Vf\)|\(Vostfr\)\b))?',
              '',
              0,
              0)
          .replaceAll(' vostfr', '')
          .replaceAll(' Vostfr', '')
          .replaceAll(' VF', '')
          .replaceAll(' Vf', '')
          .replaceAll(' vf', '')
          .replaceAll(' (VF)', '')
          .replaceAll(' (vf)', '')
          .replaceAll(' (vf)', '')
          .replaceAll(' (Vf)', '')
          .replaceAll(' (Vostfr)', ''));
    }
    final images =
        MBridge.xpath(res, '//*[@class="episode"]/div/figure/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final data = {
      "url":
          "${sourceInfo.baseUrl}/toute-la-liste-affiches/page/$page/?q=$query"
    };
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls =
        MBridge.xpath(res, '//*[@class="list"]/article/div/div/figure/a/@href');
    final names = MBridge.xpath(
        res, '//*[@class="list"]/article/div/div/figure/a/img/@title');
    final images = MBridge.xpath(
        res, '//*[@class="list"]/article/div/div/figure/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
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
    String res = await MBridge.http('GET', json.encode(data));
    MManga anime = MManga();
    final originalUrl = MBridge.xpath(res,
            '//*[@class="breadcrumb"]/li[@class="breadcrumb-item"][2]/a/@href')
        .first;
    if (originalUrl.isNotEmpty) {
      final newData = {"url": originalUrl};
      res = await MBridge.http('GET', json.encode(newData));
    }

    anime.description =
        MBridge.xpath(res, '//*[@class="episode fz-sm synop"]/p/text()')
            .first
            .replaceAll("Synopsis:", "");
    final status = MBridge.xpath(res,
            '//*[@class="list-unstyled"]/li[contains(text(),"Statut")]/text()')
        .first
        .replaceAll("Statut: ", "");
    anime.status = MBridge.parseStatus(status, statusList);
    anime.genre = MBridge.xpath(res,
        '//*[@class="list-unstyled"]/li[contains(text(),"Genre")]/ul/li/a/text()');

    final epUrls =
        MBridge.xpath(res, '//*[@class="list-episodes list-group"]/a/@href');
    final dates = MBridge.xpath(
        res, '//*[@class="list-episodes list-group"]/a/span/text()');
    final names =
        MBridge.xpath(res, '//*[@class="list-episodes list-group"]/a/text()');
    List<String> episodes = [];

    for (var i = 0; i < names.length; i++) {
      final date = dates[i];
      final name = names[i];
      episodes.add(
          "Episode ${MBridge.regExp(name.replaceAll(date, ""), r".* (\d*) [VvfF]{1,1}", '', 1, 1)}");
    }
    final dateUploads = MBridge.parseDates(dates, "dd MMMM yyyy", "fr");

    List<MChapter>? episodesList = [];
    for (var i = 0; i < episodes.length; i++) {
      MChapter episode = MChapter();
      episode.name = episodes[i];
      episode.url = epUrls[i];
      episode.dateUpload = dateUploads[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    final res = await MBridge.http('GET', json.encode({"url": url}));

    final servers =
        MBridge.xpath(res, '//*[@id="nav-tabContent"]/div/iframe/@src');
    List<MVideo> videos = [];
    for (var url in servers) {
      final datasServer = {
        "url": fixUrl(url),
        "headers": {"X-Requested-With": "XMLHttpRequest"}
      };

      final resServer = await MBridge.http('GET', json.encode(datasServer));
      final serverUrl =
          fixUrl(MBridge.regExp(resServer, r"data-url='([^']+)'", '', 1, 1));
      List<MVideo> a = [];
      if (serverUrl.contains("https://streamwish")) {
        a = await MBridge.streamWishExtractor(serverUrl, "StreamWish");
      } else if (serverUrl.contains("sibnet")) {
        a = await MBridge.sibnetExtractor(serverUrl);
      } else if (serverUrl.contains("https://doo")) {
        a = await MBridge.doodExtractor(serverUrl);
      } else if (serverUrl.contains("https://voe.sx")) {
        a = await MBridge.voeExtractor(serverUrl, null);
      } else if (serverUrl.contains("https://ok.ru")) {
        a = await MBridge.okruExtractor(serverUrl);
      }
      videos.addAll(a);
    }

    return videos;
  }

  String fixUrl(String url) {
    return MBridge.regExp(url, r"^(?:(?:https?:)?//|www\.)", 'https://', 0, 0);
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    return [];
  }
}

OtakuFr main() {
  return OtakuFr();
}

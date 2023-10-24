import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MManga anime) async {
  final data = {
    "url": "${anime.baseUrl}/toute-la-liste-affiches/page/${anime.page}/?q=."
  };
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls =
      MBridge.xpath(res, '//*[@class="list"]/article/div/div/figure/a/@href');
  anime.names = MBridge.xpath(
      res, '//*[@class="list"]/article/div/div/figure/a/img/@title');
  anime.images = MBridge.xpath(
      res, '//*[@class="list"]/article/div/div/figure/a/img/@src');
  final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

getLatestUpdatesAnime(MManga anime) async {
  final data = {"url": "${anime.baseUrl}/page/${anime.page}/"};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(res, '//*[@class="episode"]/div/a/@href');
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
  anime.names = names;
  anime.images =
      MBridge.xpath(res, '//*[@class="episode"]/div/figure/a/img/@src');
  final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
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
  String res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }

  final originalUrl = MBridge.xpath(res,
          '//*[@class="breadcrumb"]/li[@class="breadcrumb-item"][2]/a/@href')
      .first;
  if (originalUrl.isNotEmpty) {
    final newData = {"url": originalUrl};
    res = await MBridge.http('GET', json.encode(newData));
    if (res.isEmpty) {
      return anime;
    }
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

  anime.urls =
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
  anime.names = episodes;
  anime.chaptersDateUploads =
      MBridge.listParseDateTime(dates, "dd MMMM yyyy", "fr");
  return anime;
}

searchAnime(MManga anime) async {
  final data = {
    "url":
        "${anime.baseUrl}/toute-la-liste-affiches/page/${anime.page}/?q=${anime.query}"
  };
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }

  anime.urls =
      MBridge.xpath(res, '//*[@class="list"]/article/div/div/figure/a/@href');

  anime.names = MBridge.xpath(
      res, '//*[@class="list"]/article/div/div/figure/a/img/@title');
  anime.images = MBridge.xpath(
      res, '//*[@class="list"]/article/div/div/figure/a/img/@src');
  final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

getVideoList(MManga anime) async {
  final datas = {"url": anime.link};

  final res = await MBridge.http('GET', json.encode(datas));

  if (res.isEmpty) {
    return [];
  }
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
    for (var vi in a) {
      videos.add(vi);
    }
  }

  return videos;
}

String fixUrl(String url) {
  return MBridge.regExp(url, r"^(?:(?:https?:)?//|www\.)", 'https://', 0, 0);
}

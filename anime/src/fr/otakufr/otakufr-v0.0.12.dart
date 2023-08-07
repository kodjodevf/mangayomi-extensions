import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/toute-la-liste-affiches/page/${anime.page}/?q=.",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  anime.urls = MBridge.xpath(
          res, '//*[@class="list"]/article/div/div/figure/a/@href', '._.._.._')
      .split('._.._.._');

  anime.names = MBridge.xpath(res,
          '//*[@class="list"]/article/div/div/figure/a/img/@title', '._.._.._')
      .split('._.._.._');
  anime.images = MBridge.xpath(res,
          '//*[@class="list"]/article/div/div/figure/a/img/@src', '._.._.._')
      .split('._.._.._');
  final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href', '');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/page/${anime.page}/",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  anime.urls =
      MBridge.xpath(res, '//*[@class="episode"]/div/a/@href', '._.._.._')
          .split('._.._.._');
  List<String> namess =
      MBridge.xpath(res, '//*[@class="episode"]/div/a/text()', '._.._.._')
          .split('._.._.._');
  List<String> names = [];
  for (var name in MBridge.listParse(namess, 0)) {
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
  anime.images = MBridge.xpath(
          res,
          '//*[@class="episode"]/div/figure/a/img/@src',
          '._.._.._.._.._.._.._.._.._')
      .split('._.._.._.._.._.._.._.._.._');
  final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href', '');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
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

  final originalUrl = MBridge.xpath(res,
      '//*[@class="breadcrumb"]/li[@class="breadcrumb-item"][2]/a/@href', '');
  if (originalUrl.isEmpty) {
  } else {
    final newData = {"url": originalUrl, "headers": null};
    res = await MBridge.http(json.encode(newData), 0);
    if (res.isEmpty) {
      return anime;
    }
  }
  anime.description =
      MBridge.xpath(res, '//*[@class="episode fz-sm synop"]/p/text()', '')
          .replaceAll("Synopsis:", "");
  final status = MBridge.xpath(
          res,
          '//*[@class="list-unstyled"]/li[contains(text(),"Statut")]/text()',
          '')
      .replaceAll("Statut: ", "");
  anime.status = MBridge.parseStatus(status, statusList);
  anime.genre = MBridge.xpath(
          res,
          '//*[@class="list-unstyled"]/li[contains(text(),"Genre")]/ul/li/a/text()',
          '._.._.._')
      .split('._.._.._');

  anime.urls = MBridge.xpath(
          res, '//*[@class="list-episodes list-group"]/a/@href', '._.._.._')
      .split("._.._.._");
  List<String> dates = MBridge.xpath(res,
          '//*[@class="list-episodes list-group"]/a/span/text()', '._.._.._')
      .split("._.._.._");
  List<String> names = MBridge.xpath(
          res, '//*[@class="list-episodes list-group"]/a/text()', '._.._.._')
      .split("._.._.._");

  List<String> episodes = [];
  for (var i = 0; i < names.length; i++) {
    final date = MBridge.listParse(dates, 0)[i];
    final name = MBridge.listParse(names, 0)[i];
    episodes.add(
        "Episode ${MBridge.regExp(name.replaceAll(date, ""), r".* (\d*) [VvfF]{1,1}", '', 1, 1)}");
  }
  anime.names = episodes;
  anime.chaptersDateUploads = MBridge.listParse(
      MBridge.listParseDateTime(dates, "dd MMMM yyyy", "fr"), 0);
  return anime;
}

searchAnime(MangaModel anime) async {
  final data = {
    "url":
        "${anime.baseUrl}/toute-la-liste-affiches/page/${anime.page}/?q=${anime.query}",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  anime.urls = MBridge.xpath(
          res, '//*[@class="list"]/article/div/div/figure/a/@href', '._.._.._')
      .split('._.._.._');

  anime.names = MBridge.xpath(res,
          '//*[@class="list"]/article/div/div/figure/a/img/@title', '._.._.._')
      .split('._.._.._');
  anime.images = MBridge.xpath(res,
          '//*[@class="list"]/article/div/div/figure/a/img/@src', '._.._.._')
      .split('._.._.._');
  final nextPage = MBridge.xpath(res, '//a[@class="next page-link"]/@href', '');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

getVideoList(MangaModel anime) async {
  final datas = {
    "url": anime.link,
    "headers": null,
    "sourceId": anime.sourceId
  };

  final res = await MBridge.http(json.encode(datas), 0);

  if (res.isEmpty) {
    return [];
  }
  final servers =
      MBridge.xpath(res, '//*[@id="nav-tabContent"]/div/iframe/@src', ".-")
          .split(".-");
  List<VideoModel> videos = [];
  for (var url in MBridge.listParse(servers, 0)) {
    final datasServer = {
      "url": fixUrl(url),
      "headers": {"X-Requested-With": "XMLHttpRequest"},
      "sourceId": anime.sourceId
    };

    final resServer = await MBridge.http(json.encode(datasServer), 0);
    final serverUrl =
        fixUrl(MBridge.regExp(resServer, r"data-url='([^']+)'", '', 1, 1));
    List<VideoModel> a = [];
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

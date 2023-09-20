import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularManga(MangaModel manga) async {
  final url =
      "${manga.baseUrl}/browse?${lang(manga.lang)}&sort=views_a&page=${manga.page}";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  return mangaElementM(res, manga);
}

String lang(String lang) {
  lang = lang.replaceAll("-", "_");
  if (lang == "all") {
    return "";
  }
  return "langs=$lang";
}

getLatestUpdatesManga(MangaModel manga) async {
  final url =
      "${manga.baseUrl}/browse?${lang(manga.lang)}&sort=update&page=${manga.page}";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  return mangaElementM(res, manga);
}

searchManga(MangaModel manga) async {
  final data = {
    "url": "${manga.baseUrl}/search?word=${manga.query}&page=${manga.page}",
    "headers": null,
    "sourceId": manga.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  return mangaElementM(res, manga);
}

getMangaDetail(MangaModel manga) async {
  final statusList = [
    {
      "Ongoing": 0,
      "Completed": 1,
      "Cancelled": 3,
      "Hiatus": 2,
    }
  ];

  final url = "${manga.baseUrl}${manga.link}";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);

  if (res.isEmpty) {
    return manga;
  }

  final workStatus = MBridge.xpath(
      res,
      '//*[@class="attr-item"]/b[contains(text(),"Original work")]/following-sibling::span[1]/text()',
      '');
  manga.status = MBridge.parseStatus(workStatus, statusList);

  manga.author = MBridge.xpath(
      res,
      '//*[@class="attr-item"]/b[contains(text(),"Authors")]/following-sibling::span[1]/text()',
      '');
  manga.genre = MBridge.xpath(
          res,
          '//*[@class="attr-item"]/b[contains(text(),"Genres")]/following-sibling::span[1]/text()',
          '')
      .split(",");
  manga.description = MBridge.xpath(res, '//*[@class="limit-html"]/text()', '');

  List<String> chapsElement =
      MBridge.querySelectorAll(res, "div.main div.p-2", 2, "", 0, 0, '-.')
          .split('-.');
  List<String> times = [];
  List<String> chapsUrls = [];
  List<String> chapsNames = [];
  List<String> scanlators = [];
  for (var element in MBridge.listParse(chapsElement, 0)) {
    final urlElement = MBridge.querySelector(element, "a.chapt", 2, "");
    final group = MBridge.xpath(element, '//*[@class="extra"]/a/text()', '');
    final name = MBridge.xpath(urlElement, '//a/text()', '');
    final url = MBridge.xpath(urlElement, '//a/@href', '');
    final time = MBridge.xpath(
        element, '//*[@class="extra"]/i[@class="ps-3"]/text()', '');
    times.add(time);
    chapsUrls.add(url);
    scanlators.add(group);
    chapsNames.add(name.replaceAll("\n ", "").replaceAll("  ", ""));
  }

  manga.urls = chapsUrls;
  manga.names = chapsNames;
  manga.chaptersScanlators = scanlators;
  manga.chaptersDateUploads = MBridge.listParse(
      MBridge.listParseDateTime(times, "MMM dd,yyyy", "en"), 0);

  return manga;
}

getChapterUrl(MangaModel manga) async {
  final datas = {
    "url": "${manga.baseUrl}${manga.link}",
    "headers": null,
    "sourceId": manga.sourceId
  };
  final res = await MBridge.http(json.encode(datas), 0);
  if (res.isEmpty) {
    return [];
  }
  final script = MBridge.xpath(
      res,
      '//script[contains(text(), "imgHttpLis") and contains(text(), "batoWord") and contains(text(), "batoPass")]/text()',
      "");
  final imgHttpLisString = MBridge.subString(
      MBridge.subString(script, 'const imgHttpLis =', 2), ';', 0);
  List<String> imgHttpLis = MBridge.jsonDecodeToList(imgHttpLisString, 0);
  final batoWord = MBridge.subString(
      MBridge.subString(script, 'const batoWord =', 2), ';', 0);
  final batoPass = MBridge.subString(
      MBridge.subString(script, 'const batoPass =', 2), ';', 0);
  final evaluatedPass = MBridge.deobfuscateJsPassword(batoPass);
  final imgAccListString =
      MBridge.decryptAESCryptoJS(batoWord.replaceAll('"', ""), evaluatedPass);
  List<String> imgAccList = MBridge.jsonDecodeToList(imgAccListString, 0);
  List<String> pagesUrl = [];
  for (int i = 0; i < imgHttpLis.length; i++) {
    final imgUrl = MBridge.listParse(imgHttpLis, 0)[i];
    final imgAcc = MBridge.listParse(imgAccList, 0)[i];
    pagesUrl.add("$imgUrl?$imgAcc");
  }

  return pagesUrl;
}

MangaModel mangaElementM(String res, MangaModel manga) async {
  if (res.isEmpty) {
    return manga;
  }
  final lang = manga.lang.replaceAll("-", "_");
  List<String> resB = MBridge.querySelectorAll(
          res, "div#series-list div.col", 2, "", 0, 0, '-.')
      .split('-.');
  List<String> images = [];
  List<String> urls = [];
  List<String> names = [];

  for (var element in MBridge.listParse(resB, 0)) {
    if (manga.lang == "all") {
      final item = MBridge.querySelector(element, "a.item-cover", 2, "");
      final img = MBridge.querySelector(item, "img", 3, "src");
      final url = MBridge.querySelector(item, "a", 3, "href");
      images.add(img);
      urls.add(url);
      final title = MBridge.querySelector(element, "a.item-title", 0, "");
      names.add(title);
    } else if (manga.lang == "en") {
      if (element.contains('no-flag')) {
        final item = MBridge.querySelector(element, "a.item-cover", 2, "");
        final img = MBridge.querySelector(item, "img", 3, "src");
        final url = MBridge.querySelector(item, "a", 3, "href");
        images.add(img);
        urls.add(url);
        final title = MBridge.querySelector(element, "a.item-title", 0, "");
        names.add(title);
      }
    } else {
      if (element.contains('data-lang="$lang"')) {
        final item = MBridge.querySelector(element, "a.item-cover", 2, "");
        final img = MBridge.querySelector(item, "img", 3, "src");
        final url = MBridge.querySelector(item, "a", 3, "href");
        images.add(img);
        urls.add(url);
        final title = MBridge.querySelector(element, "a.item-title", 0, "");
        names.add(title);
      }
    }
  }
  manga.urls = urls;
  manga.names = names;
  manga.images = images;
  final nextPage = MBridge.xpath(
      res,
      '//li[@class="page-item disabled"]/a/span[contains(text(),"»")]/text()',
      "");
  if (nextPage.isEmpty) {
    manga.hasNextPage = true;
  } else {
    manga.hasNextPage = false;
  }
  return manga;
}

Map<String, String> getMirrorPref() {
  return {
    "bato.to": "https://bato.to",
    "batocomic.com": "https://batocomic.com",
    "batocomic.net": "https://batocomic.net",
    "batocomic.org": "https://batocomic.org",
    "batotoo.com": "https://batotoo.com",
    "batotwo.com": "https://batotwo.com",
    "battwo.com": "https://battwo.com",
    "comiko.net": "https://comiko.net",
    "comiko.org": "https://comiko.org",
    "mangatoto.com": "https://mangatoto.com",
    "mangatoto.net": "https://mangatoto.net",
    "mangatoto.org": "https://mangatoto.org",
    "readtoto.com": "https://readtoto.com",
    "readtoto.net": "https://readtoto.net",
    "readtoto.org": "https://readtoto.org",
    "dto.to": "https://dto.to",
    "hto.to": "https://hto.to",
    "mto.to": "https://mto.to",
    "wto.to": "https://wto.to",
    "xbato.com": "https://xbato.com",
    "xbato.net": "https://xbato.net",
    "xbato.org": "https://xbato.org",
    "zbato.com": "https://zbato.com",
    "zbato.net": "https://zbato.net",
    "zbato.org": "https://zbato.org",
  };
}

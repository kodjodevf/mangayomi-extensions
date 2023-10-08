import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/browse?${lang(manga.lang)}&sort=views_a&page=${manga.page}";
  final data = {"url": url, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(data));
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
  final url = "${manga.baseUrl}/browse?${lang(manga.lang)}&sort=update&page=${manga.page}";
  final data = {"url": url, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(data));
  return mangaElementM(res, manga);
}

searchManga(MangaModel manga) async {
  final data = {"url": "${manga.baseUrl}/search?word=${manga.query}&page=${manga.page}", "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(data));
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
  final data = {"url": url, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(data));

  if (res.isEmpty) {
    return manga;
  }

  final workStatus = MBridge.xpath(
          res, '//*[@class="attr-item"]/b[contains(text(),"Original work")]/following-sibling::span[1]/text()')
      .first;
  manga.status = MBridge.parseStatus(workStatus, statusList);

  manga.author =
      MBridge.xpath(res, '//*[@class="attr-item"]/b[contains(text(),"Authors")]/following-sibling::span[1]/text()')
          .first;
  manga.genre =
      MBridge.xpath(res, '//*[@class="attr-item"]/b[contains(text(),"Genres")]/following-sibling::span[1]/text()')
          .first
          .split(",");
  manga.description = MBridge.xpath(res, '//*[@class="limit-html"]/text()').first;

  List<String> chapsElement =
      MBridge.querySelectorAll(res, selector: "div.main div.p-2", typeElement: 2, attributes: "", typeRegExp: 0);
  List<String> times = [];
  List<String> chapsUrls = [];
  List<String> chapsNames = [];
  List<String> scanlators = [];
  for (var element in chapsElement) {
    final urlElement =
        MBridge.querySelectorAll(element, selector: "a.chapt", typeElement: 2, attributes: "", typeRegExp: 0).first;
    final group = MBridge.xpath(element, '//*[@class="extra"]/a/text()').first;
    final name = MBridge.xpath(urlElement, '//a/text()').first;
    final url = MBridge.xpath(urlElement, '//a/@href').first;
    final time = MBridge.xpath(element, '//*[@class="extra"]/i[@class="ps-3"]/text()').first;
    times.add(time);
    chapsUrls.add(url);
    scanlators.add(group);
    chapsNames.add(name.replaceAll("\n ", "").replaceAll("  ", ""));
  }

  manga.urls = chapsUrls;
  manga.names = chapsNames;
  manga.chaptersScanlators = scanlators;
  manga.chaptersDateUploads = MBridge.listParseDateTime(times, "MMM dd,yyyy", "en");

  return manga;
}

getChapterUrl(MangaModel manga) async {
  final datas = {"url": "${manga.baseUrl}${manga.link}", "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(datas));
  if (res.isEmpty) {
    return [];
  }
  final script = MBridge.xpath(res,
          '//script[contains(text(), "imgHttpLis") and contains(text(), "batoWord") and contains(text(), "batoPass")]/text()')
      .first;
  final imgHttpLisString = MBridge.substringBefore(MBridge.substringAfterLast(script, 'const imgHttpLis ='), ';');
  var imgHttpLis = json.decode(imgHttpLisString);
  final batoWord = MBridge.substringBefore(MBridge.substringAfterLast(script, 'const batoWord ='), ';');
  final batoPass = MBridge.substringBefore(MBridge.substringAfterLast(script, 'const batoPass ='), ';');
  final evaluatedPass = MBridge.deobfuscateJsPassword(batoPass);
  final imgAccListString = MBridge.decryptAESCryptoJS(batoWord.replaceAll('"', ""), evaluatedPass);
  var imgAccList = json.decode(imgAccListString);
  List<String> pagesUrl = [];
  for (int i = 0; i < imgHttpLis.length; i++) {
    String imgUrl = imgHttpLis[i];
    String imgAcc = imgAccList[i];
    pagesUrl.add("$imgUrl?$imgAcc");
  }

  return pagesUrl;
}

MangaModel mangaElementM(String res, MangaModel manga) async {
  if (res.isEmpty) {
    return manga;
  }
  final lang = manga.lang.replaceAll("-", "_");
  var resB =
      MBridge.querySelectorAll(res, selector: "div#series-list div.col", typeElement: 2, attributes: "", typeRegExp: 0);
  List<String> images = [];
  List<String> urls = [];
  List<String> names = [];

  for (var element in resB) {
    if (manga.lang == "all" ||
        manga.lang == "en" && element.contains('no-flag') ||
        element.contains('data-lang="$lang"')) {
      final item =
          MBridge.querySelectorAll(element, selector: "a.item-cover", typeElement: 2, attributes: "", typeRegExp: 0)
              .first;
      final img =
          MBridge.querySelectorAll(item, selector: "img", typeElement: 3, attributes: "src", typeRegExp: 0).first;
      final url =
          MBridge.querySelectorAll(item, selector: "a", typeElement: 3, attributes: "href", typeRegExp: 0).first;
      images.add(img);
      urls.add(url);
      final title =
          MBridge.querySelectorAll(element, selector: "a.item-title", typeElement: 0, attributes: "", typeRegExp: 0)
              .first;
      names.add(title);
    }
  }
  manga.urls = urls;
  manga.names = names;
  manga.images = images;
  final nextPage = MBridge.xpath(res, '//li[@class="page-item disabled"]/a/span[contains(text(),"»")]/text()').first;
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

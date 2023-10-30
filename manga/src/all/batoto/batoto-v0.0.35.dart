import 'package:mangayomi/bridge_lib.dart';
import 'package:mangayomi/utils.dart';
import 'dart:convert';

class Batoto extends MSourceProvider {
  Batoto();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final url =
        "${sourceInfo.baseUrl}/browse?${lang(sourceInfo.lang)}&sort=views_a&page=$page";
    final data = {"url": url};
    final res = await MBridge.http('GET', json.encode(data));
    return mangaElementM(res, sourceInfo);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final url =
        "${sourceInfo.baseUrl}/browse?${lang(sourceInfo.lang)}&sort=update&page=$page";
    final data = {"url": url};
    final res = await MBridge.http('GET', json.encode(data));
    return mangaElementM(res, sourceInfo);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final url = "${sourceInfo.baseUrl}/search?word=$query&page=$page";
    final data = {"url": url};
    final res = await MBridge.http('GET', json.encode(data));
    return mangaElementM(res, sourceInfo);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1, "Cancelled": 3, "Hiatus": 2}
    ];

    final data = {"url": "${sourceInfo.baseUrl}$url"};
    final res = await MBridge.http('GET', json.encode(data));
    MManga manga = MManga();
    final workStatus = MBridge.xpath(res,
            '//*[@class="attr-item"]/b[contains(text(),"Original work")]/following-sibling::span[1]/text()')
        .first;
    manga.status = MBridge.parseStatus(workStatus, statusList);

    manga.author = MBridge.xpath(res,
            '//*[@class="attr-item"]/b[contains(text(),"Authors")]/following-sibling::span[1]/text()')
        .first;
    manga.genre = MBridge.xpath(res,
            '//*[@class="attr-item"]/b[contains(text(),"Genres")]/following-sibling::span[1]/text()')
        .first
        .split(",");
    manga.description =
        MBridge.xpath(res, '//*[@class="limit-html"]/text()').first;

    List<String> chapsElement = MBridge.querySelectorAll(res,
        selector: "div.main div.p-2",
        typeElement: 2,
        attributes: "",
        typeRegExp: 0);
    List<String> times = [];
    List<String> chapsUrls = [];
    List<String> chapsNames = [];
    List<String> scanlators = [];
    for (var element in chapsElement) {
      final urlElement = MBridge.querySelectorAll(element,
              selector: "a.chapt",
              typeElement: 2,
              attributes: "",
              typeRegExp: 0)
          .first;
      final group =
          MBridge.xpath(element, '//*[@class="extra"]/a/text()').first;
      final name = MBridge.xpath(urlElement, '//a/text()').first;
      final url = MBridge.xpath(urlElement, '//a/@href').first;
      final time =
          MBridge.xpath(element, '//*[@class="extra"]/i[@class="ps-3"]/text()')
              .first;
      times.add(time);
      chapsUrls.add(url);
      scanlators.add(group);
      chapsNames.add(name.replaceAll("\n ", "").replaceAll("  ", ""));
    }
    var dateUploads = MBridge.parseDates(
        times, sourceInfo.dateFormat, sourceInfo.dateFormatLocale);
    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chapsNames.length; i++) {
      MChapter chapter = MChapter();
      chapter.name = chapsNames[i];
      chapter.url = chapsUrls[i];
      chapter.scanlator = scanlators[i];
      chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    final datas = {"url": "${sourceInfo.baseUrl}$url"};
    final res = await MBridge.http('GET', json.encode(datas));

    final script = MBridge.xpath(res,
            '//script[contains(text(), "imgHttpLis") and contains(text(), "batoWord") and contains(text(), "batoPass")]/text()')
        .first;
    final imgHttpLisString = Substring(script)
        .substringAfterLast('const imgHttpLis =')
        .substringBefore(';')
        .text;
    var imgHttpLis = json.decode(imgHttpLisString);
    final batoWord = Substring(script)
        .substringAfterLast('const batoWord =')
        .substringBefore(';')
        .text;
    final batoPass = Substring(script)
        .substringAfterLast('const batoPass =')
        .substringBefore(';')
        .text;
    final evaluatedPass = MBridge.deobfuscateJsPassword(batoPass);
    final imgAccListString =
        MBridge.decryptAESCryptoJS(batoWord.replaceAll('"', ""), evaluatedPass);
    var imgAccList = json.decode(imgAccListString);
    List<String> pagesUrl = [];
    for (int i = 0; i < imgHttpLis.length; i++) {
      String imgUrl = imgHttpLis[i];
      String imgAcc = imgAccList[i];
      pagesUrl.add("$imgUrl?$imgAcc");
    }

    return pagesUrl;
  }

  MPages mangaElementM(String res, MSource sourceInfo) async {
    final lang = sourceInfo.lang.replaceAll("-", "_");

    var resB = MBridge.querySelectorAll(res,
        selector: "div#series-list div.col",
        typeElement: 2,
        attributes: "",
        typeRegExp: 0);

    List<String> images = [];
    List<String> urls = [];
    List<String> names = [];

    for (var element in resB) {
      if (sourceInfo.lang == "all" ||
          sourceInfo.lang == "en" && element.contains('no-flag') ||
          element.contains('data-lang="$lang"')) {
        final item = MBridge.querySelectorAll(element,
                selector: "a.item-cover",
                typeElement: 2,
                attributes: "",
                typeRegExp: 0)
            .first;
        final img = MBridge.querySelectorAll(item,
                selector: "img",
                typeElement: 3,
                attributes: "src",
                typeRegExp: 0)
            .first;
        final url = MBridge.querySelectorAll(item,
                selector: "a",
                typeElement: 3,
                attributes: "href",
                typeRegExp: 0)
            .first;
        images.add(img);
        urls.add(url);
        final title = MBridge.querySelectorAll(element,
                selector: "a.item-title",
                typeElement: 0,
                attributes: "",
                typeRegExp: 0)
            .first;
        names.add(title);
      }
    }
    List<MManga> mangaList = [];

    for (var i = 0; i < urls.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  String lang(String lang) {
    lang = lang.replaceAll("-", "_");
    if (lang == "all") {
      return "";
    }
    return "langs=$lang";
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    return [];
  }
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

Batoto main() {
  return Batoto();
}

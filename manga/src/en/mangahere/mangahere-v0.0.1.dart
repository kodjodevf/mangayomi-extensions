import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

searchManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.baseUrl}/search?title=${manga.query}&page=${manga.page}";

  final data = {"url": url, "headers": headers};
  final res = await MBridge.http(json.encode(data), 1);
  if (res.isEmpty) {
    return manga;
  }

  manga.names = MBridge.xpath(
          res, '//*[contains(@class, "manga-list-4-list")]/li/a/@title', '-.')
      .split('-.');
  manga.images = MBridge.xpath(
          res,
          '//*[contains(@class, "manga-list-4-list")]/li/a/img[@class="manga-list-4-cover"]/@src',
          '-.')
      .split('-.');
  manga.urls = MBridge.xpath(
          res, '//*[contains(@class, "manga-list-4-list")]/li/a/@href', '-.')
      .split('-.');
  return manga;
}

getLatestUpdatesManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.baseUrl}/directory/${manga.page}.htm?latest";

  final data = {"url": url, "headers": headers};
  final res = await MBridge.http(json.encode(data), 1);
  if (res.isEmpty) {
    return manga;
  }

  manga.names = MBridge.xpath(
          res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@title', '-.')
      .split('-.');
  manga.images = MBridge.xpath(
          res,
          '//*[ contains(@class, "manga-list-1-list")]/li/a/img[@class="manga-list-1-cover"]/@src',
          '-.')
      .split('-.');
  manga.urls = MBridge.xpath(
          res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@href', '-.')
      .split('-.');
  return manga;
}

getMangaDetail(MangaModel manga) async {
  final statusList = [
    {
      "Ongoing": 0,
      "Completed": 1,
    }
  ];
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.baseUrl}/${manga.link}";
  final data = {"url": url, "headers": headers};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.author =
      MBridge.xpath(res, '//*[@class="detail-info-right-say"]/a/text()', '');
  manga.description =
      MBridge.xpath(res, '//*[@class="fullcontent"]/text()', '');
  final status = MBridge.xpath(
      res, '//*[@class="detail-info-right-title-tip"]/text()', '');
  manga.status = MBridge.parseStatus(status, statusList);
  manga.genre = MBridge.xpath(
          res, '//*[@class="detail-info-right-tag-list"]/a/text()', '._')
      .split("._");
  manga.urls =
      MBridge.xpath(res, '//*[@class="detail-main-list"]/li/a/@href', '._')
          .split("._");
  manga.names = MBridge.xpath(
          res,
          '//*[@class="detail-main-list"]/li/a/div/p[@class="title3"]/text()',
          '._')
      .split("._");
  final chapterDates = MBridge.xpath(
          res,
          '//*[@class="detail-main-list"]/li/a/div/p[@class="title2"]/text()',
          '._')
      .split("._");

  manga.chaptersDateUploads = MBridge.listParse(
      MBridge.listParseDateTime(
          chapterDates, manga.dateFormat, manga.dateFormatLocale),
      0);
  return manga;
}

getPopularManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.baseUrl}/directory/${manga.page}.htm";

  final data = {"url": url, "headers": headers};
  final res = await MBridge.http(json.encode(data), 1);
  if (res.isEmpty) {
    return manga;
  }

  manga.names = MBridge.xpath(
          res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@title', '-.')
      .split('-.');
  manga.images = MBridge.xpath(
          res,
          '//*[ contains(@class, "manga-list-1-list")]/li/a/img[@class="manga-list-1-cover"]/@src',
          '-.')
      .split('-.');
  manga.urls = MBridge.xpath(
          res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@href', '-.')
      .split('-.');
  return manga;
}

getChapterUrl(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.baseUrl}${manga.link}";
  final data = {"url": url, "headers": headers};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return [];
  }
  final pages = MBridge.xpath(res, "//body/div/div/span/a/text()", "._");
  List<String> pageUrls = [];
  if (pages.isEmpty) {
    final script = MBridge.xpath(res,
            "//script[contains(text(),'function(p,a,c,k,e,d)')]/text()", "")
        .replaceAll("eval", "");
    String deobfuscatedScript = MBridge.evalJs(script);
    int a = deobfuscatedScript.indexOf("newImgs=['") + 10;
    int b = deobfuscatedScript.indexOf("'];");
    List<String> urls =
        MBridge.listParse(deobfuscatedScript.substring(a, b).split("','"), 0);
    for (var url in urls) {
      pageUrls.add("https:$url");
    }
  } else {
    final pagesNumberList = MBridge.listParse(pages.split("._"), 0);
    //manga.status objext is used to parse pagesNumber value to int
    manga.status =
        MBridge.intParse(pagesNumberList[pagesNumberList.length - 2]);
    int secretKeyScriptLocation = res.indexOf("eval(function(p,a,c,k,e,d)");
    int secretKeyScriptEndLocation =
        res.indexOf("</script>", secretKeyScriptLocation);
    String secretKeyScript = res
        .substring(secretKeyScriptLocation, secretKeyScriptEndLocation)
        .replaceAll("eval", "");
    String secretKeyDeobfuscatedScript = MBridge.evalJs(secretKeyScript);
    int secretKeyStartLoc = secretKeyDeobfuscatedScript.indexOf("'");
    int secretKeyEndLoc = secretKeyDeobfuscatedScript.indexOf(";");

    String secretKey = secretKeyDeobfuscatedScript.substring(
        secretKeyStartLoc, secretKeyEndLoc);
    int chapterIdStartLoc = res.indexOf("chapterid");
    String chapterId = res.substring(
        chapterIdStartLoc + 11, res.indexOf(";", chapterIdStartLoc));
    String pageBase = url.substring(0, url.lastIndexOf("/"));
    for (int i = 1; i <= manga.status; i++) {
      String pageLink =
          "$pageBase/chapterfun.ashx?cid=$chapterId&page=$i&key=$secretKey";
      String responseText = MBridge.stringParse("");
      for (int tr = 1; tr <= 3; tr++) {
        if (responseText.isEmpty) {
          final headers = {
            "Referer": url,
            "Accept": "*/*",
            "Accept-Language": "en-US,en;q=0.9",
            "Connection": "keep-alive",
            "Host": "www.mangahere.cc",
            "X-Requested-With": "XMLHttpRequest"
          };
          final data = {"url": pageLink, "headers": headers};
          final response = await MBridge.http(json.encode(data), 0);
          responseText = MBridge.stringParse(response);

          if (responseText.isEmpty) {
            secretKey = "";
          }
        }
      }
      String deobfuscatedScript =
          MBridge.evalJs(responseText.replaceAll("eval", ""));

      int baseLinkStartPos = deobfuscatedScript.indexOf("pix=") + 5;
      int baseLinkEndPos =
          deobfuscatedScript.indexOf(";", baseLinkStartPos) - 1;
      String baseLink =
          deobfuscatedScript.substring(baseLinkStartPos, baseLinkEndPos);

      int imageLinkStartPos = deobfuscatedScript.indexOf("pvalue=") + 9;
      int imageLinkEndPos = deobfuscatedScript.indexOf("\"", imageLinkStartPos);
      String imageLink =
          deobfuscatedScript.substring(imageLinkStartPos, imageLinkEndPos);
      pageUrls.add("https:$baseLink$imageLink");
    }
  }

  return pageUrls;
}

Map<String, String> getHeader(String url) {
  final headers = {'Referer': '$url/', "Cookie": "isAdult=1"};
  return headers;
}

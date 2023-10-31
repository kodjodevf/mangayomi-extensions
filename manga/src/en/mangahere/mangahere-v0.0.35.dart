import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaHere extends MProvider {
  MangaHere();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final headers = getHeader(source.baseUrl);
    final url = "${source.baseUrl}/directory/$page.htm";

    final data = {"url": url, "headers": headers};
    final res = await http('POST', json.encode(data));

    List<MManga> mangaList = [];
    final names = xpath(
        res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@title');
    final images = xpath(res,
        '//*[ contains(@class, "manga-list-1-list")]/li/a/img[@class="manga-list-1-cover"]/@src');
    final urls = xpath(
        res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@href');

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final headers = getHeader(source.baseUrl);
    final url = "${source.baseUrl}/directory/$page.htm?latest";

    final data = {"url": url, "headers": headers};
    final res = await http('POST', json.encode(data));

    List<MManga> mangaList = [];
    final names = xpath(
        res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@title');
    final images = xpath(res,
        '//*[ contains(@class, "manga-list-1-list")]/li/a/img[@class="manga-list-1-cover"]/@src');
    final urls = xpath(
        res, '//*[ contains(@class, "manga-list-1-list")]/li/a/@href');

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    final headers = getHeader(source.baseUrl);
    final url = "${source.baseUrl}/search?title=$query&page=$page";

    final data = {"url": url, "headers": headers};
    final res = await http('POST', json.encode(data));

    List<MManga> mangaList = [];
    final names = xpath(
        res, '//*[contains(@class, "manga-list-4-list")]/li/a/@title');
    final images = xpath(res,
        '//*[contains(@class, "manga-list-4-list")]/li/a/img[@class="manga-list-4-cover"]/@src');
    final urls = xpath(
        res, '//*[contains(@class, "manga-list-4-list")]/li/a/@href');

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1}
    ];
    final headers = getHeader(source.baseUrl);
    final data = {"url": "${source.baseUrl}/$url", "headers": headers};
    final res = await http('GET', json.encode(data));
    MManga manga = MManga();
    manga.author =
        xpath(res, '//*[@class="detail-info-right-say"]/a/text()')
            .first;
    manga.description =
        xpath(res, '//*[@class="fullcontent"]/text()').first;
    final status =
        xpath(res, '//*[@class="detail-info-right-title-tip"]/text()')
            .first;
    manga.status = parseStatus(status, statusList);
    manga.genre =
        xpath(res, '//*[@class="detail-info-right-tag-list"]/a/text()');

    var chapUrls =
        xpath(res, '//*[@class="detail-main-list"]/li/a/@href');
    var chaptersNames = xpath(res,
        '//*[@class="detail-main-list"]/li/a/div/p[@class="title3"]/text()');
    final chapterDates = xpath(res,
        '//*[@class="detail-main-list"]/li/a/div/p[@class="title2"]/text()');
    var dateUploads = parseDates(
        chapterDates, source.dateFormat, source.dateFormatLocale);

    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chaptersNames.length; i++) {
      MChapter chapter = MChapter();
      chapter.name = chaptersNames[i];
      chapter.url = chapUrls[i];
      chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource source, String url) async {
    final headers = getHeader(source.baseUrl);
    final urll = "${source.baseUrl}$url";
    final data = {"url": urll, "headers": headers};
    final res = await http('GET', json.encode(data));
    final pages = xpath(res, "//body/div/div/span/a/text()");
    List<String> pageUrls = [];
    if (pages.isEmpty) {
      final script = xpath(
              res, "//script[contains(text(),'function(p,a,c,k,e,d)')]/text()")
          .first
          .replaceAll("eval", "");
      String deobfuscatedScript = evalJs(script);
      int a = deobfuscatedScript.indexOf("newImgs=['") + 10;
      int b = deobfuscatedScript.indexOf("'];");
      List<String> urls = deobfuscatedScript.substring(a, b).split("','");
      for (var url in urls) {
        pageUrls.add("https:$url");
      }
    } else {
      final pagesNumberList = pages;
      int pagesNumber = int.parse(pagesNumberList[pagesNumberList.length - 2]);
      int secretKeyScriptLocation = res.indexOf("eval(function(p,a,c,k,e,d)");
      int secretKeyScriptEndLocation =
          res.indexOf("</script>", secretKeyScriptLocation);
      String secretKeyScript = res
          .substring(secretKeyScriptLocation, secretKeyScriptEndLocation)
          .replaceAll("eval", "");
      String secretKeyDeobfuscatedScript = evalJs(secretKeyScript);
      int secretKeyStartLoc = secretKeyDeobfuscatedScript.indexOf("'");
      int secretKeyEndLoc = secretKeyDeobfuscatedScript.indexOf(";");

      String secretKey = secretKeyDeobfuscatedScript.substring(
          secretKeyStartLoc, secretKeyEndLoc);
      int chapterIdStartLoc = res.indexOf("chapterid");
      String chapterId = res.substring(
          chapterIdStartLoc + 11, res.indexOf(";", chapterIdStartLoc));
      String pageBase = urll.substring(0, urll.lastIndexOf("/"));
      for (int i = 1; i <= pagesNumber; i++) {
        String pageLink =
            "$pageBase/chapterfun.ashx?cid=$chapterId&page=$i&key=$secretKey";
        String responseText = "".toString();
        for (int tr = 1; tr <= 3; tr++) {
          if (responseText.isEmpty) {
            final headers = {
              "Referer": urll,
              "Accept": "*/*",
              "Accept-Language": "en-US,en;q=0.9",
              "Connection": "keep-alive",
              "Host": "www.mangahere.cc",
              "X-Requested-With": "XMLHttpRequest"
            };
            final data = {"url": pageLink, "headers": headers};
            final ress = await http('GET', json.encode(data));

            responseText = ress;

            if (responseText.isEmpty) {
              secretKey = "";
            }
          }
        }
        String deobfuscatedScript =
            evalJs(responseText.replaceAll("eval", ""));

        int baseLinkStartPos = deobfuscatedScript.indexOf("pix=") + 5;
        int baseLinkEndPos =
            deobfuscatedScript.indexOf(";", baseLinkStartPos) - 1;
        String baseLink =
            deobfuscatedScript.substring(baseLinkStartPos, baseLinkEndPos);

        int imageLinkStartPos = deobfuscatedScript.indexOf("pvalue=") + 9;
        int imageLinkEndPos =
            deobfuscatedScript.indexOf("\"", imageLinkStartPos);
        String imageLink =
            deobfuscatedScript.substring(imageLinkStartPos, imageLinkEndPos);
        pageUrls.add("https:$baseLink$imageLink");
      }
    }

    return pageUrls;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    return [];
  }
}

Map<String, String> getHeader(String url) {
  final headers = {'Referer': '$url/', "Cookie": "isAdult=1"};
  return headers;
}

MangaHere main() {
  return MangaHere();
}

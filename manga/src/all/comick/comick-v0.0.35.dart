import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class ComickFun extends MSourceProvider {
  ComickFun();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final url =
        "${sourceInfo.apiUrl}/v1.0/search?sort=follow&page=$page&tachiyomi=true";
    final data = {"url": url, "headers": getHeader(sourceInfo.baseUrl)};
    final res = await MBridge.http('GET', json.encode(data));
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final url =
        "${sourceInfo.apiUrl}/v1.0/search?sort=uploaded&page=$page&tachiyomi=true";
    final data = {"url": url, "headers": getHeader(sourceInfo.baseUrl)};
    final res = await MBridge.http('GET', json.encode(data));
    return mangaRes(res);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final url = "${sourceInfo.apiUrl}/v1.0/search?q=$query&tachiyomi=true";
    final data = {"url": url, "headers": getHeader(sourceInfo.baseUrl)};
    final res = await MBridge.http('GET', json.encode(data));
    return mangaRes(res);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {"1": 0, "2": 1, "3": 3, "4": 2}
    ];

    final headers = getHeader(sourceInfo.baseUrl);

    final urll =
        "${sourceInfo.apiUrl}${url.replaceAll("#", '')}?tachiyomi=true";
    final data = {"url": urll, "headers": headers};
    final res = await MBridge.http('GET', json.encode(data));
    MManga manga = MManga();
    manga.author = MBridge.jsonPathToString(res, r'$.authors[*].name', '');
    manga.genre =
        MBridge.jsonPathToString(res, r'$.genres[*].name', "_.").split("_.");
    manga.description = MBridge.jsonPathToString(res, r'$..desc', '');
    manga.status = MBridge.parseStatus(
        MBridge.jsonPathToString(res, r'$..comic.status', ''), statusList);
    final chapUrlReq =
        "${sourceInfo.apiUrl}${url.replaceAll("#", '')}chapters?lang=${sourceInfo.lang}&tachiyomi=true&page=1";
    final dataReq = {"url": chapUrlReq, "headers": headers};
    final request = await MBridge.http('GET', json.encode(dataReq));
    var total = MBridge.jsonPathToString(request, r'$.total', '');
    final chapterLimit = int.parse(total);
    final newChapUrlReq =
        "${sourceInfo.apiUrl}${url.replaceAll("#", '')}chapters?limit=$chapterLimit&lang=${sourceInfo.lang}&tachiyomi=true&page=1";

    final newDataReq = {"url": newChapUrlReq, "headers": headers};
    final newRequest = await MBridge.http('GET', json.encode(newDataReq));

    final chapsUrls =
        MBridge.jsonPathToString(newRequest, r'$.chapters[*].hid', "_.")
            .split("_.");
    final chapDate =
        MBridge.jsonPathToString(newRequest, r'$.chapters[*].created_at', "_.")
            .split("_.");
    final chaptersVolumes =
        MBridge.jsonPathToString(newRequest, r'$.chapters[*].vol', "_.")
            .split("_.");
    final chaptersScanlators =
        MBridge.jsonPathToString(newRequest, r'$.chapters[*].group_name', "_.")
            .split("_.");
    final chapsNames =
        MBridge.jsonPathToString(newRequest, r'$.chapters[*].title', "_.")
            .split("_.");
    final chaptersChaps =
        MBridge.jsonPathToString(newRequest, r'$.chapters[*].chap', "_.")
            .split("_.");

    var dateUploads = MBridge.parseDates(
        chapDate, sourceInfo.dateFormat, sourceInfo.dateFormatLocale);
    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chapsNames.length; i++) {
      String title = "";
      String scanlator = "";
      if (chaptersChaps.isNotEmpty && chaptersVolumes.isNotEmpty) {
        title = beautifyChapterName(chaptersVolumes[i], chaptersChaps[i],
            chapsNames[i], sourceInfo.lang);
      } else {
        title = chapsNames[i];
      }
      if (chaptersScanlators.isNotEmpty) {
        scanlator = chaptersScanlators[i]
            .toString()
            .replaceAll(']', "")
            .replaceAll("[", "");
      }
      MChapter chapter = MChapter();
      chapter.name = title;
      chapter.url = chapsUrls[i];
      chapter.scanlator = scanlator == "null" ? "" : scanlator;
      chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    final urll = "${sourceInfo.apiUrl}/chapter/$url?tachiyomi=true";
    final data = {"url": urll, "headers": getHeader(url)};
    final res = await MBridge.http('GET', json.encode(data));
    return MBridge.jsonPathToString(res, r'$.chapter.images[*].url', '_.')
        .split('_.');
  }

  MPages mangaRes(String res) async {
    final names = MBridge.jsonPathToList(res, r'$.title', 0);
    List<String> ids = MBridge.jsonPathToList(res, r'$.hid', 0);
    List<String> mangaUrls = [];
    for (var id in ids) {
      mangaUrls.add("/comic/$id/#");
    }
    final urls = mangaUrls;
    final images = MBridge.jsonPathToList(res, r'$.cover_url', 0);
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

  Map<String, String> getHeader(String url) {
    final headers = {
      "Referer": "$url/",
      'User-Agent':
          "Tachiyomi Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:110.0) Gecko/20100101 Firefox/110.0"
    };
    return headers;
  }

  String beautifyChapterName(
      String vol, String chap, String title, String lang) {
    String result = "";

    if (vol != "null" && vol.isNotEmpty) {
      if (chap != "null" && chap.isEmpty) {
        result += "Volume $vol ";
      } else {
        result += "Vol. $vol ";
      }
    }

    if (chap != "null" && chap.isNotEmpty) {
      if (vol != "null" && vol.isEmpty) {
        if (lang != "null" && lang == "fr") {
          result += "Chapitre $chap";
        } else {
          result += "Chapter $chap";
        }
      } else {
        result += "Ch. $chap ";
      }
    }

    if (title != "null" && title.isNotEmpty) {
      if (chap != "null" && chap.isEmpty) {
        result += title;
      } else {
        result += " : $title";
      }
    }

    return result;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    return [];
  }
}

ComickFun main() {
  return ComickFun();
}

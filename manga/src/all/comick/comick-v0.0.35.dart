import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class ComickFun extends MProvider {
  ComickFun();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final url =
        "${source.apiUrl}/v1.0/search?sort=follow&page=$page&tachiyomi=true";
    final data = {"url": url, "headers": getHeader(source.baseUrl)};
    final res = await http('GET', json.encode(data));
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final url =
        "${source.apiUrl}/v1.0/search?sort=uploaded&page=$page&tachiyomi=true";
    final data = {"url": url, "headers": getHeader(source.baseUrl)};
    final res = await http('GET', json.encode(data));
    return mangaRes(res);
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    final url = "${source.apiUrl}/v1.0/search?q=$query&tachiyomi=true";
    final data = {"url": url, "headers": getHeader(source.baseUrl)};
    final res = await http('GET', json.encode(data));
    return mangaRes(res);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"1": 0, "2": 1, "3": 3, "4": 2}
    ];

    final headers = getHeader(source.baseUrl);

    final urll = "${source.apiUrl}${url.replaceAll("#", '')}?tachiyomi=true";
    final data = {"url": urll, "headers": headers};
    final res = await http('GET', json.encode(data));
    MManga manga = MManga();
    manga.author = jsonPathToString(res, r'$.authors[*].name', '');
    manga.genre = jsonPathToString(res, r'$.genres[*].name', "_.").split("_.");
    manga.description = jsonPathToString(res, r'$..desc', '');
    manga.status =
        parseStatus(jsonPathToString(res, r'$..comic.status', ''), statusList);
    final chapUrlReq =
        "${source.apiUrl}${url.replaceAll("#", '')}chapters?lang=${source.lang}&tachiyomi=true&page=1";
    final dataReq = {"url": chapUrlReq, "headers": headers};
    final request = await http('GET', json.encode(dataReq));
    var total = jsonPathToString(request, r'$.total', '');
    final chapterLimit = int.parse(total);
    final newChapUrlReq =
        "${source.apiUrl}${url.replaceAll("#", '')}chapters?limit=$chapterLimit&lang=${source.lang}&tachiyomi=true&page=1";

    final newDataReq = {"url": newChapUrlReq, "headers": headers};
    final newRequest = await http('GET', json.encode(newDataReq));

    final chapsUrls =
        jsonPathToString(newRequest, r'$.chapters[*].hid', "_.").split("_.");
    final chapDate =
        jsonPathToString(newRequest, r'$.chapters[*].created_at', "_.")
            .split("_.");
    final chaptersVolumes =
        jsonPathToString(newRequest, r'$.chapters[*].vol', "_.").split("_.");
    final chaptersScanlators =
        jsonPathToString(newRequest, r'$.chapters[*].group_name', "_.")
            .split("_.");
    final chapsNames =
        jsonPathToString(newRequest, r'$.chapters[*].title', "_.").split("_.");
    final chaptersChaps =
        jsonPathToString(newRequest, r'$.chapters[*].chap', "_.").split("_.");

    var dateUploads =
        parseDates(chapDate, source.dateFormat, source.dateFormatLocale);
    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chapsNames.length; i++) {
      String title = "";
      String scanlator = "";
      if (chaptersChaps.isNotEmpty && chaptersVolumes.isNotEmpty) {
        title = beautifyChapterName(
            chaptersVolumes[i], chaptersChaps[i], chapsNames[i], source.lang);
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
  Future<List<String>> getPageList(MSource source, String url) async {
    final urll = "${source.apiUrl}/chapter/$url?tachiyomi=true";
    final data = {"url": urll, "headers": getHeader(url)};
    final res = await http('GET', json.encode(data));
    return jsonPathToString(res, r'$.chapter.images[*].url', '_.').split('_.');
  }

  MPages mangaRes(String res) async {
    final names = jsonPathToList(res, r'$.title', 0);
    List<String> ids = jsonPathToList(res, r'$.hid', 0);
    List<String> mangaUrls = [];
    for (var id in ids) {
      mangaUrls.add("/comic/$id/#");
    }
    final urls = mangaUrls;
    final images = jsonPathToList(res, r'$.cover_url', 0);
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
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    return [];
  }
}

Map<String, String> getHeader(String url) {
  final headers = {
    "Referer": "$url/",
    'User-Agent':
        "Tachiyomi Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:110.0) Gecko/20100101 Firefox/110.0"
  };
  return headers;
}

ComickFun main() {
  return ComickFun();
}

// import 'package:bridge_lib/bridge_lib.dart';
// import 'dart:convert';

// getLatestUpdatesManga(MangaModel manga) async {
//   final url =
//       "${manga.apiUrl}/v1.0/search?sort=uploaded&page=${manga.page}&tachiyomi=true";
//   final data = {"url": url, "headers": getHeader(manga.baseUrl)};
//   final res = await MBridge.http(json.encode(data), 0);
//   if (res.isEmpty) {
//     return manga;
//   }
//   manga.names = MBridge.jsonPathToList(res, r'$.title');
//   List<String> ids = MBridge.jsonPathToList(res, r'$.hid');
//   List<String> mangaUrls = [];
//   for (var id in ids) {
//     mangaUrls.add("/comic/$id/#");
//   }
//   manga.urls = mangaUrls;
//   manga.images = MBridge.jsonPathToList(res, r'$.cover_url');
//   return manga;
// }

// getMangaDetail(MangaModel manga) async {
//   final statusList = [
//     {
//       "1": 0,
//       "2": 1,
//       "3": 3,
//       "4": 2,
//     }
//   ];

//   final headers = getHeader(manga.baseUrl);

//   final urll =
//       "${manga.apiUrl}${manga.link.replaceAll("#", '')}?tachiyomi=true";
//   final data = {"url": urll, "headers": headers};
//   final res = await MBridge.http(json.encode(data), 0);
//   if (res.isEmpty) {
//     return manga;
//   }
//   manga.author = MBridge.jsonPathToString(res, r'$.authors[*].name', '');
//   manga.genre =
//       MBridge.jsonPathToString(res, r'$.genres[*].name', "_.").split("_.");
//   manga.description = MBridge.jsonPathToString(res, r'$..desc', '');
//   manga.status = MBridge.parseStatus(
//       MBridge.jsonPathToString(res, r'$..comic.status', ''), statusList);
//   final chapUrlReq =
//       "${manga.apiUrl}${manga.link.replaceAll("#", '')}chapters?lang=${manga.lang}&tachiyomi=true&page=1";
//   final dataReq = {"url": chapUrlReq, "headers": headers};
//   final request = await MBridge.http(json.encode(dataReq), 0);
//   var total = MBridge.jsonPathToString(request, r'$.total', '');
//   final chapterLimit = MBridge.intParse("$total");
//   final newChapUrlReq =
//       "${manga.apiUrl}${manga.link.replaceAll("#", '')}chapters?limit=$chapterLimit&lang=${manga.lang}&tachiyomi=true&page=1";

//   final newDataReq = {"url": newChapUrlReq, "headers": headers};
//   final newRequest = await MBridge.http(json.encode(newDataReq), 0);

//   manga.urls = MBridge.jsonPathToString(newRequest, r'$.chapters[*].hid', "_.")
//       .split("_.");
//   final chapDate =
//       MBridge.jsonPathToString(newRequest, r'$.chapters[*].created_at', "_.")
//           .split("_.");
//   manga.chaptersDateUploads = MBridge.listParse(
//       MBridge.listParseDateTime(chapDate, "yyyy-MM-dd'T'HH:mm:ss'Z'", "en"), 0);
//   manga.chaptersVolumes =
//       MBridge.jsonPathToString(newRequest, r'$.chapters[*].vol', "_.")
//           .split("_.");
//   manga.chaptersScanlators =
//       MBridge.jsonPathToString(newRequest, r'$.chapters[*].group_name', "_.")
//           .split("_.");
//   manga.names =
//       MBridge.jsonPathToString(newRequest, r'$.chapters[*].title', "_.")
//           .split("_.");
//   manga.chaptersChaps =
//       MBridge.jsonPathToString(newRequest, r'$.chapters[*].chap', "_.")
//           .split("_.");

//   return manga;
// }

// getPopularManga(MangaModel manga) async {
//   final urll =
//       "${manga.apiUrl}/v1.0/search?sort=follow&page=${manga.page}&tachiyomi=true";
//   final data = {"url": urll, "headers": getHeader(manga.baseUrl)};
//   final res = await MBridge.http(json.encode(data), 0);
//   if (res.isEmpty) {
//     return manga;
//   }
//   manga.names = MBridge.jsonPathToList(res, r'$.title');
//   List<String> ids = MBridge.jsonPathToList(res, r'$.hid');
//   List<String> mangaUrls = [];
//   for (var id in ids) {
//     mangaUrls.add("/comic/$id/#");
//   }
//   manga.urls = mangaUrls;
//   manga.images = MBridge.jsonPathToList(res, r'$.cover_url');
//   return manga;
// }

// searchManga(MangaModel manga) async {
//   final urll = "${manga.apiUrl}/v1.0/search?q=${manga.query}&tachiyomi=true";
//   final data = {"url": urll, "headers": getHeader(manga.baseUrl)};
//   final res = await MBridge.http(json.encode(data), 0);
//   if (res.isEmpty) {
//     return manga;
//   }
//   manga.names = MBridge.jsonPathToList(res, r'$.title');
//   List<String> ids = MBridge.jsonPathToList(res, r'$.hid');
//   List<String> mangaUrls = [];
//   for (var id in ids) {
//     mangaUrls.add("/comic/$id/#");
//   }
//   manga.urls = mangaUrls;
//   manga.images = MBridge.jsonPathToList(res, r'$.cover_url');
//   return manga;
// }

// getChapterUrl(MangaModel manga) async {
//   final url = "${manga.apiUrl}/chapter/${manga.link}?tachiyomi=true";
//   final data = {"url": url, "headers": getHeader(url)};
//   final res = await MBridge.http(json.encode(data), 0);
//   if (res.isEmpty) {
//     return [];
//   }
//   return MBridge.jsonPathToString(res, r'$.chapter.images[*].url', '_.')
//       .split('_.');
// }

// Map<String, String> getHeader(String url) {
//   final headers = {
//     "Referer": "$url/",
//     'User-Agent':
//         "Tachiyomi Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:110.0) Gecko/20100101 Firefox/110.0"
//   };
//   return headers;
// }

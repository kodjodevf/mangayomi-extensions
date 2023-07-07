// import 'package:bridge_lib/bridge_lib.dart';
// import 'dart:convert';

// String getMDXContentRating() {
//   String ctnRating = MBridge.stringParse(
//       "&contentRating[]=suggestive&contentRating[]=safe&contentRating[]=erotica&contentRating[]=pornographic");
//   return ctnRating;
// }

// getPopularManga(MangaModel manga) async {
//   int page = (20 * (manga.page - 1));
//   final url =
//       "https://api.mangadex.org/manga?limit=20&offset=$page&availableTranslatedLanguage[]=en&includes[]=cover_art${getMDXContentRating()}&order[followedCount]=desc";
//   final datas = {"url": url, "headers": null};
//   final res = await MBridge.http(json.encode(datas), 0);
//   if (res.isEmpty) {
//     return manga;
//   }
//   List<String> data = MBridge.listParse(
//       MBridge.jsonPathToString(res, r'$.data[*]', '_.').split("_."), 0);
//   List<String> urlList = [];
//   List<String> titleList = [];
//   List<String> imageList = [];
//   for (var i = 0; i < data.length; i++) {
//     final expressionId =
//         MBridge.regExp(r'$.data[a].id', r'\[a\]', "[$i]", 0, 1);
//     final id = MBridge.jsonPathToString(res, expressionId, '_.');
//     titleList.add(findTitle(res, i, manga.lang));
//     urlList.add("/manga/$id");
//     imageList.add(getCover(res, i, id));
//   }
//   manga.names = titleList;
//   manga.urls = urlList;
//   manga.images = imageList;
//   return manga;
// }

// MangaModel getChapters(
//     MangaModel manga, int length, String paginatedChapterListA) {
//   String scanlators = MBridge.stringParse("");
//   String chapNames = MBridge.stringParse("");
//   String chapDate = MBridge.stringParse("");
//   String chapterUrl = MBridge.stringParse("");
//   String paginatedChapterList = MBridge.stringParse(paginatedChapterListA);
//   final dataList = MBridge.jsonPathToList(paginatedChapterList, r'$.data[*]');
//   for (var res in dataList) {
//     String scan = MBridge.stringParse("");
//     final groups = MBridge.jsonPathToList(
//         res, r'$.relationships[?@.id!="00e03853-1b96-4f41-9542-c71b8692033b"]');
//     String chapName = MBridge.stringParse("");
//     for (var element in groups) {
//       final data = MBridge.getMapValue(element, "attributes", 1);
//       if (data.isEmpty) {
//       } else {
//         final name = MBridge.getMapValue(data, "name", 0);
//         scan += MBridge.stringParse("$name");
//         final username = MBridge.getMapValue(data, "username", 0);
//         if (username.isEmpty) {
//         } else {
//           if (scan.isEmpty) {
//             scan += MBridge.stringParse("Uploaded by $username");
//           }
//         }
//       }
//     }
//     if (scan.isEmpty) {
//       scan = MBridge.stringParse("No Group");
//     }
//     final dataRes = MBridge.getMapValue(res, "attributes", 1);
//     if (dataRes.isEmpty) {
//     } else {
//       final data = MBridge.getMapValue(res, "attributes", 1);
//       final volume = MBridge.getMapValue(data, "volume", 0);
//       if (volume.isEmpty) {
//       } else {
//         if (volume == "null") {
//         } else {
//           chapName = MBridge.stringParse("Vol.$volume ");
//         }
//       }
//       final chapter = MBridge.getMapValue(data, "chapter", 0);
//       if (chapter.isEmpty) {
//       } else {
//         if (chapter == "null") {
//         } else {
//           chapName += MBridge.stringParse("Ch.$chapter ");
//         }
//       }
//       final title = MBridge.getMapValue(data, "title", 0);
//       if (title.isEmpty) {
//       } else {
//         if (title == "null") {
//         } else {
//           if (chapName.isEmpty) {
//           } else {
//             chapName += MBridge.stringParse("- ");
//           }
//           chapName += MBridge.stringParse("$title");
//         }
//       }
//       if (chapName.isEmpty) {
//         chapName += MBridge.stringParse("Oneshot");
//       }
//       final date = MBridge.getMapValue(data, "publishAt", 0);
//       final id = MBridge.getMapValue(res, "id", 0);
//       chapterUrl += "._$id";
//       chapDate += "._._$date";
//       scanlators += "._$scan";
//       chapNames += "._$chapName";
//     }
//   }
//   manga.chaptersDateUploads = MBridge.listParseDateTime(
//       chapDate.split("._._"), "yyyy-MM-dd'T'HH:mm:ss+SSS", "en_US");

//   manga.urls = chapterUrl.split("._");
//   manga.chaptersScanlators = scanlators.split("._");
//   manga.names = chapNames.split("._");
//   return manga;
// }

// getMangaDetail(MangaModel manga) async {
//   final statusList = [
//     {
//       "ongoing": 0,
//       "completed": 1,
//       "hiatus": 2,
//       "cancelled": 3,
//     }
//   ];
//   final url =
//       "https://api.mangadex.org${manga.link}?includes[]=cover_art&includes[]=author&includes[]=artist";
//   final datas = {"url": url, "headers": null};
//   final res = await MBridge.http(json.encode(datas), 0);
//   if (res.isEmpty) {
//     return manga;
//   }

//   manga.author = MBridge.jsonPathToString(
//       res, r'$..data.relationships[*].attributes.name', ', ');

//   String expressionDescriptionA = r'$..data.attributes.description.en';
//   String expressionDescription = MBridge.regExp(
//       r'$..data.attributes.description[a]', r'\[a\]', ".${manga.lang}", 0, 1);

//   String description = MBridge.jsonPathToString(res, expressionDescription, '');
//   if (description.isEmpty) {
//     description = MBridge.jsonPathToString(res, expressionDescriptionA, '');
//   }
//   manga.description = description;
//   List<String> genres = [];

//   final genre = MBridge.listParse(
//       MBridge.jsonPathToString(
//               res, r'$..data.attributes.tags[*].attributes.name.en', '.-')
//           .split('.-'),
//       0);
//   genres = genre;
//   String contentRating =
//       MBridge.jsonPathToString(res, r'$..data.attributes.contentRating', '');
//   if (contentRating == "safe") {
//   } else {
//     genres.add(contentRating);
//   }
//   String publicationDemographic = MBridge.jsonPathToString(
//       res, r'$..data.attributes.publicationDemographic', '');
//   if (publicationDemographic == "null") {
//   } else {
//     genres.add(publicationDemographic);
//   }
//   manga.genre = genres;
//   String statusRes =
//       MBridge.jsonPathToString(res, r'$..data.attributes.status', '');
//   manga.status = MBridge.parseStatus(statusRes, statusList);
//   final mangaId = MBridge.listParse(manga.link.split('/'), 2)[0];
//   final paginatedChapterList =
//       await paginatedChapterListRequest(mangaId, 0, manga.lang);
//   final chapterList =
//       MBridge.jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
//           .split('_.');
//   int limit = MBridge.intParse(
//       MBridge.jsonPathToString(paginatedChapterList, r'$.limit', ''));
//   int offset = MBridge.intParse(
//       MBridge.jsonPathToString(paginatedChapterList, r'$.offset', ''));
//   int total = MBridge.intParse(
//       MBridge.jsonPathToString(paginatedChapterList, r'$.total', ''));
//   List<MangaModel> chapterListA = [];
//   List<String> chapNames = [];
//   List<String> scanlators = [];
//   List<String> chapterUrl = [];
//   List<String> chapterDate = [];
//   final list = getChapters(
//       manga, MBridge.intParse("${chapterList.length}"), paginatedChapterList);
//   chapterListA.add(list);
//   var hasMoreResults = (limit + offset) < total;
//   while (hasMoreResults) {
//     offset += limit;
//     var newRequest =
//         await paginatedChapterListRequest(mangaId, offset, manga.lang);
//     int total =
//         MBridge.intParse(MBridge.jsonPathToString(newRequest, r'$.total', ''));
//     final chapterList =
//         MBridge.jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
//             .split('_.');
//     final list = getChapters(
//         manga, MBridge.intParse("${chapterList.length}"), newRequest);
//     chapterListA.add(list);
//     hasMoreResults = (limit + offset) < total;
//   }
//   for (var element in chapterListA) {
//     int index = 0;
//     for (var name in element.names) {
//       if (name.isEmpty) {
//       } else {
//         chapNames.add(name);
//         chapterUrl.add(element.urls[index]);
//         chapterDate.add(element.chaptersDateUploads[index]);
//         scanlators.add(element.chaptersScanlators[index]);
//       }
//       index++;
//     }
//   }
//   manga.urls = chapterUrl;
//   manga.chaptersDateUploads = chapterDate;
//   manga.chaptersScanlators = scanlators;
//   manga.names = chapNames;
//   return manga;
// }

// getLatestUpdatesManga(MangaModel manga) async {
//   int page = (20 * (manga.page - 1));
//   final urll =
//       "https://api.mangadex.org/chapter?limit=20&offset=$page&translatedLanguage[]=${manga.lang}&includeFutureUpdates=0&order[publishAt]=desc&includeFuturePublishAt=0&includeEmptyPages=0";
//   final datas = {"url": urll, "headers": null};
//   final ress = await MBridge.http(json.encode(datas), 0);
//   if (ress.isEmpty) {
//     return manga;
//   }
//   final mangaIds = MBridge.listParse(
//       MBridge.jsonPathToString(ress, r'$.data[*].relationships[*].id', '.--')
//           .split('.--'),
//       3);
//   String mangaa = MBridge.stringParse("");
//   for (var id in mangaIds) {
//     mangaa += "&ids[]=$id";
//   }
//   final newUrl =
//       "https://api.mangadex.org/manga?includes[]=cover_art&limit=${mangaIds.length}${getMDXContentRating()}$mangaa";
//   final datass = {"url": newUrl, "headers": null};
//   final res = await MBridge.http(json.encode(datass), 0);
//   List<String> data = MBridge.listParse(
//       MBridge.jsonPathToString(res, r'$.data[*]', '_.').split("_."), 0);
//   List<String> urlList = [];
//   List<String> titleList = [];
//   List<String> imageList = [];
//   for (var i = 0; i < data.length; i++) {
//     final expressionId =
//         MBridge.regExp(r'$.data[a].id', r'\[a\]', "[$i]", 0, 1);
//     final id = MBridge.jsonPathToString(res, expressionId, '_.');
//     titleList.add(findTitle(res, i, manga.lang));
//     urlList.add("/manga/$id");
//     imageList.add(getCover(res, i, id));
//   }
//   manga.names = titleList;
//   manga.urls = urlList;
//   manga.images = imageList;
//   return manga;
// }

// searchManga(MangaModel manga) async {
//   final url =
//       "https://api.mangadex.org/manga?includes[]=cover_art&offset=0&limit=20&title=${manga.query}${getMDXContentRating()}&order[followedCount]=desc&availableTranslatedLanguage[]=${manga.lang}";
//   final datas = {"url": url, "headers": null};
//   final res = await MBridge.http(json.encode(datas), 0);
//   if (res.isEmpty) {
//     return manga;
//   }
//   List<String> data = MBridge.listParse(
//       MBridge.jsonPathToString(res, r'$.data[*]', '_.').split("_."), 0);
//   List<String> urlList = [];
//   List<String> titleList = [];
//   List<String> imageList = [];
//   for (var i = 0; i < data.length; i++) {
//     final expressionId =
//         MBridge.regExp(r'$.data[a].id', r'\[a\]', "[$i]", 0, 1);
//     final id = MBridge.jsonPathToString(res, expressionId, '_.');
//     titleList.add(findTitle(res, i, manga.lang));
//     urlList.add("/manga/$id");
//     imageList.add(getCover(res, i, id));
//   }
//   manga.names = titleList;
//   manga.urls = urlList;
//   manga.images = imageList;
//   return manga;
// }

// getChapterUrl(MangaModel manga) async {
//   final url = "https://api.mangadex.org/at-home/server/${manga.link}";
//   final data = {"url": url, "headers": null};
//   final res = await MBridge.http(json.encode(data), 0);
//   if (res.isEmpty) {
//     return [];
//   }
//   final host = MBridge.jsonPathToString(res, r'$.baseUrl', '');
//   final hash = MBridge.jsonPathToString(res, r'$.chapter.hash', '');
//   List<String> pageSuffix = [];
//   List<String> pageUrls = [];
//   List<String> chapterDatas = MBridge.listParse(
//       MBridge.jsonPathToString(res, r'$.chapter.data[*]', '.--').split('.--'),
//       0);
//   for (var d in chapterDatas) {
//     pageSuffix.add("/data/$hash/$d");
//   }
//   for (var url in pageSuffix) {
//     pageUrls.add("$host$url");
//   }

//   return pageUrls;
// }

// Future<String> paginatedChapterListRequest(
//     String mangaId, int offset, String lang) async {
//   final url =
//       'https://api.mangadex.org/manga/$mangaId/feed?limit=500&offset=$offset&includes[]=user&includes[]=scanlation_group&order[volume]=desc&order[chapter]=desc&translatedLanguage[]=$lang&includeFuturePublishAt=0&includeEmptyPages=0${getMDXContentRating()}';
//   final datas = {"url": url, "headers": null};
//   return await MBridge.http(json.encode(datas), 0);
// }

// String findTitle(String dataRes, int mangaIndex, String lang) {
//   String expressionAltTitlesA = MBridge.regExp(
//       r'$.data[a].attributes.altTitles[b]', r'\[a\]', "[$mangaIndex]", 0, 1);
//   String expressionAltTitles =
//       MBridge.regExp(expressionAltTitlesA, r'\[b\]', "[*].$lang", 0, 1);

//   String altTitles =
//       MBridge.jsonPathToString(dataRes, expressionAltTitles, '_.');

//   if (altTitles.isEmpty) {
//     expressionAltTitles = MBridge.regExp(
//         r'$.data[a].attributes.altTitles[?@.en].en',
//         r'\[a\]',
//         "[$mangaIndex]",
//         0,
//         1);
//     altTitles = MBridge.jsonPathToString(dataRes, expressionAltTitles, '_.');
//   }
//   List<String> dataAltTitles = MBridge.listParse(altTitles.split('_.'), 0);
//   final expressionTitle = MBridge.regExp(
//       r'$.data[a].attributes.title.en', r'\[a\]', "[$mangaIndex]", 0, 1);
//   final title = MBridge.jsonPathToString(dataRes, expressionTitle, '_.');
//   if (title.isEmpty) {
//     return dataAltTitles[0];
//   } else {
//     return title;
//   }
// }

// String getCover(String dataRes, int mangaIndex, String mangaId) {
//   final expressionRelationAll = MBridge.regExp(
//       r'$.data[a].relationships[*]', r'\[a\]', "[$mangaIndex]", 0, 1);
//   List<String> relationDatas = MBridge.listParse(
//       MBridge.jsonPathToString(dataRes, expressionRelationAll, '_.')
//           .split("_."),
//       0);
//   String coverFileName = MBridge.stringParse("");
//   for (var j = 0; j < relationDatas.length; j++) {
//     final expressionData = MBridge.regExp(
//         r'$.data[a].relationships[b]', r'\[a\]', "[$mangaIndex]", 0, 1);
//     final expressionRelationType =
//         MBridge.regExp(expressionData, r'\[b\]', "[$j].type", 0, 1);
//     final relationType =
//         MBridge.jsonPathToString(dataRes, expressionRelationType, '');
//     if (relationType == "cover_art") {
//       if (coverFileName.isEmpty) {
//         final expressionRelationCoverFile = MBridge.regExp(
//             expressionData, r'\[b\]', "[$j].attributes.fileName", 0, 1);
//         coverFileName =
//             MBridge.jsonPathToString(dataRes, expressionRelationCoverFile, '');

//         coverFileName =
//             "https://uploads.mangadex.org/covers/$mangaId/$coverFileName";
//       }
//     }
//   }
//   return coverFileName;
// }

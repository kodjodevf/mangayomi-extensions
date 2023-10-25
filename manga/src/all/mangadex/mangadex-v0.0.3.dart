import 'package:bridge_lib/bridge_lib.dart';
import 'dart:convert';

getPopularManga(MManga manga) async {
  int page = (20 * (manga.page - 1));
  final url =
      "https://api.mangadex.org/manga?limit=20&offset=$page&availableTranslatedLanguage[]=en&includes[]=cover_art${getMDXContentRating()}&order[followedCount]=desc";
  final datas = {"url": url};
  final response = await MBridge.http('GET', json.encode(datas));
  if (response.hasError) {
    return response;
  }
  return parseManga(response.body, manga);
}

getLatestUpdatesManga(MManga manga) async {
  int page = (20 * (manga.page - 1));
  final urll =
      "https://api.mangadex.org/chapter?limit=20&offset=$page&translatedLanguage[]=${manga.lang}&includeFutureUpdates=0&order[publishAt]=desc&includeFuturePublishAt=0&includeEmptyPages=0";
  final datas = {"url": urll};
  final response = await MBridge.http('GET', json.encode(datas));
  if (response.hasError) {
    return response;
  }
  String ress = response.body;

  final mangaIds = MBridge.listParse(
      MBridge.jsonPathToString(ress, r'$.data[*].relationships[*].id', '.--')
          .split('.--'),
      3);
  String mangaa = "".toString();
  for (var id in mangaIds) {
    mangaa += "&ids[]=$id";
  }
  final newUrl =
      "https://api.mangadex.org/manga?includes[]=cover_art&limit=${mangaIds.length}${getMDXContentRating()}$mangaa";
  final datass = {"url": newUrl};
  final res = await MBridge.http('GET', json.encode(datass));
  if (res.hasError) {
    return res;
  }
  return parseManga(res.body, manga);
}

searchManga(MManga manga) async {
  final url =
      "https://api.mangadex.org/manga?includes[]=cover_art&offset=0&limit=20&title=${manga.query}${getMDXContentRating()}&order[followedCount]=desc&availableTranslatedLanguage[]=${manga.lang}";
  final datas = {"url": url};
  final res = await MBridge.http('GET', json.encode(datas));
  if (res.hasError) {
    return res;
  }
  return parseManga(res.body, manga);
}

getMangaDetail(MManga manga) async {
  final statusList = [
    {
      "ongoing": 0,
      "completed": 1,
      "hiatus": 2,
      "cancelled": 3,
    }
  ];
  final url =
      "https://api.mangadex.org${manga.link}?includes[]=cover_art&includes[]=author&includes[]=artist";
  final datas = {"url": url};
  final response = await MBridge.http('GET', json.encode(datas));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.author = MBridge.jsonPathToString(
      res, r'$..data.relationships[*].attributes.name', ', ');

  String expressionDescriptionA = r'$..data.attributes.description.en';
  String expressionDescription = MBridge.regExp(
      r'$..data.attributes.description[a]', r'\[a\]', ".${manga.lang}", 0, 1);

  String description = MBridge.jsonPathToString(res, expressionDescription, '');
  if (description.isEmpty) {
    description = MBridge.jsonPathToString(res, expressionDescriptionA, '');
  }
  manga.description = description;
  List<String> genres = [];

  final genre = MBridge.listParse(
      MBridge.jsonPathToString(
              res, r'$..data.attributes.tags[*].attributes.name.en', '.-')
          .split('.-'),
      0);
  genres = genre;
  String contentRating =
      MBridge.jsonPathToString(res, r'$..data.attributes.contentRating', '');
  if (contentRating == "safe") {
  } else {
    genres.add(contentRating);
  }
  String publicationDemographic = MBridge.jsonPathToString(
      res, r'$..data.attributes.publicationDemographic', '');
  if (publicationDemographic == "null") {
  } else {
    genres.add(publicationDemographic);
  }
  manga.genre = genres;
  String statusRes =
      MBridge.jsonPathToString(res, r'$..data.attributes.status', '');
  manga.status = MBridge.parseStatus(statusRes, statusList);
  final mangaId = MBridge.listParse(manga.link.split('/'), 2)[0];
  final paginatedChapterList =
      await paginatedChapterListRequest(mangaId, 0, manga.lang);
  final chapterList =
      MBridge.jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
          .split('_.');
  int limit = MBridge.intParse(
      MBridge.jsonPathToString(paginatedChapterList, r'$.limit', ''));
  int offset = MBridge.intParse(
      MBridge.jsonPathToString(paginatedChapterList, r'$.offset', ''));
  int total = MBridge.intParse(
      MBridge.jsonPathToString(paginatedChapterList, r'$.total', ''));
  List<MManga> chapterListA = [];
  List<String> chapNames = [];
  List<String> scanlators = [];
  List<String> chapterUrl = [];
  List<String> chapterDate = [];

  final list = getChapters(
      manga, MBridge.intParse("${chapterList.length}"), paginatedChapterList);

  chapterListA.add(list);
  var hasMoreResults = (limit + offset) < total;
  while (hasMoreResults) {
    offset += limit;
    var newRequest =
        await paginatedChapterListRequest(mangaId, offset, manga.lang);
    int total =
        MBridge.intParse(MBridge.jsonPathToString(newRequest, r'$.total', ''));
    final chapterList =
        MBridge.jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
            .split('_.');
    final list = getChapters(
        manga, MBridge.intParse("${chapterList.length}"), newRequest);
    chapterListA.add(list);
    hasMoreResults = (limit + offset) < total;
  }
  for (var element in chapterListA) {
    for (var name in element.names) {
      if (name.isNotEmpty) {
        chapNames.add(name);
      }
    }
  }
  for (var element in chapterListA) {
    for (var url in element.urls) {
      if (url.isNotEmpty) {
        chapterUrl.add(url);
      }
    }
  }
  for (var element in chapterListA) {
    for (var chapDate in element.chaptersDateUploads) {
      if (chapDate.isNotEmpty) {
        chapterDate.add(chapDate);
      }
    }
  }
  for (var element in chapterListA) {
    for (var scanlator in element.chaptersScanlators) {
      if (scanlator.isNotEmpty) {
        scanlators.add(scanlator);
      }
    }
  }
  manga.urls = chapterUrl;
  manga.chaptersDateUploads = chapterDate;
  manga.chaptersScanlators = scanlators;
  manga.names = chapNames;
  return manga;
}

getChapterPages(MManga manga) async {
  final url = "https://api.mangadex.org/at-home/server/${manga.link}";
  final data = {"url": url};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  final dataRes = json.decode(response.body);
  final host = dataRes["baseUrl"];
  final hash = dataRes["chapter"]["hash"];
  final chapterDatas = dataRes["chapter"]["data"] as List;
  return chapterDatas.map((e) => "$host/data/$hash/$e").toList();
}

String getMDXContentRating() {
  String ctnRating =
      "&contentRating[]=suggestive&contentRating[]=safe&contentRating[]=erotica&contentRating[]=pornographic";
  return ctnRating;
}

MManga getChapters(MManga manga, int length, String paginatedChapterListA) {
  String scanlators = "".toString();
  String chapNames = "".toString();
  String chapDate = "".toString();
  String chapterUrl = "".toString();
  String paginatedChapterList = paginatedChapterListA.toString();
  final dataList =
      MBridge.jsonPathToList(paginatedChapterList, r'$.data[*]', 0);
  for (var res in dataList) {
    String scan = "".toString();
    final groups = MBridge.jsonPathToList(res,
        r'$.relationships[?@.id!="00e03853-1b96-4f41-9542-c71b8692033b"]', 0);
    String chapName = "".toString();
    for (var element in groups) {
      final data = MBridge.getMapValue(element, "attributes", encode: true);
      if (data.isEmpty) {
      } else {
        final name = MBridge.getMapValue(data, "name");
        scan += "$name".toString();
        final username = MBridge.getMapValue(data, "username");
        if (username.isEmpty) {
        } else {
          if (scan.isEmpty) {
            scan += "Uploaded by $username".toString();
          }
        }
      }
    }
    if (scan.isEmpty) {
      scan = "No Group".toString();
    }
    final dataRes = MBridge.getMapValue(res, "attributes", encode: true);
    if (dataRes.isEmpty) {
    } else {
      final data = MBridge.getMapValue(res, "attributes", encode: true);
      final volume = MBridge.getMapValue(data, "volume");
      if (volume.isEmpty) {
      } else {
        if (volume == "null") {
        } else {
          chapName = "Vol.$volume ".toString();
        }
      }
      final chapter = MBridge.getMapValue(data, "chapter");
      if (chapter.isEmpty) {
      } else {
        if (chapter == "null") {
        } else {
          chapName += "Ch.$chapter ".toString();
        }
      }
      final title = MBridge.getMapValue(data, "title");
      if (title.isEmpty) {
      } else {
        if (title == "null") {
        } else {
          if (chapName.isEmpty) {
          } else {
            chapName += "- ".toString();
          }
          chapName += "$title".toString();
        }
      }
      if (chapName.isEmpty) {
        chapName += "Oneshot".toString();
      }
      final date = MBridge.getMapValue(data, "publishAt");
      final id = MBridge.getMapValue(res, "id");
      chapterUrl += "._$id";
      chapDate += "._._$date";
      scanlators += "._$scan";
      chapNames += "._$chapName";
    }
  }
  manga.chaptersDateUploads = MBridge.listParseDateTime(
      chapDate.split("._._"), "yyyy-MM-dd'T'HH:mm:ss+SSS", "en_US");

  manga.urls = chapterUrl.split("._");
  manga.chaptersScanlators = scanlators.split("._");
  manga.names = chapNames.split("._");
  return manga;
}

Future<String> paginatedChapterListRequest(
    String mangaId, int offset, String lang) async {
  final url =
      'https://api.mangadex.org/manga/$mangaId/feed?limit=500&offset=$offset&includes[]=user&includes[]=scanlation_group&order[volume]=desc&order[chapter]=desc&translatedLanguage[]=$lang&includeFuturePublishAt=0&includeEmptyPages=0${getMDXContentRating()}';
  final datas = {"url": url};
  final response = await MBridge.http('GET', json.encode(datas));
  return response.body;
}

String findTitle(Map<String, dynamic> dataRes, String lang) {
  final altTitlesJ = dataRes["attributes"]["altTitles"];
  final titleJ = dataRes["attributes"]["title"];
  final title = MBridge.getMapValue(json.encode(titleJ), "en");
  if (title.isEmpty) {
    for (var r in altTitlesJ) {
      final altTitle = MBridge.getMapValue(json.encode(r), "en");
      if (altTitle.isNotEmpty) {
        return altTitle;
      }
    }
  }
  return title;
}

String getCover(Map<String, dynamic> dataRes) {
  final relationships = dataRes["relationships"];
  String coverFileName = "".toString();
  for (var a in relationships) {
    final relationType = a["type"];
    if (relationType == "cover_art") {
      if (coverFileName.isEmpty) {
        coverFileName =
            "https://uploads.mangadex.org/covers/${dataRes["id"]}/${a["attributes"]["fileName"]}";
      }
    }
  }
  return coverFileName;
}

MManga parseManga(String res, MManga manga) {
  if (res.isEmpty) {
    return manga;
  }
  final datasRes = json.decode(res);
  final resJson = datasRes["data"] as List;
  manga.names = resJson.map((e) => findTitle(e, manga.lang)).toList();
  manga.urls = resJson.map((e) => "/manga/${e["id"]}").toList();
  manga.images = resJson.map((e) => getCover(e)).toList();
  return manga;
}

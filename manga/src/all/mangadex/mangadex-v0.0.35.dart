import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaDex extends MSourceProvider {
  MangaDex();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    page = (20 * (page - 1));
    final url =
        "https://api.mangadex.org/manga?limit=20&offset=$page&availableTranslatedLanguage[]=en&includes[]=cover_art${getMDXContentRating()}&order[followedCount]=desc";
    final datas = {"url": url};
    final res = await MBridge.http('GET', json.encode(datas));
    return mangaRes(res, sourceInfo);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    page = (20 * (page - 1));
    final urll =
        "https://api.mangadex.org/chapter?limit=20&offset=$page&translatedLanguage[]=${sourceInfo.lang}&includeFutureUpdates=0&order[publishAt]=desc&includeFuturePublishAt=0&includeEmptyPages=0";
    final datas = {"url": urll};
    final ress = await MBridge.http('GET', json.encode(datas));
    final mangaIds =
        MBridge.jsonPathToString(ress, r'$.data[*].relationships[*].id', '.--')
            .split('.--');
    String mangaIdss = "".toString();
    for (var id in mangaIds) {
      mangaIdss += "&ids[]=$id";
    }
    final newUrl =
        "https://api.mangadex.org/manga?includes[]=cover_art&limit=${mangaIds.length}${getMDXContentRating()}$mangaIdss";
    final res = await MBridge.http('GET', json.encode({"url": newUrl}));
    return mangaRes(res, sourceInfo);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final url =
        "https://api.mangadex.org/manga?includes[]=cover_art&offset=0&limit=20&title=$query${getMDXContentRating()}&order[followedCount]=desc&availableTranslatedLanguage[]=${sourceInfo.lang}";

    final res = await MBridge.http('GET', json.encode({"url": url}));
    return mangaRes(res, sourceInfo);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {"ongoing": 0, "completed": 1, "hiatus": 2, "cancelled": 3}
    ];

    final urll =
        "https://api.mangadex.org$url?includes[]=cover_art&includes[]=author&includes[]=artist";
    final res = await MBridge.http('GET', json.encode({"url": urll}));
    MManga manga = MManga();
    manga.author = MBridge.jsonPathToString(
        res, r'$..data.relationships[*].attributes.name', ', ');

    String expressionDescriptionA = r'$..data.attributes.description.en';
    String expressionDescription = MBridge.regExp(
        r'$..data.attributes.description[a]',
        r'\[a\]',
        ".${sourceInfo.lang}",
        0,
        1);

    String description =
        MBridge.jsonPathToString(res, expressionDescription, '');
    if (description.isEmpty) {
      description = MBridge.jsonPathToString(res, expressionDescriptionA, '');
    }
    manga.description = description;
    List<String> genres = [];

    genres = MBridge.jsonPathToString(
            res, r'$..data.attributes.tags[*].attributes.name.en', '.-')
        .split('.-');

    String contentRating =
        MBridge.jsonPathToString(res, r'$..data.attributes.contentRating', '');
    if (contentRating != "safe") {
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
    final mangaId = url.split('/').last;

    final paginatedChapterList =
        await paginatedChapterListRequest(mangaId, 0, sourceInfo.lang);
    final chapterList =
        MBridge.jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
            .split('_.');
    int limit = int.parse(
        MBridge.jsonPathToString(paginatedChapterList, r'$.limit', ''));
    int offset = int.parse(
        MBridge.jsonPathToString(paginatedChapterList, r'$.offset', ''));
    int total = int.parse(
        MBridge.jsonPathToString(paginatedChapterList, r'$.total', ''));
    List<MChapter> chapterListA = [];

    final list =
        getChapters(int.parse("${chapterList.length}"), paginatedChapterList);

    chapterListA.addAll(list);
    var hasMoreResults = (limit + offset) < total;
    while (hasMoreResults) {
      offset += limit;
      var newRequest =
          await paginatedChapterListRequest(mangaId, offset, sourceInfo.lang);
      int total =
          int.parse(MBridge.jsonPathToString(newRequest, r'$.total', ''));
      final chapterList =
          MBridge.jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
              .split('_.');
      final list = getChapters(int.parse("${chapterList.length}"), newRequest);
      chapterListA.addAll(list);
      hasMoreResults = (limit + offset) < total;
    }

    manga.chapters = chapterListA;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    final urll = "https://api.mangadex.org/at-home/server/$url";

    final res = await MBridge.http('GET', json.encode({"url": urll}));

    final dataRes = json.decode(res);
    final host = dataRes["baseUrl"];
    final hash = dataRes["chapter"]["hash"];
    final chapterDatas = dataRes["chapter"]["data"] as List;
    return chapterDatas.map((e) => "$host/data/$hash/$e").toList();
  }

  MPages mangaRes(String res, MSource sourceInfo) {
    final datasRes = json.decode(res);
    final resJson = datasRes["data"] as List;
    List<MManga> mangaList = [];
    for (var e in resJson) {
      MManga manga = MManga();
      manga.name = findTitle(e, sourceInfo.lang);
      manga.imageUrl = getCover(e);
      manga.link = "/manga/${e["id"]}";
      mangaList.add(manga);
    }
    return MPages(mangaList, true);
  }

  List<MChapter> getChapters(int length, String paginatedChapterListA) {
    List<MChapter> chaptersList = [];
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
        if (data.isNotEmpty) {
          final name = MBridge.getMapValue(data, "name");
          scan += "$name".toString();
          final username = MBridge.getMapValue(data, "username");
          if (username.isNotEmpty) {
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
      if (dataRes.isNotEmpty) {
        final data = MBridge.getMapValue(res, "attributes", encode: true);
        final volume = MBridge.getMapValue(data, "volume");
        if (volume.isNotEmpty) {
          if (volume != "null") {
            chapName = "Vol.$volume ".toString();
          }
        }
        final chapter = MBridge.getMapValue(data, "chapter");
        if (chapter.isNotEmpty) {
          if (chapter != "null") {
            chapName += "Ch.$chapter ".toString();
          }
        }
        final title = MBridge.getMapValue(data, "title");
        if (title.isNotEmpty) {
          if (title != "null") {
            if (chapName.isNotEmpty) {
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
        MChapter chapterr = MChapter();
        chapterr.name = chapName;
        chapterr.url = id;
        chapterr.scanlator = scan;
        chapterr.dateUpload = MBridge.parseDates(
                [date], "yyyy-MM-dd'T'HH:mm:ss+SSS", "en_US")
            .first;
        chaptersList.add(chapterr);
      }
    }

    return chaptersList;
  }

  Future<String> paginatedChapterListRequest(
      String mangaId, int offset, String lang) async {
    final url =
        'https://api.mangadex.org/manga/$mangaId/feed?limit=500&offset=$offset&includes[]=user&includes[]=scanlation_group&order[volume]=desc&order[chapter]=desc&translatedLanguage[]=$lang&includeFuturePublishAt=0&includeEmptyPages=0${getMDXContentRating()}';
    final res = await MBridge.http('GET', json.encode({"url": url}));
    return res;
  }

  String getMDXContentRating() {
    String ctnRating =
        "&contentRating[]=suggestive&contentRating[]=safe&contentRating[]=erotica&contentRating[]=pornographic";
    return ctnRating;
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

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    return [];
  }
}

MangaDex main() {
  return MangaDex();
}

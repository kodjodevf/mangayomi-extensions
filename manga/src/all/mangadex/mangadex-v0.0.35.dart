import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaDex extends MProvider {
  MangaDex();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    page = (20 * (page - 1));
    final url =
        "https://api.mangadex.org/manga?limit=20&offset=$page&availableTranslatedLanguage[]=en&includes[]=cover_art${getMDXContentRating()}&order[followedCount]=desc";
    final datas = {"url": url};
    final res = await http('GET', json.encode(datas));
    return mangaRes(res, source);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    page = (20 * (page - 1));
    final urll =
        "https://api.mangadex.org/chapter?limit=20&offset=$page&translatedLanguage[]=${source.lang}&includeFutureUpdates=0&order[publishAt]=desc&includeFuturePublishAt=0&includeEmptyPages=0";
    final datas = {"url": urll};
    final ress = await http('GET', json.encode(datas));
    final mangaIds =
        jsonPathToString(ress, r'$.data[*].relationships[*].id', '.--')
            .split('.--');
    String mangaIdss = "".toString();
    for (var id in mangaIds) {
      mangaIdss += "&ids[]=$id";
    }
    final newUrl =
        "https://api.mangadex.org/manga?includes[]=cover_art&limit=${mangaIds.length}${getMDXContentRating()}$mangaIdss";
    final res = await http('GET', json.encode({"url": newUrl}));
    return mangaRes(res, source);
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    final url =
        "https://api.mangadex.org/manga?includes[]=cover_art&offset=0&limit=20&title=$query${getMDXContentRating()}&order[followedCount]=desc&availableTranslatedLanguage[]=${source.lang}";

    final res = await http('GET', json.encode({"url": url}));
    return mangaRes(res, source);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"ongoing": 0, "completed": 1, "hiatus": 2, "cancelled": 3}
    ];

    final urll =
        "https://api.mangadex.org$url?includes[]=cover_art&includes[]=author&includes[]=artist";
    final res = await http('GET', json.encode({"url": urll}));
    MManga manga = MManga();
    manga.author = jsonPathToString(
        res, r'$..data.relationships[*].attributes.name', ', ');

    String expressionDescriptionA = r'$..data.attributes.description.en';
    String expressionDescription = regExp(
        r'$..data.attributes.description[a]',
        r'\[a\]',
        ".${source.lang}",
        0,
        1);

    String description =
        jsonPathToString(res, expressionDescription, '');
    if (description.isEmpty) {
      description = jsonPathToString(res, expressionDescriptionA, '');
    }
    manga.description = description;
    List<String> genres = [];

    genres = jsonPathToString(
            res, r'$..data.attributes.tags[*].attributes.name.en', '.-')
        .split('.-');

    String contentRating =
        jsonPathToString(res, r'$..data.attributes.contentRating', '');
    if (contentRating != "safe") {
      genres.add(contentRating);
    }
    String publicationDemographic = jsonPathToString(
        res, r'$..data.attributes.publicationDemographic', '');
    if (publicationDemographic == "null") {
    } else {
      genres.add(publicationDemographic);
    }
    manga.genre = genres;
    String statusRes =
        jsonPathToString(res, r'$..data.attributes.status', '');
    manga.status = parseStatus(statusRes, statusList);
    final mangaId = url.split('/').last;

    final paginatedChapterList =
        await paginatedChapterListRequest(mangaId, 0, source.lang);
    final chapterList =
        jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
            .split('_.');
    int limit = int.parse(
        jsonPathToString(paginatedChapterList, r'$.limit', ''));
    int offset = int.parse(
        jsonPathToString(paginatedChapterList, r'$.offset', ''));
    int total = int.parse(
        jsonPathToString(paginatedChapterList, r'$.total', ''));
    List<MChapter> chapterListA = [];

    final list =
        getChapters(int.parse("${chapterList.length}"), paginatedChapterList);

    chapterListA.addAll(list);
    var hasMoreResults = (limit + offset) < total;
    while (hasMoreResults) {
      offset += limit;
      var newRequest =
          await paginatedChapterListRequest(mangaId, offset, source.lang);
      int total =
          int.parse(jsonPathToString(newRequest, r'$.total', ''));
      final chapterList =
          jsonPathToString(paginatedChapterList, r'$.data[*]', '_.')
              .split('_.');
      final list = getChapters(int.parse("${chapterList.length}"), newRequest);
      chapterListA.addAll(list);
      hasMoreResults = (limit + offset) < total;
    }

    manga.chapters = chapterListA;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource source, String url) async {
    final urll = "https://api.mangadex.org/at-home/server/$url";

    final res = await http('GET', json.encode({"url": urll}));

    final dataRes = json.decode(res);
    final host = dataRes["baseUrl"];
    final hash = dataRes["chapter"]["hash"];
    final chapterDatas = dataRes["chapter"]["data"] as List;
    return chapterDatas.map((e) => "$host/data/$hash/$e").toList();
  }

  MPages mangaRes(String res, MSource source) {
    final datasRes = json.decode(res);
    final resJson = datasRes["data"] as List;
    List<MManga> mangaList = [];
    for (var e in resJson) {
      MManga manga = MManga();
      manga.name = findTitle(e, source.lang);
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
        jsonPathToList(paginatedChapterList, r'$.data[*]', 0);
    for (var res in dataList) {
      String scan = "".toString();
      final groups = jsonPathToList(res,
          r'$.relationships[?@.id!="00e03853-1b96-4f41-9542-c71b8692033b"]', 0);
      String chapName = "".toString();
      for (var element in groups) {
        final data = getMapValue(element, "attributes", encode: true);
        if (data.isNotEmpty) {
          final name = getMapValue(data, "name");
          scan += "$name".toString();
          final username = getMapValue(data, "username");
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
      final dataRes = getMapValue(res, "attributes", encode: true);
      if (dataRes.isNotEmpty) {
        final data = getMapValue(res, "attributes", encode: true);
        final volume = getMapValue(data, "volume");
        if (volume.isNotEmpty) {
          if (volume != "null") {
            chapName = "Vol.$volume ".toString();
          }
        }
        final chapter = getMapValue(data, "chapter");
        if (chapter.isNotEmpty) {
          if (chapter != "null") {
            chapName += "Ch.$chapter ".toString();
          }
        }
        final title = getMapValue(data, "title");
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
        final date = getMapValue(data, "publishAt");
        final id = getMapValue(res, "id");
        MChapter chapterr = MChapter();
        chapterr.name = chapName;
        chapterr.url = id;
        chapterr.scanlator = scan;
        chapterr.dateUpload = parseDates(
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
    final res = await http('GET', json.encode({"url": url}));
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
    final title = getMapValue(json.encode(titleJ), "en");
    if (title.isEmpty) {
      for (var r in altTitlesJ) {
        final altTitle = getMapValue(json.encode(r), "en");
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
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    return [];
  }
}

MangaDex main() {
  return MangaDex();
}

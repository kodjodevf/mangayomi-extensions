import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaDex extends MProvider {
  MangaDex({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    page = (20 * (page - 1));
    final url =
        "https://api.mangadex.org/manga?limit=20&offset=$page&availableTranslatedLanguage[]=${source.lang}&includes[]=cover_art${preferenceContentRating(source.id)}${preferenceOriginalLanguages(source.id)}&order[followedCount]=desc";
    final res = (await client.get(Uri.parse(url))).body;
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    page = (20 * (page - 1));
    final url =
        "https://api.mangadex.org/chapter?limit=20&offset=$page&translatedLanguage[]=${source.lang}&includeFutureUpdates=0&order[publishAt]=desc&includeFuturePublishAt=0&includeEmptyPages=0";
    final ress = (await client.get(Uri.parse(url))).body;
    final mangaIds =
        jsonPathToString(ress, r'$.data[*].relationships[*].id', '.--')
            .split('.--');
    String mangaIdss = "";
    for (var id in mangaIds) {
      mangaIdss += "&ids[]=$id";
    }
    final newUrl =
        "https://api.mangadex.org/manga?includes[]=cover_art&limit=${mangaIds.length}${preferenceContentRating(source.id)}${preferenceOriginalLanguages(source.id)}$mangaIdss";
    final res = (await client.get(Uri.parse(newUrl))).body;
    return mangaRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    page = (20 * (page - 1));
    final filters = filterList.filters;
    String url = "";

    url =
        "https://api.mangadex.org/manga?includes[]=cover_art&offset=$page&limit=20&title=$query";
    for (var filter in filters) {
      if (filter.type == "HasAvailableChaptersFilter") {
        if (filter.state) {
          url += "${ll(url)}hasAvailableChapters=true";
          url += "${ll(url)}availableTranslatedLanguage[]=${source.lang}";
        }
      } else if (filter.type == "OriginalLanguageList") {
        final langs = (filter.state as List).where((e) => e.state).toList();
        if (langs.isNotEmpty) {
          for (var lang in langs) {
            url += "${ll(url)}${lang.value}";
          }
        }
      } else if (filter.type == "ContentRatingList") {
        final ctns = (filter.state as List).where((e) => e.state).toList();
        if (ctns.isNotEmpty) {
          for (var ctn in ctns) {
            url += "${ll(url)}${ctn.value}";
          }
        }
      } else if (filter.type == "DemographicList") {
        final demogr = (filter.state as List).where((e) => e.state).toList();
        if (demogr.isNotEmpty) {
          for (var demog in demogr) {
            url += "${ll(url)}${demog.value}";
          }
        }
      } else if (filter.type == "StatusList") {
        final statusL = (filter.state as List).where((e) => e.state).toList();
        if (statusL.isNotEmpty) {
          for (var status in statusL) {
            url += "${ll(url)}${status.value}";
          }
        }
      } else if (filter.type == "SortFilter") {
        final value = filter.state.ascending ? "asc" : "desc";
        url +=
            "${ll(url)}order[${filter.values[filter.state.index].value}]=$value";
      } else if (filter.type == "TagsFilter") {
        for (var tag in filter.state) {
          url += "${ll(url)}${tag.values[tag.state].value}";
        }
      } else if (filter.type == "FormatFilter") {
        final included = (filter.state as List)
            .where((e) => e.state == 1 ? true : false)
            .toList();
        final excluded = (filter.state as List)
            .where((e) => e.state == 2 ? true : false)
            .toList();
        if (included.isNotEmpty) {
          for (var val in included) {
            url += "${ll(url)}includedTags[]=${val.value}";
          }
        }
        if (excluded.isNotEmpty) {
          for (var val in excluded) {
            url += "${ll(url)}excludedTags[]=${val.value}";
          }
        }
      } else if (filter.type == "GenreFilter") {
        final included = (filter.state as List)
            .where((e) => e.state == 1 ? true : false)
            .toList();
        final excluded = (filter.state as List)
            .where((e) => e.state == 2 ? true : false)
            .toList();
        if (included.isNotEmpty) {
          for (var val in included) {
            url += "${ll(url)}includedTags[]=${val.value}";
          }
        }
        if (excluded.isNotEmpty) {
          for (var val in excluded) {
            url += "${ll(url)}excludedTags[]=${val.value}";
          }
        }
      } else if (filter.type == "ThemeFilter") {
        final included = (filter.state as List)
            .where((e) => e.state == 1 ? true : false)
            .toList();
        final excluded = (filter.state as List)
            .where((e) => e.state == 2 ? true : false)
            .toList();
        if (included.isNotEmpty) {
          for (var val in included) {
            url += "${ll(url)}includedTags[]=${val.value}";
          }
        }
        if (excluded.isNotEmpty) {
          for (var val in excluded) {
            url += "${ll(url)}excludedTags[]=${val.value}";
          }
        }
      }
    }

    final res = (await client.get(Uri.parse(url))).body;
    return mangaRes(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"ongoing": 0, "completed": 1, "hiatus": 2, "cancelled": 3}
    ];

    final res = (await client.get(Uri.parse(
            "https://api.mangadex.org$url?includes[]=cover_art&includes[]=author&includes[]=artist")))
        .body;
    MManga manga = MManga();
    manga.author = jsonPathToString(
        res, r'$..data.relationships[*].attributes.name', ', ');

    String expressionDescriptionA = r'$..data.attributes.description.en';
    String expressionDescription = regExp(r'$..data.attributes.description[a]',
        r'\[a\]', ".${source.lang}", 0, 1);

    String description = jsonPathToString(res, expressionDescription, '');
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
    String publicationDemographic =
        jsonPathToString(res, r'$..data.attributes.publicationDemographic', '');
    if (publicationDemographic == "null") {
    } else {
      genres.add(publicationDemographic);
    }
    manga.genre = genres;
    String statusRes = jsonPathToString(res, r'$..data.attributes.status', '');
    manga.status = parseStatus(statusRes, statusList);
    final mangaId = url.split('/').last;

    final paginatedChapterList =
        await paginatedChapterListRequest(mangaId, 0, source.lang, source.id);
    final chapterList =
        jsonPathToString(paginatedChapterList, r'$.data[*]', '_.').split('_.');
    int limit =
        int.parse(jsonPathToString(paginatedChapterList, r'$.limit', ''));
    int offset =
        int.parse(jsonPathToString(paginatedChapterList, r'$.offset', ''));
    int total =
        int.parse(jsonPathToString(paginatedChapterList, r'$.total', ''));
    List<MChapter> chapterListA = [];

    final list =
        getChapters(int.parse("${chapterList.length}"), paginatedChapterList);

    chapterListA.addAll(list);
    var hasMoreResults = (limit + offset) < total;
    while (hasMoreResults) {
      offset += limit;
      var newRequest = await paginatedChapterListRequest(
          mangaId, offset, source.lang, source.id);
      int total = int.parse(jsonPathToString(newRequest, r'$.total', ''));
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
  Future<List<String>> getPageList(String url) async {
    final res = (await client
            .get(Uri.parse("https://api.mangadex.org/at-home/server/$url")))
        .body;

    final host = getMapValue(res, "baseUrl");
    final chapter = getMapValue(res, "chapter", encode: true);
    final hash = getMapValue(chapter, "hash");
    final chapterDatas =
        json.decode(getMapValue(chapter, "data", encode: true)) as List;
    return chapterDatas.map((e) => "$host/data/$hash/$e").toList();
  }

  MPages mangaRes(String res) {
    final datasRes = getMapValue(res, "data", encode: true);

    final resJson = json.decode(datasRes) as List;
    List<MManga> mangaList = [];
    for (var e in resJson) {
      MManga manga = MManga();
      manga.name = findTitle(json.encode(e), source.lang);
      manga.imageUrl = getCover(json.encode(e), source.id);
      manga.link = "/manga/${getMapValue(json.encode(e), "id")}";
      mangaList.add(manga);
    }
    return MPages(mangaList, true);
  }

  List<MChapter> getChapters(int length, String paginatedChapterListA) {
    List<MChapter> chaptersList = [];
    String paginatedChapterList = paginatedChapterListA;
    final dataList = jsonPathToList(paginatedChapterList, r'$.data[*]', 0);
    for (var res in dataList) {
      String scan = "";
      final groups = jsonPathToList(res,
          r'$.relationships[?@.id!="00e03853-1b96-4f41-9542-c71b8692033b"]', 0);
      String chapName = "";
      for (var element in groups) {
        final data = getMapValue(element, "attributes", encode: true);
        if (data.isNotEmpty) {
          final name = getMapValue(data, "name");
          scan += "$name";
          final username = getMapValue(data, "username");
          if (username.isNotEmpty) {
            if (scan.isEmpty) {
              scan += "Uploaded by $username";
            }
          }
        }
      }
      if (scan.isEmpty) {
        scan = "No Group";
      }
      final dataRes = getMapValue(res, "attributes", encode: true);
      if (dataRes.isNotEmpty) {
        final data = getMapValue(res, "attributes", encode: true);
        final volume = getMapValue(data, "volume");
        if (volume.isNotEmpty) {
          if (volume != "null") {
            chapName = "Vol.$volume ";
          }
        }
        final chapter = getMapValue(data, "chapter");
        if (chapter.isNotEmpty) {
          if (chapter != "null") {
            chapName += "Ch.$chapter ";
          }
        }
        final title = getMapValue(data, "title");
        if (title.isNotEmpty) {
          if (title != "null") {
            if (chapName.isNotEmpty) {
              chapName += "- ";
            }
            chapName += "$title";
          }
        }
        if (chapName.isEmpty) {
          chapName += "Oneshot";
        }
        final date = getMapValue(data, "publishAt");
        final id = getMapValue(res, "id");
        MChapter chapterr = MChapter();
        chapterr.name = chapName;
        chapterr.url = id;
        chapterr.scanlator = scan;
        chapterr.dateUpload =
            parseDates([date], "yyyy-MM-dd'T'HH:mm:ss+SSS", "en_US").first;
        chaptersList.add(chapterr);
      }
    }

    return chaptersList;
  }

  Future<String> paginatedChapterListRequest(
      String mangaId, int offset, String lang, int sourceId) async {
    final url =
        'https://api.mangadex.org/manga/$mangaId/feed?limit=500&offset=$offset&includes[]=user&includes[]=scanlation_group&order[volume]=desc&order[chapter]=desc&translatedLanguage[]=$lang&includeFuturePublishAt=0&includeEmptyPages=0${preferenceContentRating(sourceId)}';
    final res = (await client.get(Uri.parse(url))).body;
    return res;
  }

  String findTitle(String dataRes, String lang) {
    final attributes = getMapValue(dataRes, "attributes", encode: true);
    final altTitlesJ =
        json.decode(getMapValue(attributes, "altTitles", encode: true));
    final titleJ = getMapValue(attributes, "title", encode: true);
    final title = getMapValue(titleJ, "en");
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

  String getCover(String dataRes, int sourceId) {
    final coverQuality = getPreferenceValue(sourceId, "cover_quality");
    final relationships = json
        .decode(getMapValue(dataRes, "relationships", encode: true)) as List;
    String coverFileName = "".toString();
    for (var a in relationships) {
      final relationType = getMapValue(json.encode(a), "type");
      if (relationType == "cover_art") {
        if (coverFileName.isEmpty) {
          final attributes =
              getMapValue(json.encode(a), "attributes", encode: true);
          coverFileName =
              "https://uploads.mangadex.org/covers/${getMapValue(dataRes, "id")}/${getMapValue(attributes, "fileName")}$coverQuality";
        }
      }
    }
    return coverFileName;
  }

  @override
  List<dynamic> getFilterList() {
    return [
      CheckBoxFilter(
          "Has available chapters", "", "HasAvailableChaptersFilter"),
      GroupFilter("OriginalLanguageList", "Original language", [
        CheckBoxFilter("Japanese (Manga)", "originalLanguage[]=ja"),
        CheckBoxFilter("Chinese (Manhua)",
            "originalLanguage[]=zh&originalLanguage[]=zh-hk"),
        CheckBoxFilter("Korean (Manhwa)", "originalLanguage[]=ko"),
      ]),
      GroupFilter("ContentRatingList", "Content rating", [
        CheckBoxFilter("Safe", "contentRating[]=safe", state: true),
        CheckBoxFilter("Suggestive", "contentRating[]=suggestive", state: true),
        CheckBoxFilter("Erotica", "contentRating[]=erotica"),
        CheckBoxFilter("Pornographic", "contentRating[]=pornographic"),
      ]),
      GroupFilter("DemographicList", "Publication demographic", [
        CheckBoxFilter("None", "publicationDemographic[]=none"),
        CheckBoxFilter("Shounen", "publicationDemographic[]=shounen"),
        CheckBoxFilter("Shoujo", "publicationDemographic[]=shoujo"),
        CheckBoxFilter("Seinen", "publicationDemographic[]=seinen"),
        CheckBoxFilter("Josei", "publicationDemographic[]=josei"),
      ]),
      GroupFilter("StatusList", "Status", [
        CheckBoxFilter("Ongoing", "status[]=ongoing"),
        CheckBoxFilter("Completed", "status[]=completed"),
        CheckBoxFilter("Hiatus", "status[]=hiatus"),
        CheckBoxFilter("Cancelled", "status[]=cancelled"),
      ]),
      SortFilter("SortFilter", "Sort", SortState(5, false), [
        SelectFilterOption("Alphabetic", "title"),
        SelectFilterOption("Chapter uploded at", "latestUploadedChapter"),
        SelectFilterOption("Number of follows", "followedCount"),
        SelectFilterOption("Content created at", "createdAt"),
        SelectFilterOption("Content info updated at", "updatedAt"),
        SelectFilterOption("Relevance", "relevance"),
        SelectFilterOption("Year", "year"),
        SelectFilterOption("Rating", "rating"),
      ]),
      GroupFilter("TagsFilter", "Tags mode", [
        SelectFilter("TagInclusionMode", "Included tags mode", 0, [
          SelectFilterOption("AND", "includedTagsMode=AND"),
          SelectFilterOption("OR", "includedTagsMode=OR"),
        ]),
        SelectFilter("TagExclusionMode", "Excluded tags mode", 1, [
          SelectFilterOption("AND", "excludedTagsMode=AND"),
          SelectFilterOption("OR", "excludedTagsMode=OR"),
        ]),
      ]),
      GroupFilter("ContentsFilter", "Content", [
        TriStateFilter("Gore", "b29d6a3d-1569-4e7a-8caf-7557bc92cd5d"),
        TriStateFilter(
            "Sexual Violence", "97893a4c-12af-4dac-b6be-0dffb353568e"),
      ]),
      GroupFilter("FormatFilter", "Format", [
        TriStateFilter("4-Koma", "b11fda93-8f1d-4bef-b2ed-8803d3733170"),
        TriStateFilter("Adaptation", "f4122d1c-3b44-44d0-9936-ff7502c39ad3"),
        TriStateFilter("Anthology", "51d83883-4103-437c-b4b1-731cb73d786c"),
        TriStateFilter("Award Winning", "0a39b5a1-b235-4886-a747-1d05d216532d"),
        TriStateFilter("Doujinshi", "b13b2a48-c720-44a9-9c77-39c9979373fb"),
        TriStateFilter("Fan Colored", "7b2ce280-79ef-4c09-9b58-12b7c23a9b78"),
        TriStateFilter("Full Color", "f5ba408b-0e7a-484d-8d49-4e9125ac96de"),
        TriStateFilter("Long Strip", "3e2b8dae-350e-4ab8-a8ce-016e844b9f0d"),
        TriStateFilter(
            "Official Colored", "320831a8-4026-470b-94f6-8353740e6f04"),
        TriStateFilter("Oneshot", "0234a31e-a729-4e28-9d6a-3f87c4966b9e"),
        TriStateFilter("User Created", "891cf039-b895-47f0-9229-bef4c96eccd4"),
        TriStateFilter("Web Comic", "e197df38-d0e7-43b5-9b09-2842d0c326dd"),
      ]),
      GroupFilter("GenreFilter", "Genre", [
        TriStateFilter("Action", "391b0423-d847-456f-aff0-8b0cfc03066b"),
        TriStateFilter("Adventure", "87cc87cd-a395-47af-b27a-93258283bbc6"),
        TriStateFilter("Boys' Love", "5920b825-4181-4a17-beeb-9918b0ff7a30"),
        TriStateFilter("Comedy", "4d32cc48-9f00-4cca-9b5a-a839f0764984"),
        TriStateFilter("Crime", "5ca48985-9a9d-4bd8-be29-80dc0303db72"),
        TriStateFilter("Drama", "b9af3a63-f058-46de-a9a0-e0c13906197a"),
        TriStateFilter("Fantasy", "cdc58593-87dd-415e-bbc0-2ec27bf404cc"),
        TriStateFilter("Girls' Love", "a3c67850-4684-404e-9b7f-c69850ee5da6"),
        TriStateFilter("Historical", "33771934-028e-4cb3-8744-691e866a923e"),
        TriStateFilter("Horror", "cdad7e68-1419-41dd-bdce-27753074a640"),
        TriStateFilter("Isekai", "ace04997-f6bd-436e-b261-779182193d3d"),
        TriStateFilter("Magical Girls", "81c836c9-914a-4eca-981a-560dad663e73"),
        TriStateFilter("Mecha", "50880a9d-5440-4732-9afb-8f457127e836"),
        TriStateFilter("Medical", "c8cbe35b-1b2b-4a3f-9c37-db84c4514856"),
        TriStateFilter("Mystery", "ee968100-4191-4968-93d3-f82d72be7e46"),
        TriStateFilter("Philosophical", "b1e97889-25b4-4258-b28b-cd7f4d28ea9b"),
        TriStateFilter("Psychological", "3b60b75c-a2d7-4860-ab56-05f391bb889c"),
        TriStateFilter("Romance", "423e2eae-a7a2-4a8b-ac03-a8351462d71d"),
        TriStateFilter("Sci-Fi", "256c8bd9-4904-4360-bf4f-508a76d67183"),
        TriStateFilter("Slice of Life", "e5301a23-ebd9-49dd-a0cb-2add944c7fe9"),
        TriStateFilter("Sports", "69964a64-2f90-4d33-beeb-f3ed2875eb4c"),
        TriStateFilter("Superhero", "7064a261-a137-4d3a-8848-2d385de3a99c"),
        TriStateFilter("Thriller", "07251805-a27e-4d59-b488-f0bfbec15168"),
        TriStateFilter("Tragedy", "f8f62932-27da-4fe4-8ee1-6779a8c5edba"),
        TriStateFilter("Wuxia", "acc803a4-c95a-4c22-86fc-eb6b582d82a2"),
      ]),
      GroupFilter("ThemeFilter", "Theme", [
        TriStateFilter("Aliens", "e64f6742-c834-471d-8d72-dd51fc02b835"),
        TriStateFilter("Animals", "3de8c75d-8ee3-48ff-98ee-e20a65c86451"),
        TriStateFilter("Cooking", "ea2bc92d-1c26-4930-9b7c-d5c0dc1b6869"),
        TriStateFilter("Crossdressing", "9ab53f92-3eed-4e9b-903a-917c86035ee3"),
        TriStateFilter("Delinquents", "da2d50ca-3018-4cc0-ac7a-6b7d472a29ea"),
        TriStateFilter("Demons", "39730448-9a5f-48a2-85b0-a70db87b1233"),
        TriStateFilter("Genderswap", "2bd2e8d0-f146-434a-9b51-fc9ff2c5fe6a"),
        TriStateFilter("Ghosts", "3bb26d85-09d5-4d2e-880c-c34b974339e9"),
        TriStateFilter("Gyaru", "fad12b5e-68ba-460e-b933-9ae8318f5b65"),
        TriStateFilter("Harem", "aafb99c1-7f60-43fa-b75f-fc9502ce29c7"),
        TriStateFilter("Incest", "5bd0e105-4481-44ca-b6e7-7544da56b1a3"),
        TriStateFilter("Loli", "2d1f5d56-a1e5-4d0d-a961-2193588b08ec"),
        TriStateFilter("Mafia", "85daba54-a71c-4554-8a28-9901a8b0afad"),
        TriStateFilter("Magic", "a1f53773-c69a-4ce5-8cab-fffcd90b1565"),
        TriStateFilter("Martial Arts", "799c202e-7daa-44eb-9cf7-8a3c0441531e"),
        TriStateFilter("Military", "ac72833b-c4e9-4878-b9db-6c8a4a99444a"),
        TriStateFilter("Monster Girls", "dd1f77c5-dea9-4e2b-97ae-224af09caf99"),
        TriStateFilter("Monsters", "36fd93ea-e8b8-445e-b836-358f02b3d33d"),
        TriStateFilter("Music", "f42fbf9e-188a-447b-9fdc-f19dc1e4d685"),
        TriStateFilter("Ninja", "489dd859-9b61-4c37-af75-5b18e88daafc"),
        TriStateFilter(
            "Office Workers", "92d6d951-ca5e-429c-ac78-451071cbf064"),
        TriStateFilter("Police", "df33b754-73a3-4c54-80e6-1a74a8058539"),
        TriStateFilter(
            "Post-Apocalyptic", "9467335a-1b83-4497-9231-765337a00b96"),
        TriStateFilter("Reincarnation", "0bc90acb-ccc1-44ca-a34a-b9f3a73259d0"),
        TriStateFilter("Reverse Harem", "65761a2a-415e-47f3-bef2-a9dababba7a6"),
        TriStateFilter("Samurai", "81183756-1453-4c81-aa9e-f6e1b63be016"),
        TriStateFilter("School Life", "caaa44eb-cd40-4177-b930-79d3ef2afe87"),
        TriStateFilter("Shota", "ddefd648-5140-4e5f-ba18-4eca4071d19b"),
        TriStateFilter("Supernatural", "eabc5b4c-6aff-42f3-b657-3e90cbd00b75"),
        TriStateFilter("Survival", "5fff9cde-849c-4d78-aab0-0d52b2ee1d25"),
        TriStateFilter("Time Travel", "292e862b-2d17-4062-90a2-0356caa4ae27"),
        TriStateFilter(
            "Traditional Games", "31932a7e-5b8e-49a6-9f12-2afa39dc544c"),
        TriStateFilter("Vampires", "d7d1730f-6eb0-4ba6-9437-602cac38664c"),
        TriStateFilter("Video Games", "9438db5a-7e2a-4ac0-b39e-e0d95a34b8a8"),
        TriStateFilter("Villainess", "d14322ac-4d6f-4e9b-afd9-629d5f4d8a41"),
        TriStateFilter(
            "Virtual Reality", "8c86611e-fab7-4986-9dec-d1a2f44acdd5"),
        TriStateFilter("Zombies", "631ef465-9aba-4afb-b0fc-ea10efe274a8"),
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "cover_quality",
          title: "Cover quality",
          summary: "",
          valueIndex: 0,
          entries: ["Original", "Medium", "Low"],
          entryValues: ["", ".512.jpg", ".256.jpg"]),
      MultiSelectListPreference(
          key: "content_rating",
          title: "Default content rating",
          summary: "Show content with the selected rating by default",
          valueIndex: 0,
          entries: [
            "safe",
            "suggestive",
            "erotica",
            "pornographic"
          ],
          entryValues: [
            "contentRating[]=safe",
            "contentRating[]=suggestive",
            "contentRating[]=erotica",
            "contentRating[]=pornographic"
          ],
          values: [
            "contentRating[]=safe",
            "contentRating[]=suggestive"
          ]),
      MultiSelectListPreference(
          key: "original_languages",
          title: "Filter original languages",
          summary:
              "Only show content that was originaly published in the selected languages in both latest and browse",
          valueIndex: 0,
          entries: [
            "Japanese",
            "Chinese",
            "Korean"
          ],
          entryValues: [
            "originalLanguage[]=ja",
            "originalLanguage[]=zh&originalLanguage[]=zh-hk",
            "originalLanguage[]=ko"
          ],
          values: []),
    ];
  }

  String preferenceContentRating(int sourceId) {
    final contentRating =
        getPreferenceValue(sourceId, "content_rating") as List<String>;
    String contentRatingStr = "";
    if (contentRating.isNotEmpty) {
      contentRatingStr = "&";
      for (var ctn in contentRating) {
        contentRatingStr += "&$ctn";
      }
    }
    return contentRatingStr;
  }

  String preferenceOriginalLanguages(int sourceId) {
    final originalLanguages =
        getPreferenceValue(sourceId, "original_languages") as List<String>;
    String originalLanguagesStr = "";
    if (originalLanguages.isNotEmpty) {
      originalLanguagesStr = "&";
      for (var language in originalLanguages) {
        originalLanguagesStr += "&$language";
      }
    }
    return originalLanguagesStr;
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

MangaDex main(MSource source) {
  return MangaDex(source: source);
}

import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class ComickFun extends MProvider {
  ComickFun({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(
            Uri.parse(
                "${source.apiUrl}/v1.0/search?sort=follow&page=$page&tachiyomi=true"),
            headers: getHeader(source.baseUrl)))
        .body;
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(
            Uri.parse(
                "${source.apiUrl}/v1.0/search?sort=uploaded&page=$page&tachiyomi=true"),
            headers: getHeader(source.baseUrl)))
        .body;
    return mangaRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    if (query.isNotEmpty) {
      url = "${source.apiUrl}/v1.0/search?q=$query&tachiyomi=true";
    } else {
      url = "${source.apiUrl}/v1.0/search";
      for (var filter in filters) {
        if (filter.type == "CompletedFilter") {
          if (filter.state) {
            url += "${ll(url)}completed=true";
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
              url += "${ll(url)}genres=${val.value}";
            }
          }
          if (excluded.isNotEmpty) {
            for (var val in excluded) {
              url += "${ll(url)}excludes=${val.value}";
            }
          }
        } else if (filter.type == "DemographicFilter") {
          final included = (filter.state as List)
              .where((e) => e.state == 1 ? true : false)
              .toList();
          if (included.isNotEmpty) {
            for (var val in included) {
              url += "${ll(url)}demographic=${val.value}";
            }
          }
        } else if (filter.type == "TypeFilter") {
          final country = (filter.state as List).where((e) => e.state).toList();
          if (country.isNotEmpty) {
            for (var coun in country) {
              url += "${ll(url)}country=${coun.value}";
            }
          }
        } else if (filter.type == "SortFilter") {
          url += "${ll(url)}sort=${filter.values[filter.state].value}";
        } else if (filter.type == "StatusFilter") {
          url += "${ll(url)}status=${filter.values[filter.state].value}";
        } else if (filter.type == "CreatedAtFilter") {
          if (filter.state > 0) {
            url += "${ll(url)}time=${filter.values[filter.state].value}";
          }
        } else if (filter.type == "MinimumFilter") {
          if (filter.state.isNotEmpty) {
            url += "${ll(url)}minimum=${filter.state}";
          }
        } else if (filter.type == "FromYearFilter") {
          if (filter.state.isNotEmpty) {
            url += "${ll(url)}from=${filter.state}";
          }
        } else if (filter.type == "ToYearFilter") {
          if (filter.state.isNotEmpty) {
            url += "${ll(url)}to=${filter.state}";
          }
        } else if (filter.type == "TagFilter") {
          if (filter.state.isNotEmpty) {
            final tags = (filter.state as String).split(",");
            for (var tag in tags) {
              url += "${ll(url)}tags=$tag";
            }
          }
        }
      }
      url += "${ll(url)}page=$page&tachiyomi=true";
    }

    final res =
        (await client.get(Uri.parse(url), headers: getHeader(source.baseUrl)))
            .body;
    return mangaRes(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"1": 0, "2": 1, "3": 3, "4": 2}
    ];
    final headers = getHeader(source.baseUrl);
    final res = (await client.get(
            Uri.parse(
                "${source.apiUrl}${url.replaceAll("#", '')}?tachiyomi=true"),
            headers: headers))
        .body;
    MManga manga = MManga();
    manga.author = jsonPathToString(res, r'$.authors[*].name', '');
    manga.genre = jsonPathToString(
            res, r'$.comic.md_comic_md_genres[*].md_genres.name', "_.")
        .split("_.");
    manga.description = jsonPathToString(res, r'$..desc', '');
    manga.status =
        parseStatus(jsonPathToString(res, r'$..comic.status', ''), statusList);
    final chapUrlReq =
        "${source.apiUrl}${url.replaceAll("#", '')}chapters?lang=${source.lang}&tachiyomi=true&page=1";
    final request =
        (await client.get(Uri.parse(chapUrlReq), headers: headers)).body;
    var total = jsonPathToString(request, r'$.total', '');
    final chapterLimit = int.parse(total);
    final newChapUrlReq =
        "${source.apiUrl}${url.replaceAll("#", '')}chapters?limit=$chapterLimit&lang=${source.lang}&tachiyomi=true&page=1";

    final newRequest =
        (await client.get(Uri.parse(newChapUrlReq), headers: headers)).body;

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
  Future<List<String>> getPageList(String url) async {
    final res = (await client.get(
            Uri.parse("${source.apiUrl}/chapter/$url?tachiyomi=true"),
            headers: getHeader(url)))
        .body;
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

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("The filter is ignored when using text search."),
      GroupFilter("GenreFilter", "Genre", [
        {
          "type": "TriState",
          "filter": {"name": "4-Koma", "value": "4-koma"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Action", "value": "action"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Adaptation", "value": "adaptation"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Adult", "value": "adult"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Adventure", "value": "adventure"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Aliens", "value": "aliens"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Animals", "value": "animals"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Anthology", "value": "anthology"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Award Winning", "value": "award-winning"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Comedy", "value": "comedy"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Cooking", "value": "cooking"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Crime", "value": "crime"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Crossdressing", "value": "crossdressing"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Delinquents", "value": "delinquents"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Demons", "value": "demons"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Doujinshi", "value": "doujinshi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Drama", "value": "drama"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Ecchi", "value": "ecchi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Fan Colored", "value": "fan-colored"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Fantasy", "value": "fantasy"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Full Color", "value": "full-color"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Gender Bender", "value": "gender-bender"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Genderswap", "value": "genderswap"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Ghosts", "value": "ghosts"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Gore", "value": "gore"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Gyaru", "value": "gyaru"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Harem", "value": "harem"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Historical", "value": "historical"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Horror", "value": "horror"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Incest", "value": "incest"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Isekai", "value": "isekai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Loli", "value": "loli"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Long Strip", "value": "long-strip"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Mafia", "value": "mafia"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Magic", "value": "magic"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Magical Girls", "value": "magical-girls"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Martial Arts", "value": "martial-arts"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Mature", "value": "mature"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Mecha", "value": "mecha"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Medical", "value": "medical"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Military", "value": "military"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Monster Girls", "value": "monster-girls"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Monsters", "value": "monsters"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Music", "value": "music"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Mystery", "value": "mystery"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Ninja", "value": "ninja"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Office Workers", "value": "office-workers"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Official Colored", "value": "official-colored"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Oneshot", "value": "oneshot"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Philosophical", "value": "philosophical"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Police", "value": "police"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Post-Apocalyptic", "value": "post-apocalyptic"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Psychological", "value": "psychological"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Reincarnation", "value": "reincarnation"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Reverse Harem", "value": "reverse-harem"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Romance", "value": "romance"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Samurai", "value": "samurai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "School Life", "value": "school-life"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Sci-Fi", "value": "sci-fi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Sexual Violence", "value": "sexual-violence"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shota", "value": "shota"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shoujo Ai", "value": "shoujo-ai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shounen Ai", "value": "shounen-ai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Slice of Life", "value": "slice-of-life"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Smut", "value": "smut"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Sports", "value": "sports"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Superhero", "value": "superhero"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Supernatural", "value": "supernatural"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Survival", "value": "survival"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Thriller", "value": "thriller"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Time Travel", "value": "time-travel"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Traditional Games", "value": "traditional-games"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Tragedy", "value": "tragedy"}
        },
        {
          "type": "TriState",
          "filter": {"name": "User Created", "value": "user-created"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Vampires", "value": "vampires"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Video Games", "value": "video-games"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Villainess", "value": "villainess"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Virtual Reality", "value": "virtual-reality"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Web Comic", "value": "web-comic"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Wuxia", "value": "wuxia"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Yaoi", "value": "yaoi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Yuri", "value": "yuri"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Zombies", "value": "zombies"}
        }
      ]),
      GroupFilter("DemographicFilter", "Demographic", [
        TriStateFilter("Shounen", "1"),
        TriStateFilter("Shoujo", "2"),
        TriStateFilter("Seinen", "3"),
        TriStateFilter("Josei", "4"),
      ]),
      GroupFilter("TypeFilter", "Type", [
        CheckBoxFilter("Manga", "jp"),
        CheckBoxFilter("Manhwa", "kr"),
        CheckBoxFilter("Manhua", "cn"),
      ]),
      SelectFilter("SortFilter", "Sort", 0, [
        SelectFilterOption("Most popular", "follow"),
        SelectFilterOption("Most follows", "user_follow_count"),
        SelectFilterOption("Most views", "view"),
        SelectFilterOption("High rating", "rating"),
        SelectFilterOption("Last updated", "uploaded"),
        SelectFilterOption("Newest", "created_at"),
      ]),
      SelectFilter("StatusFilter", "Status", 0, [
        SelectFilterOption("All", "0"),
        SelectFilterOption("Ongoing", "1"),
        SelectFilterOption("Completed", "2"),
        SelectFilterOption("Cancelled", "3"),
        SelectFilterOption("Hiatus", "4"),
      ]),
      CheckBoxFilter("Completely Scanlated?", "", "CompletedFilter"),
      SelectFilter("CreatedAtFilter", "Created at", 0, [
        SelectFilterOption("", ""),
        SelectFilterOption("3 days", "3"),
        SelectFilterOption("7 days", "7"),
        SelectFilterOption("30 days", "30"),
        SelectFilterOption("3 months", "90"),
        SelectFilterOption("6 months", "180"),
        SelectFilterOption("1 year", "365"),
      ]),
      TextFilter("MinimumFilter", "Minimum Chapters"),
      HeaderFilter("From Year, ex: 2010"),
      TextFilter("FromYearFilter", "From"),
      HeaderFilter("To Year, ex: 2021"),
      TextFilter("ToYearFilter", "To"),
      HeaderFilter("Separate tags with commas"),
      TextFilter("TagFilter", "Tags")
    ];
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
}

Map<String, String> getHeader(String url) {
  final headers = {
    "Referer": "$url/",
    'User-Agent':
        "Tachiyomi Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:110.0) Gecko/20100101 Firefox/110.0"
  };
  return headers;
}

ComickFun main(MSource source) {
  return ComickFun(source: source);
}

import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class NepNep extends MProvider {
  NepNep({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}/search/"))).body;
    final directory = directoryFromDocument(res);
    final resSort = sortMapList(json.decode(directory), "vm", 1);

    return parseDirectory(resSort);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}/search/"))).body;
    final directory = directoryFromDocument(res);
    final resSort = sortMapList(json.decode(directory), "lt", 1);

    return parseDirectory(resSort);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    List<dynamic> queryRes = [];
    final res = (await client.get(Uri.parse("${source.baseUrl}/search/"))).body;

    final directory = directoryFromDocument(res);
    final resSort = sortMapList(json.decode(directory), "lt", 1);
    final datas = json.decode(resSort) as List;
    queryRes =
        datas.where((e) {
          String name = getMapValue(json.encode(e), 's');
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList();

    for (var filter in filters) {
      if (filter.type == "SortFilter") {
        final ascending = filter.state.ascending;
        String sortBy = "s";
        if (filter.state.index == 1) {
          sortBy = "v";
        }
        if (filter.state.index == 2) {
          sortBy = "ls";
        }
        queryRes = json.decode(sortMapList(queryRes, sortBy, 1)) as List;
        if (ascending) {
          queryRes = queryRes.reversed.toList();
        }
      }
      if (filter.type == "ScanStatusFilter") {
        if (filter.state != 0) {
          queryRes =
              queryRes.where((e) {
                final value = getMapValue(json.encode(e), 'ss');
                return value.toLowerCase().contains(
                  (filter.values[filter.state].value as String).toLowerCase(),
                );
              }).toList();
        }
      } else if (filter.type == "PublishStatusFilter") {
        if (filter.state != 0) {
          queryRes =
              queryRes.where((e) {
                final value = getMapValue(json.encode(e), 'ps');
                return value.toLowerCase().contains(
                  (filter.values[filter.state].value as String).toLowerCase(),
                );
              }).toList();
        }
      } else if (filter.type == "TypeFilter") {
        if (filter.state != 0) {
          queryRes =
              queryRes.where((e) {
                final value = getMapValue(json.encode(e), 't');
                return value.toLowerCase().contains(
                  (filter.values[filter.state].value as String).toLowerCase(),
                );
              }).toList();
        }
      } else if (filter.type == "TranslationFilter") {
        if (filter.state != 0) {
          queryRes =
              queryRes.where((e) {
                final value = getMapValue(json.encode(e), 'o');
                return value.toLowerCase().contains("yes");
              }).toList();
        }
      } else if (filter.type == "YearFilter") {
        if (filter.state.isNotEmpty) {
          queryRes =
              queryRes.where((e) {
                final value = getMapValue(json.encode(e), 'y');
                return value.toLowerCase().contains(
                  (filter.name as String).toLowerCase(),
                );
              }).toList();
        }
      } else if (filter.type == "AuthorFilter") {
        if (filter.state.isNotEmpty) {
          queryRes =
              queryRes.where((e) {
                final value = getMapValue(json.encode(e), 'a');
                return value.toLowerCase().contains(
                  (filter.name as String).toLowerCase(),
                );
              }).toList();
        }
      } else if (filter.type == "GenresFilter") {
        final included =
            (filter.state as List)
                .where((e) => e.state == 1 ? true : false)
                .toList();
        final excluded =
            (filter.state as List)
                .where((e) => e.state == 2 ? true : false)
                .toList();
        if (included.isNotEmpty) {
          for (var val in included) {
            queryRes =
                queryRes.where((e) {
                  final value = getMapValue(json.encode(e), 'g');
                  return value.toLowerCase().contains(
                    (val.value as String).toLowerCase(),
                  );
                }).toList();
          }
        }
        if (excluded.isNotEmpty) {
          for (var val in excluded) {
            queryRes =
                queryRes.where((e) {
                  final value = getMapValue(json.encode(e), 'g');
                  return !(value.toLowerCase().contains(
                    (val.value as String).toLowerCase(),
                  ));
                }).toList();
          }
        }
      }
    }

    return parseDirectory(json.encode(queryRes));
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1, "Cancelled": 3, "Hiatus": 2},
    ];
    final headers = getHeader(source.baseUrl);
    final res =
        (await client.get(
          Uri.parse('${source.baseUrl}/manga/$url'),
          headers: headers,
        )).body;
    MManga manga = MManga();
    manga.author =
        xpath(
          res,
          '//li[contains(@class,"list-group-item") and contains(text(),"Author")]/a/text()',
        ).first;
    manga.description =
        xpath(
          res,
          '//li[contains(@class,"list-group-item") and contains(text(),"Description:")]/div/text()',
        ).first;
    final status =
        xpath(
          res,
          '//li[contains(@class,"list-group-item") and contains(text(),"Status")]/a/text()',
        ).first;

    manga.status = parseStatus(toStatus(status), statusList);
    manga.genre = xpath(
      res,
      '//li[contains(@class,"list-group-item") and contains(text(),"Genre(s)")]/a/text()',
    );

    final script =
        xpath(res, '//script[contains(text(), "MainFunction")]/text()').first;
    final vmChapters = substringBefore(
      substringAfter(script, "vm.Chapters = "),
      ";",
    );
    final chapters = json.decode(vmChapters) as List;

    List<MChapter> chaptersList = [];

    for (var ch in chapters) {
      final c = json.encode(ch);
      MChapter chapter = MChapter();
      String name = getMapValue(c, 'ChapterName');
      String indexChapter = getMapValue(c, 'Chapter');
      if (name.isEmpty) {
        name = '${getMapValue(c, 'Type')} ${chapterImage(indexChapter, true)}';
      }
      chapter.name = name == "null" ? "" : name;
      chapter.url =
          '/read-online/${substringAfter(url, "/manga/")}${chapterURLEncode(getMapValue(c, 'Chapter'))}';
      chapter.dateUpload =
          parseDates(
            [getMapValue(c, 'Date')],
            source.dateFormat,
            source.dateFormatLocale,
          ).first;
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final headers = getHeader(source.baseUrl);
    List<String> pages = [];
    final res =
        (await client.get(
          Uri.parse('${source.baseUrl}$url'),
          headers: headers,
        )).body;
    final script =
        xpath(res, '//script[contains(text(), "MainFunction")]/text()').first;
    final chapScript = substringBefore(
      substringAfter(script, "vm.CurChapter = "),
      ";",
    );
    final pathName = substringBefore(
      substringAfter(script, "vm.CurPathName = \"", ""),
      "\"",
    );
    var directory =
        getMapValue(chapScript, 'Directory') == 'null'
            ? ''
            : getMapValue(chapScript, 'Directory');
    if (directory.length > 0) {
      directory += '/';
    }
    final mangaName = substringBefore(
      substringAfter(url, "/read-online/"),
      "-chapter",
    );
    var chNum = chapterImage(getMapValue(chapScript, 'Chapter'), false);
    var totalPages = int.parse(getMapValue(chapScript, 'Page'));
    for (int page = 1; page <= totalPages; page++) {
      String paddedPageNumber = "$page".padLeft(3, '0');
      String pageUrl =
          'https://$pathName/manga/$mangaName/$directory$chNum-$paddedPageNumber.png';

      pages.add(pageUrl);
    }
    return pages;
  }

  String directoryFromDocument(String res) {
    final script =
        xpath(res, '//script[contains(text(), "MainFunction")]/text()').first;
    return substringBefore(
      substringAfter(script, "vm.Directory = "),
      "vm.GetIntValue",
    ).replaceAll(";", " ");
  }

  MPages parseDirectory(String res) {
    List<MManga> mangaList = [];
    final datas = json.decode(res) as List;
    for (var data in datas) {
      final d = json.encode(data);
      MManga manga = MManga();
      manga.name = getMapValue(d, "s");
      manga.imageUrl =
          'https://temp.compsci88.com/cover/${getMapValue(d, "i")}.jpg';
      manga.link = getMapValue(d, "i");
      mangaList.add(manga);
    }
    return MPages(mangaList, true);
  }

  String chapterImage(String e, bool cleanString) {
    var a = e.substring(1, e.length - 1);
    if (cleanString) {
      a = regExp(a, r'^0+', "", 0, 0);
    }

    var b = int.parse(e.substring(e.length - 1));

    if (b == 0 && a.isNotEmpty) {
      return a;
    } else if (b == 0 && a.isEmpty) {
      return '0';
    } else {
      return '$a.$b';
    }
  }

  String toStatus(String status) {
    if (status.contains("Ongoing")) {
      return "Ongoing";
    } else if (status.contains("Complete")) {
      return "Complete";
    } else if (status.contains("Cancelled")) {
      return "Cancelled";
    } else if (status.contains("Hiatus")) {
      return "Hiatus";
    }
    return "";
  }

  String chapterURLEncode(String e) {
    var index = ''.toString();
    var t = int.parse(e.substring(0, 1));

    if (t != 1) {
      index = '-index-$t';
    }

    var dgt = 0;
    var inta = int.parse(e);
    if (inta < 100100) {
      dgt = 4;
    } else if (inta < 101000) {
      dgt = 3;
    } else if (inta < 110000) {
      dgt = 2;
    } else {
      dgt = 1;
    }

    final n = e.substring(dgt, e.length - 1);
    var suffix = ''.toString();
    final path = int.parse(e.substring(e.length - 1));

    if (path != 0) {
      suffix = '.$path';
    }

    return '-chapter-$n$suffix$index.html';
  }

  @override
  List<dynamic> getFilterList() {
    return [
      TextFilter("YearFilter", "Years"),
      TextFilter("AuthorFilter", "Author"),
      SelectFilter("ScanStatusFilter", "Scan Status", 0, [
        SelectFilterOption("Any", "Any"),
        SelectFilterOption("Complete", "Complete"),
        SelectFilterOption("Discontinued", "Discontinued"),
        SelectFilterOption("Hiatus", "Hiatus"),
        SelectFilterOption("Incomplete", "Incomplete"),
        SelectFilterOption("Ongoing", "Ongoing"),
      ]),
      SelectFilter("PublishStatusFilter", "Publish Status", 0, [
        SelectFilterOption("Any", "Any"),
        SelectFilterOption("Cancelled", "Cancelled"),
        SelectFilterOption("Complete", "Complete"),
        SelectFilterOption("Discontinued", "Discontinued"),
        SelectFilterOption("Hiatus", "Hiatus"),
        SelectFilterOption("Incomplete", "Incomplete"),
        SelectFilterOption("Ongoing", "Ongoing"),
        SelectFilterOption("Unfinished", "Unfinished"),
      ]),
      SelectFilter("TypeFilter", "Type", 0, [
        SelectFilterOption("Any", "Any"),
        SelectFilterOption("Doujinshi", "Doujinshi"),
        SelectFilterOption("Manga", "Manga"),
        SelectFilterOption("Manhua", "Manhua"),
        SelectFilterOption("Manhwa", "Manhwa"),
        SelectFilterOption("OEL", "OEL"),
        SelectFilterOption("One-shot", "One-shot"),
      ]),
      SelectFilter("TranslationFilter", "Translation", 0, [
        SelectFilterOption("Any", "Any"),
        SelectFilterOption("Official Only", "Official Only"),
      ]),
      SortFilter("SortFilter", "Sort", SortState(2, false), [
        SelectFilterOption("Alphabetically", "Alphabetically"),
        SelectFilterOption("Date updated", "Date updated"),
        SelectFilterOption("Popularity", "Popularity"),
      ]),
      GroupFilter("GenresFilter", "Genres", [
        TriStateFilter("Action", ""),
        TriStateFilter("Adult", ""),
        TriStateFilter("Adventure", ""),
        TriStateFilter("Comedy", ""),
        TriStateFilter("Doujinshi", ""),
        TriStateFilter("Drama", ""),
        TriStateFilter("Ecchi", ""),
        TriStateFilter("Fantasy", ""),
        TriStateFilter("Gender Bender", ""),
        TriStateFilter("Harem", ""),
        TriStateFilter("Hentai", ""),
        TriStateFilter("Historical", ""),
        TriStateFilter("Horror", ""),
        TriStateFilter("Isekai", ""),
        TriStateFilter("Josei", ""),
        TriStateFilter("Lolicon", ""),
        TriStateFilter("Martial Arts", ""),
        TriStateFilter("Mature", ""),
        TriStateFilter("Mecha", ""),
        TriStateFilter("Mystery", ""),
        TriStateFilter("Psychological", ""),
        TriStateFilter("Romance", ""),
        TriStateFilter("School Life", ""),
        TriStateFilter("Sci-fi", ""),
        TriStateFilter("Seinen", ""),
        TriStateFilter("Shotacon", ""),
        TriStateFilter("Shoujo", ""),
        TriStateFilter("Shoujo Ai", ""),
        TriStateFilter("Shounen", ""),
        TriStateFilter("Shounen Ai", ""),
        TriStateFilter("Slice of Life", ""),
        TriStateFilter("Smut", ""),
        TriStateFilter("Sports", ""),
        TriStateFilter("Supernatural", ""),
        TriStateFilter("Tragedy", ""),
        TriStateFilter("Yaoi", ""),
        TriStateFilter("Yuri", ""),
      ]),
    ];
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

Map<String, String> getHeader(String url) {
  final headers = {
    'Referer': '$url/',
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:71.0) Gecko/20100101 Firefox/77.0",
  };
  return headers;
}

NepNep main(MSource source) {
  return NepNep(source: source);
}

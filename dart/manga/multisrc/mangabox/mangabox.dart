import 'package:mangayomi/bridge_lib.dart';

class MangaBox extends MProvider {
  MangaBox({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(
            "${source.baseUrl}/${popularUrlPath(source.name, page)}")))
        .body;
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(
            Uri.parse("${source.baseUrl}/${latestUrlPath(source.name, page)}")))
        .body;
    return mangaRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;

    String url = "";
    if (query.isNotEmpty &&
        (source.name != "Manganato" && source.name != "Mangabat")) {
      url = "${source.baseUrl}/${simpleQueryPath(source.name, page, query)}";
    } else {
      url = source.baseUrl;
      if (source.name == "Manganato" || source.name == "Mangabat") {
        url +=
            "/advanced_search?page=$page&keyw=${normalizeSearchQuery(query)}";
        String genreInclude = "";
        String genreExclude = "";
        for (var filter in filters) {
          if (filter.type == "KeywordFilter") {
            final key = filter.values[filter.state].value;
            url += "${ll(url)}keyt=$key";
          } else if (filter.type == "SortFilter") {
            final sort = filter.values[filter.state].value;
            url += "${ll(url)}orby=$sort";
          } else if (filter.type == "StatusFilter") {
            final status = filter.values[filter.state].value;
            url += "${ll(url)}sts=$status";
          } else if (filter.type == "GenreListFilter") {
            final included = (filter.state as List)
                .where((e) => e.state == 1 ? true : false)
                .toList();
            final excluded = (filter.state as List)
                .where((e) => e.state == 2 ? true : false)
                .toList();
            if (included.isNotEmpty) {
              for (var val in included) {
                genreInclude += "_${val.value}";
              }
            }
            if (excluded.isNotEmpty) {
              for (var val in excluded) {
                genreExclude += "_${val.value}";
              }
            }
          }
        }
        url += "${ll(url)}g_i=$genreInclude";
        url += "${ll(url)}g_e=$genreExclude";
      } else {
        for (var filter in filters) {
          if (filter.type == "SortFilter") {
            final sort = filter.values[filter.state].value;
            url += "${ll(url)}type=$sort";
          } else if (filter.type == "StatusFilter") {
            final status = filter.values[filter.state].value;
            url += "${ll(url)}state=$status";
          } else if (filter.type == "GenreListFilter") {
            final genre = filter.values[filter.state].value;
            url += "${ll(url)}category=$genre";
          }
        }
      }
    }

    final res = (await client.get(Uri.parse(url))).body;

    List<MManga> mangaList = [];
    List<String> urls = [];
    urls = xpath(res,
        '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item" or @class="story_item_right"]/h3/a/@href');
    List<String> names = [];
    names = xpath(res,
        '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item" or @class="story_item_right"]/h3/a/text()');
    final images = xpath(res,
        '//*[@class="search-story-item" or @class="story_item" or @class="content-genres-item"  or @class="list-story-item" or @class="story-item" or @class="list-truyen-item-wrap"]/a/img/@src');
    if (names.isEmpty) {
      urls = xpath(res,
          '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h2/a/@href');
      names = xpath(res,
          '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h2/a/text()');
    }
    if (names.isEmpty) {
      names = xpath(res,
          '//*[@class="search-story-item" or @class="list-story-item"]/a/@title');
      urls = xpath(res,
          '//*[@class="search-story-item" or @class="list-story-item"]/a/@href');
    }
    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1}
    ];
    MManga manga = MManga();
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    manga.author = document.xpathFirst(
            '//*[@class="table-label" and contains(text(), "Author")]/parent::tr/td[2]/text()|//li[contains(text(), "Author")]/a/text()') ??
        "";

    final alternative = document.xpathFirst(
            '//*[@class="table-label" and contains(text(), "Alternative")]/parent::tr/td[2]/text()') ??
        "";

    final description = document.xpathFirst(
            '//*[@id="panel-story-info-description" ]/text() | //*[@id="story_discription" ]/text() | //div[@id="noidungm"]/text()') ??
        "";

    if (description.isNotEmpty) {
      manga.description = description
          .split("summary:", ' ')
          .last
          .split("Summary:", ' ')
          .last
          .replaceAll("\n", ' ')
          .replaceAll("Description :", "");
      if (alternative.isNotEmpty) {
        manga.description =
            "${manga.description}\n\nAlternative Name: $alternative";
      }
    }
    final status = document.xpathFirst(
            '//*[@class="table-label" and contains(text(), "Status")]/parent::tr/td[2]/text() | //li[contains(text(), "Status")]/text() | //li[contains(text(), "Status")]/a/text()') ??
        "";
    if (status.isNotEmpty) {
      manga.status = parseStatus(status.split(":").last.trim(), statusList);
    }
    manga.genre = document.xpath(
        '//*[@class="table-label" and contains(text(), "Genres")]/parent::tr/td[2]/a/text() | //li[contains(text(), "Genres")]/a/text()');
    final chaptersElements = document.select(
        "div.chapter-list div.row, ul.row-content-chapter li, div#chapter_list li");
    List<MChapter>? chaptersList = [];
    for (var element in chaptersElements) {
      final a = element.selectFirst("a");
      MChapter chapter = MChapter();
      chapter.name = a.text;
      final dates = element.select("span");
      String dateStr = "";
      if (dates != null && dates.isNotEmpty) {
        dateStr = dates.last.text;
      } else {
        dateStr = element.selectFirst("ul > li > p")?.text ??
            DateTime.now().toString();
      }
      chapter.url = a.getHref;
      chapter.dateUpload =
          parseDates([dateStr], source.dateFormat, source.dateFormatLocale)[0];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    List<String> pageUrls = [];
    final urls = xpath(res,
        '//div[@class="container-chapter-reader" or @class="panel-read-story"]/img/@src');
    for (var url in urls) {
      if (url.startsWith("https://convert_image_digi.mgicdn.com")) {
        pageUrls
            .add("https://images.weserv.nl/?url=${substringAfter(url, "//")}");
      } else {
        pageUrls.add(url);
      }
    }

    return pageUrls;
  }

  MPages mangaRes(String res) {
    List<MManga> mangaList = [];
    List<String> urls = [];
    urls = xpath(res,
        '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h3/a/@href');
    List<String> names = [];
    names = xpath(res,
        '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h3/a/text()');
    final images = xpath(res,
        '//*[ @class="content-genres-item"  or @class="list-story-item" or @class="story-item" or @class="list-truyen-item-wrap"]/a/img/@src');
    if (names.isEmpty) {
      names = xpath(res, '//*[@class="list-story-item"]/a/@title');
      urls = xpath(res, '//*[@class="list-story-item"]/a/@href');
    }
    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  String popularUrlPath(String sourceName, int page) {
    if (sourceName == "Manganato") {
      return "genre-all/$page?type=topview";
    } else if (sourceName == "Mangabat") {
      return "manga-list-all/$page?type=topview";
    } else if (sourceName == "Mangairo") {
      return "manga-list/type-topview/ctg-all/state-all/page-$page";
    }
    return "manga_list?type=topview&category=all&state=all&page=$page";
  }

  String latestUrlPath(String sourceName, int page) {
    if (sourceName == "Manganato") {
      return "genre-all/$page";
    } else if (sourceName == "Mangabat") {
      return "manga-list-all/$page";
    } else if (sourceName == "Mangairo") {
      return "manga-list/type-latest/ctg-all/state-all/page-$page";
    }
    return "manga_list?type=latest&category=all&state=all&page=$page";
  }

  String simpleQueryPath(String sourceName, int page, String query) {
    if (sourceName == "Mangakakalot") {
      return "search/story/${normalizeSearchQuery(query)}?page=$page";
    } else if (sourceName == "Mangairo") {
      return "list/search/${normalizeSearchQuery(query)}?page=$page";
    } else if (sourceName == "Mangabat") {
      return "search/manga/${normalizeSearchQuery(query)}?page=$page";
    } else if (sourceName == "Manganato") {
      return "search/story/${normalizeSearchQuery(query)}?page=$page";
    }

    return "search/${normalizeSearchQuery(query)}?page=$page";
  }

  String normalizeSearchQuery(String query) {
    String str = query.toLowerCase();
    str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    str = str.replaceAll(RegExp(r'đ'), 'd');
    str = str.replaceAll(
        RegExp(
          r"""!|@|%|\^|\*|\(|\)|\+|=|<|>|\?|/|,|\.|:|;|'| |"|&|#|\[|]|~|-|$|_""",
        ),
        "_");
    str = str.replaceAll(RegExp(r'_+'), '_');
    str = str.replaceAll(RegExp(r'^_+|_+$'), '');
    return str;
  }

  @override
  List<dynamic> getFilterList() {
    if (source.name == "Mangairo") {
      return [];
    }
    return [
      SelectFilter("KeywordFilter", "Keyword search:", 0, [
        SelectFilterOption("Everything", ""),
        SelectFilterOption("Title", "title"),
        SelectFilterOption("Alt title", "alternative"),
        SelectFilterOption("Author", "author"),
      ]),
      SelectFilter("SortFilter", "Order by:", 0, [
        SelectFilterOption("Latest", "latest"),
        SelectFilterOption("Newest", "newest"),
        SelectFilterOption("Top read", "topview"),
      ]),
      SelectFilter("StatusFilter", "Status:", 0, [
        SelectFilterOption("ALL", "all"),
        SelectFilterOption("Completed", "completed"),
        SelectFilterOption("Ongoing", "ongoing"),
        SelectFilterOption("Dropped", "drop"),
      ]),
      if (source.name == "Manganato" || source.name == "Mangabat")
        GroupFilter("GenreListFilter", "Category:", [
          TriStateFilter("Action", "2"),
          TriStateFilter("Adult", "3"),
          TriStateFilter("Adventure", "4"),
          TriStateFilter("Comedy", "6"),
          TriStateFilter("Cooking", "7"),
          TriStateFilter("Doujinshi", "9"),
          TriStateFilter("Drama", "10"),
          TriStateFilter("Ecchi", "11"),
          TriStateFilter("Fantasy", "12"),
          TriStateFilter("Gender bender", "13"),
          TriStateFilter("Harem", "14"),
          TriStateFilter("Historical", "15"),
          TriStateFilter("Horror", "16"),
          TriStateFilter("Isekai", "45"),
          TriStateFilter("Josei", "17"),
          TriStateFilter("Manhua", "44"),
          TriStateFilter("Manhwa", "43"),
          TriStateFilter("Martial arts", "19"),
          TriStateFilter("Mature", "20"),
          TriStateFilter("Mecha", "21"),
          TriStateFilter("Medical", "22"),
          TriStateFilter("Mystery", "24"),
          TriStateFilter("One shot", "25"),
          TriStateFilter("Psychological", "26"),
          TriStateFilter("Romance", "27"),
          TriStateFilter("School life", "28"),
          TriStateFilter("Sci fi", "29"),
          TriStateFilter("Seinen", "30"),
          TriStateFilter("Shoujo", "31"),
          TriStateFilter("Shoujo ai", "32"),
          TriStateFilter("Shounen", "33"),
          TriStateFilter("Shounen ai", "34"),
          TriStateFilter("Slice of life", "35"),
          TriStateFilter("Smut", "36"),
          TriStateFilter("Sports", "37"),
          TriStateFilter("Supernatural", "38"),
          TriStateFilter("Tragedy", "39"),
          TriStateFilter("Webtoons", "40"),
          TriStateFilter("Yaoi", "41"),
          TriStateFilter("Yuri", "42"),
        ]),
      if (source.name != "Manganato" && source.name != "Mangabat")
        SelectFilter("GenreListFilter", "Category:", 0, [
          SelectFilterOption("ALL", "all"),
          SelectFilterOption("Action", "2"),
          SelectFilterOption("Adult", "3"),
          SelectFilterOption("Adventure", "4"),
          SelectFilterOption("Comedy", "6"),
          SelectFilterOption("Cooking", "7"),
          SelectFilterOption("Doujinshi", "9"),
          SelectFilterOption("Drama", "10"),
          SelectFilterOption("Ecchi", "11"),
          SelectFilterOption("Fantasy", "12"),
          SelectFilterOption("Gender bender", "13"),
          SelectFilterOption("Harem", "14"),
          SelectFilterOption("Historical", "15"),
          SelectFilterOption("Horror", "16"),
          SelectFilterOption("Isekai", "45"),
          SelectFilterOption("Josei", "17"),
          SelectFilterOption("Manhua", "44"),
          SelectFilterOption("Manhwa", "43"),
          SelectFilterOption("Martial arts", "19"),
          SelectFilterOption("Mature", "20"),
          SelectFilterOption("Mecha", "21"),
          SelectFilterOption("Medical", "22"),
          SelectFilterOption("Mystery", "24"),
          SelectFilterOption("One shot", "25"),
          SelectFilterOption("Psychological", "26"),
          SelectFilterOption("Romance", "27"),
          SelectFilterOption("School life", "28"),
          SelectFilterOption("Sci fi", "29"),
          SelectFilterOption("Seinen", "30"),
          SelectFilterOption("Shoujo", "31"),
          SelectFilterOption("Shoujo ai", "32"),
          SelectFilterOption("Shounen", "33"),
          SelectFilterOption("Shounen ai", "34"),
          SelectFilterOption("Slice of life", "35"),
          SelectFilterOption("Smut", "36"),
          SelectFilterOption("Sports", "37"),
          SelectFilterOption("Supernatural", "38"),
          SelectFilterOption("Tragedy", "39"),
          SelectFilterOption("Webtoons", "40"),
          SelectFilterOption("Yaoi", "41"),
          SelectFilterOption("Yuri", "42"),
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
  final headers = {'referer': '$url/'};
  return headers;
}

MangaBox main(MSource source) {
  return MangaBox(source: source);
}

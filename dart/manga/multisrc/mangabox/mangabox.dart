import 'package:mangayomi/bridge_lib.dart';

class MangaBox extends MProvider {
  MangaBox({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(
          Uri.parse("${source.baseUrl}/${popularUrlPath(source.name, page)}"),
          headers: getHeader(source.baseUrl),
        )).body;
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(
          Uri.parse("${source.baseUrl}/${latestUrlPath(source.name, page)}"),
          headers: getHeader(source.baseUrl),
        )).body;
    return mangaRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;

    String url = "";
    if (query.isNotEmpty) {
      url = "${source.baseUrl}/${simpleQueryPath(source.name, page, query)}";
    } else {
      String genre = "all";
      String sort = "latest";
      String status = "all";

      for (var filter in filters) {
        if (filter.type == "GenreListFilter") {
          genre = filter.values[filter.state].value;
        } else if (filter.type == "SortFilter") {
          sort = filter.values[filter.state].value;
        } else if (filter.type == "StatusFilter") {
          status = filter.values[filter.state].value;
        }
      }
      url =
          "${source.baseUrl}/genre/$genre?type=$sort&state=$status&page=$page";
    }

    final res =
        (await client.get(
          Uri.parse(url),
          headers: getHeader(source.baseUrl),
        )).body;

    List<MManga> mangaList = [];
    List<String> urls = [];
    urls = xpath(
      res,
      '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item" or @class="story_item_right"]/h3/a/@href',
    );
    List<String> names = [];
    names = xpath(
      res,
      '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item" or @class="story_item_right"]/h3/a/text()',
    );
    final images = xpath(
      res,
      '//*[@class="search-story-item" or @class="story_item" or @class="content-genres-item"  or @class="list-story-item" or @class="story-item" or @class="list-truyen-item-wrap"]/a/img/@src',
    );
    if (names.isEmpty) {
      urls = xpath(
        res,
        '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h2/a/@href',
      );
      names = xpath(
        res,
        '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h2/a/text()',
      );
    }
    if (names.isEmpty) {
      names = xpath(
        res,
        '//*[@class="search-story-item" or @class="list-story-item"]/a/@title',
      );
      urls = xpath(
        res,
        '//*[@class="search-story-item" or @class="list-story-item"]/a/@href',
      );
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
      {"Ongoing": 0, "Completed": 1},
    ];
    MManga manga = MManga();
    final res =
        (await client.get(
          Uri.parse(url),
          headers: getHeader(source.baseUrl),
        )).body;
    final document = parseHtml(res);
    manga.author =
        document.xpathFirst(
          '//*[@class="table-label" and contains(text(), "Author")]/parent::tr/td[2]/text()|//li[contains(text(), "Author")]/a/text()',
        ) ??
        "";

    final alternative =
        document.xpathFirst(
          '//*[@class="table-label" and contains(text(), "Alternative")]/parent::tr/td[2]/text()',
        ) ??
        "";

    final description =
        document.xpathFirst(
          '//*[@id="contentBox" ]/text() | //*[@id="story_discription" ]/text() | //div[@id="noidungm"]/text()',
        ) ??
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
    final status =
        document.xpathFirst(
          '//*[@class="table-label" and contains(text(), "Status")]/parent::tr/td[2]/text() | //li[contains(text(), "Status")]/text() | //li[contains(text(), "Status")]/a/text()',
        ) ??
        "";
    if (status.isNotEmpty) {
      manga.status = parseStatus(status.split(":").last.trim(), statusList);
    }
    manga.genre = document.xpath(
      '//*[@class="table-label" and contains(text(), "Genres")]/parent::tr/td[2]/a/text() | //li[contains(text(), "Genres")]/a/text()',
    );
    final chaptersElements = document.select(
      "div.chapter-list div.row, ul.row-content-chapter li, div#chapter_list li",
    );
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
        dateStr = element.selectFirst("p")?.text ?? "";
      }
      chapter.url = a.getHref;
      chapter.dateUpload =
          dateStr.isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toString()
              : parseDates(
                [dateStr],
                source.dateFormat,
                source.dateFormatLocale,
              )[0];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final res =
        (await client.get(
          Uri.parse(url),
          headers: getHeader(source.baseUrl),
        )).body;
    List<String> pageUrls = [];
    final urls = xpath(
      res,
      '//div[@class="container-chapter-reader" or @class="panel-read-story"]/img/@src',
    );
    for (var url in urls) {
      if (url.startsWith("https://convert_image_digi.mgicdn.com")) {
        pageUrls.add(
          "https://images.weserv.nl/?url=${substringAfter(url, "//")}",
        );
      } else {
        pageUrls.add(url);
      }
    }

    return pageUrls;
  }

  MPages mangaRes(String res) {
    List<MManga> mangaList = [];
    List<String> urls = [];
    urls = xpath(
      res,
      '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h3/a/@href',
    );
    List<String> names = [];
    names = xpath(
      res,
      '//*[ @class^="genres-item"  or @class="list-truyen-item-wrap" or @class="story-item"]/h3/a/text()',
    );
    final images = xpath(
      res,
      '//*[ @class="content-genres-item"  or @class="list-story-item" or @class="story-item" or @class="list-truyen-item-wrap"]/a/img/@src',
    );
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
    if (sourceName != "Mangairo") {
      return "manga-list/hot-manga?page=$page";
    } else {
      return "manga-list/type-topview/ctg-all/state-all/page-$page";
    }
  }

  String latestUrlPath(String sourceName, int page) {
    if (sourceName != "Mangairo") {
      return "manga-list/latest-manga?page=$page";
    } else {
      return "manga-list/type-latest/ctg-all/state-all/page-$page";
    }
  }

  String simpleQueryPath(String sourceName, int page, String query) {
    if (sourceName == "Mangairo") {
      return "list/search/${normalizeSearchQuery(query)}?page=$page";
    } else {
      return "search/story/${normalizeSearchQuery(query)}?page=$page";
    }
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
      "_",
    );
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
      HeaderFilter("NOTE: The filter is ignored when using text search."),
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
      SelectFilter("GenreListFilter", "Category:", 0, [
        SelectFilterOption("ALL", "all"),
        SelectFilterOption("Action", "action"),
        SelectFilterOption("Adult", "adult"),
        SelectFilterOption("Adventure", "adventure"),
        SelectFilterOption("Comedy", "comedy"),
        SelectFilterOption("Cooking", "cooking"),
        SelectFilterOption("Doujinshi", "doujinshi"),
        SelectFilterOption("Drama", "drama"),
        SelectFilterOption("Ecchi", "ecchi"),
        SelectFilterOption("Fantasy", "fantasy"),
        SelectFilterOption("Gender Bender", "gender-bender"),
        SelectFilterOption("Harem", "harem"),
        SelectFilterOption("Historical", "historical"),
        SelectFilterOption("Horror", "horror"),
        SelectFilterOption("Isekai", "isekai"),
        SelectFilterOption("Josei", "josei"),
        SelectFilterOption("Manhua", "manhua"),
        SelectFilterOption("Manhwa", "manhwa"),
        SelectFilterOption("Martial arts", "martial-arts"),
        SelectFilterOption("Mature", "mature"),
        SelectFilterOption("Mecha", "mecha"),
        SelectFilterOption("Medical", "medical"),
        SelectFilterOption("Mystery", "mystery"),
        SelectFilterOption("One shot", "one-shot"),
        SelectFilterOption("Psychological", "psychological"),
        SelectFilterOption("Reincarnation", "reincarnation"),
        SelectFilterOption("Romance", "romance"),
        SelectFilterOption("School life", "school-life"),
        SelectFilterOption("Sci fi", "sci-fi"),
        SelectFilterOption("Seinen", "seinen"),
        SelectFilterOption("Shoujo", "shoujo"),
        SelectFilterOption("Shoujo ai", "shoujo-ai"),
        SelectFilterOption("Shounen", "shounen"),
        SelectFilterOption("Shounen ai", "shounen-ai"),
        SelectFilterOption("Slice of life", "slice-of-life"),
        SelectFilterOption("Smut", "smut"),
        SelectFilterOption("Sports", "sports"),
        SelectFilterOption("Supernatural", "supernatural"),
        SelectFilterOption("Survival", "survival"),
        SelectFilterOption("System", "system"),
        SelectFilterOption("Thriller", "thriller"),
        SelectFilterOption("Tragedy", "tragedy"),
        SelectFilterOption("Webtoons", "webtoons"),
        SelectFilterOption("Yaoi", "yaoi"),
        SelectFilterOption("Yuri", "yuri"),
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
  final Map<String, String> headers = {
    "Referer": "$url/",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
  };
  return headers;
}

MangaBox main(MSource source) {
  return MangaBox(source: source);
}

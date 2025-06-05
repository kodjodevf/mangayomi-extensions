import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaHere extends MProvider {
  MangaHere({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(
      Uri.parse("${source.baseUrl}/directory/$page.htm"),
      headers: getHeader(source.baseUrl),
    )).body;

    List<MManga> mangaList = [];
    final names = xpath(
      res,
      '//*[ contains(@class, "manga-list-1-list")]/li/a/@title',
    );
    final images = xpath(
      res,
      '//*[ contains(@class, "manga-list-1-list")]/li/a/img[@class="manga-list-1-cover"]/@src',
    );
    final urls = xpath(
      res,
      '//*[ contains(@class, "manga-list-1-list")]/li/a/@href',
    );

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
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(
      Uri.parse("${source.baseUrl}/directory/$page.htm?latest"),
      headers: getHeader(source.baseUrl),
    )).body;

    List<MManga> mangaList = [];
    final names = xpath(
      res,
      '//*[ contains(@class, "manga-list-1-list")]/li/a/@title',
    );
    final images = xpath(
      res,
      '//*[ contains(@class, "manga-list-1-list")]/li/a/img[@class="manga-list-1-cover"]/@src',
    );
    final urls = xpath(
      res,
      '//*[ contains(@class, "manga-list-1-list")]/li/a/@href',
    );

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
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "${source.baseUrl}/search";

    for (var filter in filters) {
      if (filter.type == "TypeList") {
        final type = filter.values[filter.state].value;
        url += "${ll(url)}type=$type";
      } else if (filter.type == "CompletionList") {
        final cmp = filter.values[filter.state].value;
        url += "${ll(url)}st=$cmp";
      } else if (filter.type == "RatingList") {
        url += "${ll(url)}rating_method=gt";
        final rt = filter.values[filter.state].value;
        url += "${ll(url)}rating=$rt";
      } else if (filter.type == "GenreList") {
        final included = (filter.state as List)
            .where((e) => e.state == 1 ? true : false)
            .toList();
        final excluded = (filter.state as List)
            .where((e) => e.state == 2 ? true : false)
            .toList();
        if (included.isNotEmpty) {
          url += "${ll(url)}genres=";
          for (var val in included) {
            url += "${val.value},";
          }
        }
        if (excluded.isNotEmpty) {
          url += "${ll(url)}nogenres=";
          for (var val in excluded) {
            url += "${val.value},";
          }
        }
      } else if (filter.type == "ArtistFilter") {
        url += "${ll(url)}artist_method=cw";
        url += "${ll(url)}artist=${Uri.encodeComponent(filter.state)}";
      } else if (filter.type == "AuthorFilter") {
        url += "${ll(url)}author_method=cw";
        url += "${ll(url)}author=${Uri.encodeComponent(filter.state)}";
      } else if (filter.type == "YearFilter") {
        url += "${ll(url)}released_method=cw";
        url += "${ll(url)}released=${Uri.encodeComponent(filter.state)}";
      }
    }
    url += "${ll(url)}title=$query&page=$page";
    final res = (await client.get(
      Uri.parse(url),
      headers: getHeader(source.baseUrl),
    )).body;

    List<MManga> mangaList = [];
    final names = xpath(
      res,
      '//*[contains(@class, "manga-list-4-list")]/li/a/@title',
    );
    final images = xpath(
      res,
      '//*[contains(@class, "manga-list-4-list")]/li/a/img[@class="manga-list-4-cover"]/@src',
    );
    final urls = xpath(
      res,
      '//*[contains(@class, "manga-list-4-list")]/li/a/@href',
    );

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
    final res = (await client.get(
      Uri.parse("${source.baseUrl}/$url"),
      headers: getHeader(source.baseUrl),
    )).body;
    MManga manga = MManga();
    manga.author = xpath(
      res,
      '//*[@class="detail-info-right-say"]/a/text()',
    ).first;
    manga.description = xpath(res, '//*[@class="fullcontent"]/text()').first;
    final status = xpath(
      res,
      '//*[@class="detail-info-right-title-tip"]/text()',
    ).first;
    manga.status = parseStatus(status, statusList);
    manga.genre = xpath(
      res,
      '//*[@class="detail-info-right-tag-list"]/a/text()',
    );

    var chapUrls = xpath(res, '//*[@class="detail-main-list"]/li/a/@href');
    var chaptersNames = xpath(
      res,
      '//*[@class="detail-main-list"]/li/a/div/p[@class="title3"]/text()',
    );
    final chapterDates = xpath(
      res,
      '//*[@class="detail-main-list"]/li/a/div/p[@class="title2"]/text()',
    );
    var dateUploads = parseDates(
      chapterDates,
      source.dateFormat,
      source.dateFormatLocale,
    );

    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chaptersNames.length; i++) {
      MChapter chapter = MChapter();
      chapter.name = chaptersNames[i];
      chapter.url = chapUrls[i];
      chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final headers = getHeader(source.baseUrl);
    final urll = "${source.baseUrl}$url";
    final res = (await client.get(Uri.parse(urll), headers: headers)).body;
    final pages = xpath(res, "//body/div/div/span/a/text()");
    List<String> pageUrls = [];
    if (pages.isEmpty) {
      final script = xpath(
        res,
        "//script[contains(text(),'function(p,a,c,k,e,d)')]/text()",
      ).first.replaceAll("eval", "");
      String deobfuscatedScript = unpackJs(script);
      int a = deobfuscatedScript.indexOf("newImgs=['") + 10;
      int b = deobfuscatedScript.indexOf("'];");
      List<String> urls = deobfuscatedScript.substring(a, b).split("','");
      for (var url in urls) {
        pageUrls.add("https:$url");
      }
    } else {
      final pagesNumberList = pages;
      int pagesNumber = int.parse(pagesNumberList[pagesNumberList.length - 2]);
      int secretKeyScriptLocation = res.indexOf("eval(function(p,a,c,k,e,d)");
      int secretKeyScriptEndLocation = res.indexOf(
        "</script>",
        secretKeyScriptLocation,
      );
      String secretKeyScript = res
          .substring(secretKeyScriptLocation, secretKeyScriptEndLocation)
          .replaceAll("eval", "");
      String secretKeyDeobfuscatedScript = unpackJs(secretKeyScript);
      int secretKeyStartLoc = secretKeyDeobfuscatedScript.indexOf("'");
      int secretKeyEndLoc = secretKeyDeobfuscatedScript.indexOf(";");

      String secretKey = secretKeyDeobfuscatedScript.substring(
        secretKeyStartLoc,
        secretKeyEndLoc,
      );
      int chapterIdStartLoc = res.indexOf("chapterid");
      String chapterId = res.substring(
        chapterIdStartLoc + 11,
        res.indexOf(";", chapterIdStartLoc),
      );
      String pageBase = urll.substring(0, urll.lastIndexOf("/"));
      for (int i = 1; i <= pagesNumber; i++) {
        String pageLink =
            "$pageBase/chapterfun.ashx?cid=$chapterId&page=$i&key=$secretKey";
        String responseText = "".toString();
        final headers = {
          "Referer": urll,
          "Accept": "*/*",
          "Accept-Language": "en-US,en;q=0.9",
          "Connection": "keep-alive",
          "Host": "www.mangahere.cc",
          "X-Requested-With": "XMLHttpRequest",
        };

        final ress = (await client.get(
          Uri.parse(pageLink),
          headers: headers,
        )).body;
        responseText = ress.isNotEmpty ? ress : "";

        if (responseText.isEmpty) {
          secretKey = "";
        }
        String deobfuscatedScript = unpackJs(
          responseText.replaceAll("eval", ""),
        );

        int baseLinkStartPos = deobfuscatedScript.indexOf("pix=") + 5;
        int baseLinkEndPos =
            deobfuscatedScript.indexOf(";", baseLinkStartPos) - 1;
        String baseLink = deobfuscatedScript.substring(
          baseLinkStartPos,
          baseLinkEndPos,
        );

        int imageLinkStartPos = deobfuscatedScript.indexOf("pvalue=") + 9;
        int imageLinkEndPos = deobfuscatedScript.indexOf(
          "\"",
          imageLinkStartPos,
        );
        String imageLink = deobfuscatedScript.substring(
          imageLinkStartPos,
          imageLinkEndPos,
        );
        pageUrls.add("https:$baseLink$imageLink");
      }
    }

    return pageUrls;
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
      SelectFilter("TypeList", "Type", 1, [
        SelectFilterOption("American Manga", "5"),
        SelectFilterOption("Any", "0"),
        SelectFilterOption("Chinese Manhua", "3"),
        SelectFilterOption("European Manga", "4"),
        SelectFilterOption("Hong Kong Manga", "6"),
        SelectFilterOption("Japanese Manga", "1"),
        SelectFilterOption("Korean Manhwa", "2"),
        SelectFilterOption("Other Manga", "7"),
      ]),
      TextFilter("ArtistFilter", "Artist"),
      TextFilter("AuthorFilter", "Author"),
      GroupFilter("GenreList", "Genres", [
        TriStateFilter("Action", "1"),
        TriStateFilter("Adventure", "2"),
        TriStateFilter("Comedy", "3"),
        TriStateFilter("Fantasy", "4"),
        TriStateFilter("Historical", "5"),
        TriStateFilter("Horror", "6"),
        TriStateFilter("Martial Arts", "7"),
        TriStateFilter("Mystery", "8"),
        TriStateFilter("Romance", "9"),
        TriStateFilter("Shounen Ai", "10"),
        TriStateFilter("Supernatural", "11"),
        TriStateFilter("Drama", "12"),
        TriStateFilter("Shounen", "13"),
        TriStateFilter("School Life", "14"),
        TriStateFilter("Shoujo", "15"),
        TriStateFilter("Gender Bender", "16"),
        TriStateFilter("Josei", "17"),
        TriStateFilter("Psychological", "18"),
        TriStateFilter("Seinen", "19"),
        TriStateFilter("Slice of Life", "20"),
        TriStateFilter("Sci-fi", "21"),
        TriStateFilter("Ecchi", "22"),
        TriStateFilter("Harem", "23"),
        TriStateFilter("Shoujo Ai", "24"),
        TriStateFilter("Yuri", "25"),
        TriStateFilter("Mature", "26"),
        TriStateFilter("Tragedy", "27"),
        TriStateFilter("Yaoi", "28"),
        TriStateFilter("Doujinshi", "29"),
        TriStateFilter("Sports", "30"),
        TriStateFilter("Adult", "31"),
        TriStateFilter("One Shot", "32"),
        TriStateFilter("Smut", "33"),
        TriStateFilter("Mecha", "34"),
        TriStateFilter("Shotacon", "35"),
        TriStateFilter("Lolicon", "36"),
        TriStateFilter("Webtoons", "37"),
      ]),
      SelectFilter("RatingList", "Minimum rating", 0, [
        SelectFilterOption("No Stars", "0"),
        SelectFilterOption("1 Star", "1"),
        SelectFilterOption("2 Stars", "2"),
        SelectFilterOption("3 Stars", "3"),
        SelectFilterOption("4 Stars", "4"),
        SelectFilterOption("5 Stars", "5"),
      ]),
      TextFilter("YearFilter", "Year released"),
      SelectFilter("CompletionList", "Completed series", 0, [
        SelectFilterOption("Either", "0"),
        SelectFilterOption("No", "1"),
        SelectFilterOption("Yes", "2"),
      ]),
    ];
  }
}

Map<String, String> getHeader(String url) {
  final headers = {'Referer': '$url/', "Cookie": "isAdult=1"};
  return headers;
}

MangaHere main(MSource source) {
  return MangaHere(source: source);
}

import 'package:mangayomi/bridge_lib.dart';

class NHentai extends MProvider {
  NHentai(this.source);

  final MSource source;

  final Client client = Client(source);

  @override
  bool get supportsLatest => true;

  @override
  Future<MPages> getPopular(int page) async {
    final nhLang = source.lang == "all"
        ? "/search/?q=\"\"&sort=popular&"
        : "/language/${getLanguage()}/popular?";
    final res =
        (await client.get(Uri.parse("${source.baseUrl}${nhLang}page=$page")))
            .body;
    return parseMangaList(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final nhLang = source.lang == "all" ? "/?" : "/language/${getLanguage()}/?";
    final res =
        (await client.get(Uri.parse("${source.baseUrl}${nhLang}page=$page")))
            .body;
    return parseMangaList(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    final fixedQuery = query.isEmpty ? "\"\"" : query.trim();
    final nhLang = source.lang == "all" ? "" : "+${getLanguage()} ";
    String url = "${source.baseUrl}/";
    final isFavoriteFilter =
        filters.where((e) => e.type == "FavoriteFilter").toList().first.state;
    final isOkayToSort = filters
        .where((e) => e.type == "UploadedFilter")
        .toList()
        .first
        .state
        .isEmpty;

    String advQuery = "";
    for (var filter in filters) {
      if (filter.type == "TextFilter" || filter.type == "UploadedFilter") {
        if (filter.state.isNotEmpty) {
          final splitState = (filter.state as String)
              .split(",")
              .where((e) => e.isNotEmpty ? true : false)
              .toList();
          String name = filter.name;
          for (var state in splitState) {
            final exclude = (state as String).startsWith("-");
            final text = (state as String).replaceFirst("-", "");
            if (exclude) advQuery += "-";
            advQuery += "$name:${text.trim()} ";
          }
        }
      }
    }
    if (isFavoriteFilter) {
      url += "favorites/?q=$fixedQuery $advQuery&page=$page";
    } else {
      url += "search/?q=$fixedQuery $nhLang$advQuery&page=$page";
      if (isOkayToSort) {
        final sort =
            filters.where((e) => e.type == "SortFilter").toList().first;
        url += sort.values[sort.state].value;
      }
    }
    final res = (await client.get(Uri.parse(url))).body;
    return parseMangaList(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final cleanTagRegExp = RegExp("\\(.*\\)");
    MManga manga = MManga();
    final res = (await client
            .get(Uri.parse("${source.baseUrl}${getUrlWithoutDomain(url)}")))
        .body;
    final document = parseHtml(res);
    final fullTitle =
        getTitle(document.selectFirst("#info > h1").text.replaceAll("\"", ""));
    final imageElement =
        document.selectFirst("#cover > a > img")?.attr("data-src") ?? "";
    manga.name = fullTitle;
    manga.imageUrl = imageElement;
    final artists =
        document.select("#tags > div:nth-child(3) > span > a .name");
    manga.artist = artists
        .map((MElement e) => e.text.replaceAll(cleanTagRegExp, ""))
        .toList()
        .join(", ");
    manga.author = manga.artist;
    manga.status = MStatus.completed;
    String description = "Full English and Japanese titles:\n";
    description += "$fullTitle\n";
    description += "${document.selectFirst("div#info h2").text}\n\n";
    description +=
        "Pages: ${document.selectFirst("#tags > div:nth-child(7) > span > a .name")?.text.replaceAll(cleanTagRegExp, "") ?? ""}\n";
    description +=
        "Favorited by: ${document.selectFirst("div#info i.fa-heart + span span").text.replaceAll("(", "").replaceAll(")", "")}\n";
    final categories =
        document.select("#tags > div:nth-child(6) > span > a .name");
    if (categories.isNotEmpty) {
      description +=
          "Categories: ${categories.map((MElement e) => e.text.replaceAll(cleanTagRegExp, "")).toList().join(", ")}\n\n";
    }
    manga.description = description;
    final tags = document.select("#tags > div:nth-child(2) > span > a .name");
    if (tags.isNotEmpty) {
      manga.genre = tags
          .map((MElement e) => e.text.replaceAll(cleanTagRegExp, ""))
          .toList();
    }
    final groups = document
        .select("#tags > div:nth-child(4) > span > a .name")
        .map((MElement e) => e.text.replaceAll(cleanTagRegExp, ""))
        .toList()
        .join(", ");
    final timeString =
        substringBefore(substringAfter(res, "datetime=\""), "\">")
            .replaceAll("T", " ");
    MChapter chapter = MChapter();
    chapter.name = "Chapter";
    chapter.scanlator = groups;
    chapter.dateUpload =
        parseDates([timeString], "yyyy-MM-dd HH:mm:ss.SSSSSSZ", "en")[0];
    chapter.url = getUrlWithoutDomain(url);
    manga.chapters = [chapter];
    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}${getUrlWithoutDomain(url)}")))
        .body;
    final document = parseHtml(res);
    final script = document
        .select("script")
        .where((MElement e) => e.outerHtml.contains("media_server"))
        .toList()
        .first;
    final mediaServer = RegExp(r"media_server\s*:\s*(\d+)")
        .firstMatch(script.outerHtml)
        ?.group(1);
    List<String> pages = [];
    final pageDocs = document.select("div.thumbs a > img");
    for (var pageElement in pageDocs) {
      pages.add(pageElement.getDataSrc
          .replaceAll("t.nh", "i.nh")
          .replaceAll(RegExp("t\\d+.nh"), "i$mediaServer.nh")
          .replaceAll("t.", "."));
    }
    return pages;
  }

  String getLanguage() {
    return {"en": "english", "ja": "japanese", "zh": "chinese"}[source.lang];
  }

  MPages parseMangaList(String res) {
    List<MManga> mangaList = [];
    final document = parseHtml(res);
    final result = document
        .select("#content .container")
        .where((MElement e) => e.className == "container index-container")
        .toList();
    if (result.isNotEmpty) {
      for (var element in (result.first as MElement).select(".gallery")) {
        MManga manga = MManga();
        manga.name =
            getTitle(element.selectFirst("a > div").text.replaceAll("\"", ""));
        manga.link = getUrlWithoutDomain(element.selectFirst("a").getHref);
        final imageElement = element.selectFirst(".cover img");
        manga.imageUrl =
            imageElement?.attr("data-src") ?? imageElement?.attr("src");
        mangaList.add(manga);
      }
    }
    return MPages(mangaList,
        document.selectFirst("#content > section.pagination > a.next") != null);
  }

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("Separate tags with commas (,)"),
      HeaderFilter("Prepend with dash (-) to exclude"),
      TextFilter("TextFilter", "Tags"),
      TextFilter("TextFilter", "Categories"),
      TextFilter("TextFilter", "Groups"),
      TextFilter("TextFilter", "Artists"),
      TextFilter("TextFilter", "Parodies"),
      TextFilter("TextFilter", "Characters"),
      HeaderFilter("Uploaded valid units are h, d, w, m, y."),
      HeaderFilter("example: (>20d)"),
      TextFilter("UploadedFilter", "Uploaded"),
      HeaderFilter("Filter by pages, for example: (>20)"),
      TextFilter("TextFilter", "Pages"),
      SeparatorFilter(),
      SelectFilter("SortFilter", "Sort By", 0, [
        SelectFilterOption("Popular: All Time", "&sort=popular"),
        SelectFilterOption("Popular: Week", "&sort=popular-week"),
        SelectFilterOption("Popular: Today", "&sort=popular-today"),
        SelectFilterOption("Recent", "&sort=date")
      ]),
      HeaderFilter("Sort is ignored if favorites only"),
      CheckBoxFilter("Show favorites only", "true", "FavoriteFilter")
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_display_title",
          title: "Display manga title as:",
          summary: "",
          valueIndex: 0,
          entries: ["Full Title", "Short Title"],
          entryValues: ["full", "short"]),
    ];
  }

  String getTitle(String title) {
    bool displayFullTitle =
        getPreferenceValue(source.id, "preferred_display_title") == "full";
    if (displayFullTitle) {
      return title.trim();
    }
    return title.replaceAll(RegExp(r"(\[[^]]*]|[({][^)}]*[)}])"), "").trim();
  }
}

NHentai main(MSource source) {
  return NHentai(source);
}

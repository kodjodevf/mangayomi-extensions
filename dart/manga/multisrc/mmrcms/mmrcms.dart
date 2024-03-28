import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MMRCMS extends MProvider {
  MMRCMS({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(
            "${source.baseUrl}/filterList?page=$page&sortBy=views&asc=false")))
        .body;

    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[ @class="chart-title"]/@href');
    final names = xpath(res, '//*[ @class="chart-title"]/text()');
    List<String> images = [];
    for (var url in urls) {
      String slug = substringAfterLast(url, '/');
      if (source.name == "Manga-FR") {
        images.add("${source.baseUrl}/uploads/manga/${slug}.jpg");
      } else {
        images.add(
            "${source.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg");
      }
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
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}/latest-release?page=$page")))
        .body;

    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[@class="manga-item"]/h3/a/@href');
    final names = xpath(res, '//*[@class="manga-item"]/h3/a/text()');
    List<String> images = [];
    for (var url in urls) {
      String slug = substringAfterLast(url, '/');
      if (source.name == "Manga-FR") {
        images.add("${source.baseUrl}/uploads/manga/${slug}.jpg");
      } else {
        images.add(
            "${source.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg");
      }
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
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    if (query.isNotEmpty) {
      url = "${source.baseUrl}/search?query=$query";
    } else {
      url = "${source.baseUrl}/filterList?page=$page";
      for (var filter in filters) {
        if (filter.type == "AuthorFilter") {
          url += "${ll(url)}author=${Uri.encodeComponent(filter.state)}";
        } else if (filter.type == "SortFilter") {
          url += "${ll(url)}sortBy=${filter.values[filter.state.index].value}";
          final asc = filter.state.ascending ? "asc=true" : "asc=false";
          url += "${ll(url)}$asc";
        } else if (filter.type == "CategoryFilter") {
          if (filter.state != 0) {
            final cat = filter.values[filter.state].value;
            url += "${ll(url)}cat=$cat";
          }
        } else if (filter.type == "BeginsWithFilter") {
          if (filter.state != 0) {
            final a = filter.values[filter.state].value;
            url += "${ll(url)}alpha=$a";
          }
        }
      }
    }

    final res = (await client.get(Uri.parse(url))).body;

    List<MManga> mangaList = [];

    List<String> urls = [];
    List<String> names = [];
    List<String> images = [];

    if (query.isNotEmpty) {
      final jsonList = json.decode(res)["suggestions"];
      for (var da in jsonList) {
        String value = da["value"];
        String data = da["data"];
        if (source.name == 'Scan VF') {
          urls.add('${source.baseUrl}/$data');
        } else if (source.name == 'Manga-FR') {
          urls.add('${source.baseUrl}/lecture-en-ligne/$data');
        } else {
          urls.add('${source.baseUrl}/manga/$data');
        }
        names.add(value);
        if (source.name == "Manga-FR") {
          images.add("${source.baseUrl}/uploads/manga/$data.jpg");
        } else {
          images.add(
              "${source.baseUrl}/uploads/manga/$data/cover/cover_250x350.jpg");
        }
      }
    } else {
      urls = xpath(res, '//div/div/div/a/@href');
      names = xpath(res, '//div/div/div/a/text()');
      for (var url in urls) {
        String slug = substringAfterLast(url, '/');
        if (source.name == "Manga-FR") {
          images.add("${source.baseUrl}/uploads/manga/${slug}.jpg");
        } else {
          images.add(
              "${source.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg");
        }
      }
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
      {
        "complete": 1,
        "complet": 1,
        "completo": 1,
        "zakończone": 1,
        "concluído": 1,
        "مكتملة": 1,
        "ongoing": 0,
        "en cours": 0,
        "em lançamento": 0,
        "prace w toku": 0,
        "ativo": 0,
        "مستمرة": 0,
        "em andamento": 0
      }
    ];
    MManga manga = MManga();
    final res = (await client.get(Uri.parse(url))).body;

    final author = xpath(res,
        '//*[@class="dl-horizontal"]/dt[contains(text(), "Auteur(s)") or contains(text(), "Author(s)") or contains(text(), "Autor(es)") or contains(text(), "Yazar(lar) or contains(text(), "Mangaka(lar)")]//following-sibling::dd[1]/text()');
    if (author.isNotEmpty) {
      manga.author = author.first;
    }
    final status = xpath(res,
        '//*[@class="dl-horizontal"]/dt[contains(text(), "Statut") or contains(text(), "Status") or contains(text(), "Estado") or contains(text(), "Durum")]/following-sibling::dd[1]/text()');
    if (status.isNotEmpty) {
      manga.status = parseStatus(status.first, statusList);
    }

    final description =
        xpath(res, '//*[@class="well" or @class="manga well"]/p/text()');
    if (description.isNotEmpty) {
      manga.description = description.first;
    }

    manga.genre = xpath(res,
        '//*[@class="dl-horizontal"]/dt[contains(text(), "Categories") or contains(text(), "Categorias") or contains(text(), "Categorías") or contains(text(), "Catégories") or contains(text(), "Kategoriler" or contains(text(), "Kategorie") or contains(text(), "Kategori") or contains(text(), "Tagi"))]/following-sibling::dd[1]/text()');

    var chapUrls = xpath(res, '//*[@class="chapter-title-rtl"]/a/@href');
    var chaptersNames = xpath(res, '//*[@class="chapter-title-rtl"]/a/text()');
    var chaptersDates =
        xpath(res, '//*[@class="date-chapter-title-rtl"]/text()');

    var dateUploads =
        parseDates(chaptersDates, source.dateFormat, source.dateFormatLocale);

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
    final res = (await client.get(Uri.parse(url))).body;

    List<String> pagesUrl = [];
    final pages =
        xpath(res, '//*[@id="all"]/img[@class="img-responsive"]/@data-src');
    for (var page in pages) {
      if (page.startsWith('//')) {
        pagesUrl.add(page.replaceAll('//', 'https://'));
      } else {
        pagesUrl.add(page);
      }
    }

    return pagesUrl;
  }

  List<dynamic> getFilterList() {
    return [
      HeaderFilter("NOTE: Ignored if using text search!"),
      SeparatorFilter(),
      TextFilter("AuthorFilter", "Author"),
      SelectFilter("CategoryFilter", "Category", 0, [
        SelectFilterOption("Any", ""),
        SelectFilterOption("Action", "Action"),
        SelectFilterOption("Adventure", "Adventure"),
        SelectFilterOption("Comedy", "Comedy"),
        SelectFilterOption("Doujinshi", "Doujinshi"),
        SelectFilterOption("Drama", "Drama"),
        SelectFilterOption("Ecchi", "Ecchi"),
        SelectFilterOption("Fantasy", "Fantasy"),
        SelectFilterOption("Gender Bender", "Gender Bender"),
        SelectFilterOption("Harem", "Harem"),
        SelectFilterOption("Historical", "Historical"),
        SelectFilterOption("Horror", "Horror"),
        SelectFilterOption("Josei", "Josei"),
        SelectFilterOption("Martial Arts", "Martial Arts"),
        SelectFilterOption("Mature", "Mature"),
        SelectFilterOption("Mecha", "Mecha"),
        SelectFilterOption("Mystery", "Mystery"),
        SelectFilterOption("One Shot", "One Shot"),
        SelectFilterOption("Psychological", "Psychological"),
        SelectFilterOption("Romance", "Romance"),
        SelectFilterOption("School Life", "School Life"),
        SelectFilterOption("Sci-fi", "Sci-fi"),
        SelectFilterOption("Seinen", "Seinen"),
        SelectFilterOption("Shoujo", "Shoujo"),
        SelectFilterOption("Shoujo Ai", "Shoujo Ai"),
        SelectFilterOption("Shounen", "Shounen"),
        SelectFilterOption("Shounen Ai", "Shounen Ai"),
        SelectFilterOption("Slice of Life", "Slice of Life"),
        SelectFilterOption("Sports", "Sports"),
        SelectFilterOption("Supernatural", "Supernatural"),
        SelectFilterOption("Tragedy", "Tragedy"),
        SelectFilterOption("Yaoi", "Yaoi"),
        SelectFilterOption("Yuri", "Yuri"),
      ]),
      SelectFilter("BeginsWithFilter", "Begins with", 0, [
        SelectFilterOption("Any", ""),
        SelectFilterOption("#", "#"),
        SelectFilterOption("A", "A"),
        SelectFilterOption("B", "B"),
        SelectFilterOption("C", "C"),
        SelectFilterOption("D", "D"),
        SelectFilterOption("E", "E"),
        SelectFilterOption("F", "F"),
        SelectFilterOption("G", "G"),
        SelectFilterOption("H", "H"),
        SelectFilterOption("I", "I"),
        SelectFilterOption("J", "J"),
        SelectFilterOption("K", "K"),
        SelectFilterOption("L", "L"),
        SelectFilterOption("M", "M"),
        SelectFilterOption("N", "N"),
        SelectFilterOption("O", "O"),
        SelectFilterOption("P", "P"),
        SelectFilterOption("Q", "Q"),
        SelectFilterOption("R", "R"),
        SelectFilterOption("S", "S"),
        SelectFilterOption("T", "T"),
        SelectFilterOption("U", "U"),
        SelectFilterOption("V", "V"),
        SelectFilterOption("W", "W"),
        SelectFilterOption("X", "X"),
        SelectFilterOption("Y", "Y"),
        SelectFilterOption("Z", "Z"),
      ]),
      SortFilter("SortFilter", "Sort", SortState(0, true), [
        SelectFilterOption("Name", "name"),
        SelectFilterOption("Popularity", "views"),
        SelectFilterOption("Last update", "last_release"),
      ])
    ];
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

MMRCMS main(MSource source) {
  return MMRCMS(source: source);
}

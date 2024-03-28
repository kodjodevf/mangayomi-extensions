import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaReader extends MProvider {
  MangaReader({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(
            "${source.baseUrl}${getMangaUrlDirectory(source.name)}/?page=$page&order=popular")))
        .body;
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse(
            "${source.baseUrl}${getMangaUrlDirectory(source.name)}/?page=$page&order=update")))
        .body;
    return mangaRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;

    String url =
        "${source.baseUrl}${getMangaUrlDirectory(source.name)}/?&title=$query&page=$page";

    for (var filter in filters) {
      if (filter.type == "AuthorFilter") {
        url += "${ll(url)}author=${Uri.encodeComponent(filter.state)}";
      } else if (filter.type == "YearFilter") {
        url += "${ll(url)}yearx=${Uri.encodeComponent(filter.state)}";
      } else if (filter.type == "StatusFilter") {
        final status = filter.values[filter.state].value;
        url += "${ll(url)}status=$status";
      } else if (filter.type == "TypeFilter") {
        final type = filter.values[filter.state].value;
        url += "${ll(url)}type=$type";
      } else if (filter.type == "OrderByFilter") {
        final order = filter.values[filter.state].value;
        url += "${ll(url)}order=$order";
      } else if (filter.type == "GenreListFilter") {
        final included = (filter.state as List)
            .where((e) => e.state == 1 ? true : false)
            .toList();
        final excluded = (filter.state as List)
            .where((e) => e.state == 2 ? true : false)
            .toList();
        if (included.isNotEmpty) {
          url += "${ll(url)}genres[]=";
          for (var val in included) {
            url += "${val.value},";
          }
        }
        if (excluded.isNotEmpty) {
          url += "${ll(url)}genres[]=";
          for (var val in excluded) {
            url += "-${val.value},";
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
      {
        "مستمرة": 0,
        "En curso": 0,
        "Ongoing": 0,
        "On going": 0,
        "Ativo": 0,
        "En Cours": 0,
        "Berjalan": 0,
        "Продолжается": 0,
        "Updating": 0,
        "Lançando": 0,
        "In Arrivo": 0,
        "OnGoing": 0,
        "Đang tiến hành": 0,
        "em lançamento": 0,
        "Онгоінг": 0,
        "Publishing": 0,
        "Curso": 0,
        "En marcha": 0,
        "Publicandose": 0,
        "连载中": 0,
        "Devam Ediyor": 0,
        "Em Andamento": 0,
        "In Corso": 0,
        "Güncel": 0,
        "Emision": 0,
        "En emision": 0,
        "مستمر": 0,
        "Đã hoàn thành": 1,
        "مكتملة": 1,
        "Завершено": 1,
        "Complété": 1,
        "Fini": 1,
        "Terminé": 1,
        "Tamamlandı": 1,
        "Tamat": 1,
        "Completado": 1,
        "Concluído": 1,
        "Finished": 1,
        "Completed": 1,
        "Completo": 1,
        "Concluido": 1,
        "已完结": 1,
        "Finalizado": 1,
        "Completata": 1,
        "One-Shot": 1,
        "Bitti": 1,
        "hiatus": 2,
      }
    ];
    url = getUrlWithoutDomain(url);
    MManga manga = MManga();

    final res = (await client.get(Uri.parse("${source.baseUrl}$url"))).body;
    List<String> author = xpath(
        res,
        "//table[contains(@class, 'infotable')]//tr[contains(text(), 'Author')]/td[last()]/text() | //div[contains(@class, 'tsinfo')]//div[contains(@class, 'imptdt') and contains(text(), 'Author')]//i/text() | //div[contains(@class, 'fmed')]//b[contains(text(), 'Author')]/following-sibling::span[1]/text() | //span[contains(text(), 'Author')]/text()",
        '');
    if (author.isEmpty) {
      author = xpath(
          res,
          "//table[contains(@class, 'infotable')]//tr[contains(text(), '${authorLocalStr(source.lang)}')]/td[last()]/text() | //div[contains(@class, 'tsinfo')]//div[contains(@class, 'imptdt') and contains(text(), '${authorLocalStr(source.lang)}')]//i/text() | //div[contains(@class, 'fmed')]//b[contains(text(), '${authorLocalStr(source.lang)}')]/following-sibling::span[1]/text() | //span[contains(text(), '${authorLocalStr(source.lang)}')]/text()",
          '');
    }
    if (author.isNotEmpty) {
      manga.author = author.first;
    }

    final description = parseHtml(res)
        .selectFirst(".desc, .entry-content[itemprop=description]")
        ?.text;

    if (description != null) {
      manga.description = description;
    }

    List<String> status = xpath(
        res,
        "//table[contains(@class, 'infotable')]//tr[contains(text(), 'Status')]/td[last()]/text() | //div[contains(@class, 'tsinfo')]//div[contains(@class, 'imptdt') and contains(text(), 'Status')]//i/text() | //div[contains(@class, 'fmed')]//b[contains(text(), 'Status')]/following-sibling::span[1]/text() | //span[contains(text(), 'Status')]/text()",
        '');
    if (status.isEmpty) {
      status = xpath(
          res,
          "//table[contains(@class, 'infotable')]//tr[contains(text(), '${statusLocalStr(source.lang)}')]/td[last()]/text() | //div[contains(@class, 'tsinfo')]//div[contains(@class, 'imptdt') and contains(text(), '${statusLocalStr(source.lang)}')]//i/text() | //div[contains(@class, 'fmed')]//b[contains(text(), '${statusLocalStr(source.lang)}')]/following-sibling::span[1]/text() | //span[contains(text(), '${statusLocalStr(source.lang)}')]/text()",
          '');
    }

    if (status.isNotEmpty) {
      manga.status = parseStatus(status.first, statusList);
    }

    manga.genre = xpath(res,
        '//*[@class="gnr"  or @class="mgen"  or @class="seriestugenre" ]/a/text()');
    var chapUrls = xpath(res,
        '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a[not(contains(@href,"{{number}}"))]/@href');
    var chaptersNames = xpath(res,
        '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a/span[@class="chapternum" and not(contains(text(),"{{number}}")) or @class="lch" and not(text()="Chapter {{number}}")]/text()');
    var chapterDates = xpath(res,
        '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a/span[@class="chapterdate" and not(contains(text(),"{{date}}"))]/text()');
    var dateUploads =
        parseDates(chapterDates, source.dateFormat, source.dateFormatLocale);

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
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse('${source.baseUrl}$url'))).body;

    List<String> pages = [];
    List<String> pagesUrl = [];
    bool invalidImgs = false;
    pages = xpath(res, '//*[@id="readerarea"]/p/img/@src');
    if (pages.isEmpty || pages.length == 1) {
      pages = xpath(res, '//*[@id="readerarea"]/img/@src');
    }
    if (pages.length > 1) {
      for (var page in pages) {
        if (page.contains("data:image")) {
          invalidImgs = true;
        }
      }
      if (invalidImgs) {
        pages = xpath(res, '//*[@id="readerarea"]/img/@data-src');
      }
    }
    if (pages.isEmpty || pages.length == 1) {
      final images = regExp(res, "\"images\"\\s*:\\s*(\\[.*?])", "", 1, 1);
      final pages = json.decode(images) as List;
      for (var page in pages) {
        pagesUrl.add(page);
      }
    } else {
      return pages;
    }

    return pagesUrl;
  }

  MPages mangaRes(String res) {
    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@href');
    final names = xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@title');
    List<String> images = [];
    images =
        xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/div[1]/img/@src');
    bool invalidImgs = false;
    for (var img in images) {
      if (img.contains("data:image")) {
        invalidImgs = true;
      }
    }
    if (invalidImgs) {
      images = xpath(
          res, '//*[ @class="imgu"  or @class="bsx"]/a/div[1]/img/@data-src');
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
  List<dynamic> getFilterList() {
    return [
      SeparatorFilter(),
      TextFilter("AuthorFilter", "Author"),
      TextFilter("YearFilter", "Year"),
      SelectFilter("StatusFilter", "Status", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Ongoing", "ongoing"),
        SelectFilterOption("Completed", "completed"),
        SelectFilterOption("Hiatus", "hiatus"),
        SelectFilterOption("Dropped", "dropped"),
      ]),
      SelectFilter("TypeFilter", "Type", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Manga", "Manga"),
        SelectFilterOption("Manhwa", "Manhwa"),
        SelectFilterOption("Manhua", "Manhua"),
        SelectFilterOption("Comic", "Comic"),
      ]),
      SelectFilter("OrderByFilter", "Sort By", 0, [
        SelectFilterOption("Default", ""),
        SelectFilterOption("A-Z", "title"),
        SelectFilterOption("Z-A", "titlereverse"),
        SelectFilterOption("Latest Update", "update"),
        SelectFilterOption("Latest Added", "latest"),
        SelectFilterOption("Popular", "popular"),
      ]),
      HeaderFilter("Genre exclusion is not available for all sources"),
      GroupFilter("GenreListFilter", "Genre", [
        TriStateFilter("Press reset to attempt to fetch genres", ""),
      ]),
    ];
  }

  String authorLocalStr(String lang) {
    if (lang == "fr") {
      return "Auteur";
    }
    return "Author";
  }

  String statusLocalStr(String lang) {
    if (lang == "fr") {
      return "Statut";
    } else if (lang == "es") {
      return "Estado";
    }
    return "Status";
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }

  String getMangaUrlDirectory(String sourceName) {
    if (sourceName == "Sushi-Scan") {
      return "/catalogue";
    }
    return "/manga";
  }
}

MangaReader main(MSource source) {
  return MangaReader(source: source);
}

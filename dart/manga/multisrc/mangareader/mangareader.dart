import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaReader extends MProvider {
  MangaReader({required this.source});

  MSource source;

  final Client client = Client();

  @override
  String get baseUrl => getPreferenceValue(source.id, "override_baseurl");

  @override
  Map<String, String> get headers => {"Referer": "$baseUrl/"};

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(
          Uri.parse(
            "$baseUrl${getMangaUrlDirectory(source.name)}/?page=$page&order=popular",
          ),
        )).body;
    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(
          Uri.parse(
            "$baseUrl${getMangaUrlDirectory(source.name)}/?page=$page&order=update",
          ),
        )).body;
    return mangaRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;

    String url = "$baseUrl${getMangaSearchUrl(page, query)}";

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
        final included =
            (filter.state as List)
                .where((e) => e.state == 1 ? true : false)
                .toList();
        final excluded =
            (filter.state as List)
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
        "ยังไม่จบ": 0,
        "curso": 0,
        "en marcha": 0,
        "publicandose": 0,
        "publicando": 0,
        "devam etmekte": 0,
        "連載中": 0,
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
        "จบแล้ว": 1,
        "tamat": 1,
        "completado": 1,
        "concluído": 1,
        "完結": 1,
        "concluido": 1,
        "bitmiş": 1,
        "hiatus": 2,
        "พักชั่วคราว": 2,
        "on hold": 2,
        "pausado": 2,
        "en espera": 2,
        "en pause": 2,
        "en attente": 2,
        "canceled": 3,
        "cancelled": 3,
        "cancelado": 3,
        "cancellato": 3,
        "cancelados": 3,
        "dropped": 3,
        "discontinued": 3,
        "abandonné": 3,
      },
    ];

    url = getUrlWithoutDomain(url);
    MManga manga = MManga();

    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    final seriesDetails = document.selectFirst(
      "div.bigcontent, div.animefull, div.main-info, div.postbody",
    );
    manga.author =
        seriesDetails
            .selectFirst(
              ".infotable tr:contains(Author) td:last-child, .tsinfo .imptdt:contains(Author) i, .fmed b:contains(Author)+span, span:contains(Author), " +
                  ".infotable tr:contains(Auteur) td:last-child, .tsinfo .imptdt:contains(Auteur) i, .fmed b:contains(Auteur)+span, span:contains(Auteur), " +
                  ".infotable tr:contains(autor) td:last-child, .tsinfo .imptdt:contains(autor) i, .fmed b:contains(autor)+span, span:contains(autor), " +
                  ".infotable tr:contains(المؤلف) td:last-child, .tsinfo .imptdt:contains(المؤلف) i, .fmed b:contains(المؤلف)+span, span:contains(المؤلف), " +
                  ".infotable tr:contains(Mangaka) td:last-child, .tsinfo .imptdt:contains(Mangaka) i, .fmed b:contains(Mangaka)+span, span:contains(Mangaka), " +
                  ".infotable tr:contains(seniman) td:last-child, .tsinfo .imptdt:contains(seniman) i, .fmed b:contains(seniman)+span, span:contains(seniman), " +
                  ".infotable tr:contains(Pengarang) td:last-child, .tsinfo .imptdt:contains(Pengarang) i, .fmed b:contains(Pengarang)+span, span:contains(Pengarang), " +
                  ".infotable tr:contains(Yazar) td:last-child, .tsinfo .imptdt:contains(Yazar) i, .fmed b:contains(Yazar)+span, span:contains(Yazar), " +
                  ".infotable tr:contains(ผู้วาด) td:last-child, .tsinfo .imptdt:contains(ผู้วาด) i, .fmed b:contains(ผู้วาด)+span, span:contains(ผู้วาด), ",
            )
            .text;

    manga.description =
        seriesDetails
            .selectFirst(".desc, .entry-content[itemprop=description]")
            ?.text;
    final status =
        seriesDetails
            .selectFirst(
              ".infotable tr:contains(status) td:last-child, .tsinfo .imptdt:contains(status) i, .fmed b:contains(status)+span span:contains(status), " +
                  ".infotable tr:contains(Statut) td:last-child, .tsinfo .imptdt:contains(Statut) i, .fmed b:contains(Statut)+span span:contains(Statut), " +
                  ".infotable tr:contains(Durum) td:last-child, .tsinfo .imptdt:contains(Durum) i, .fmed b:contains(Durum)+span span:contains(Durum), " +
                  ".infotable tr:contains(連載状況) td:last-child, .tsinfo .imptdt:contains(連載状況) i, .fmed b:contains(連載状況)+span span:contains(連載状況), " +
                  ".infotable tr:contains(Estado) td:last-child, .tsinfo .imptdt:contains(Estado) i, .fmed b:contains(Estado)+span span:contains(Estado), " +
                  ".infotable tr:contains(الحالة) td:last-child, .tsinfo .imptdt:contains(الحالة) i, .fmed b:contains(الحالة)+span span:contains(الحالة), " +
                  ".infotable tr:contains(حالة العمل) td:last-child, .tsinfo .imptdt:contains(حالة العمل) i, .fmed b:contains(حالة العمل)+span span:contains(حالة العمل), " +
                  ".infotable tr:contains(สถานะ) td:last-child, .tsinfo .imptdt:contains(สถานะ) i, .fmed b:contains(สถานะ)+span span:contains(สถานะ), " +
                  ".infotable tr:contains(stato) td:last-child, .tsinfo .imptdt:contains(stato) i, .fmed b:contains(stato)+span span:contains(stato), " +
                  ".infotable tr:contains(Statüsü) td:last-child, .tsinfo .imptdt:contains(Statüsü) i, .fmed b:contains(Statüsü)+span span:contains(Statüsü), " +
                  ".infotable tr:contains(สถานะ) td:last-child, .tsinfo .imptdt:contains(สถานะ) i, .fmed b:contains(สถานะ)+span span:contains(สถานะ)",
            )
            ?.text ??
        "";
    manga.status = parseStatus(status, statusList);
    manga.genre =
        seriesDetails
            .select(
              "div.gnr a, .mgen a, .seriestugenre a, " +
                  "span:contains(genre) , span:contains(التصنيف)",
            )
            .map((e) => e.text)
            .toList();
    final elements = document.select(
      "div.bxcl li, div.cl li, #chapterlist li, ul li:has(div.chbox):has(div.eph-num)",
    );
    List<MChapter>? chaptersList = [];
    for (var element in elements) {
      final urlElements = element.selectFirst("a");
      final name =
          element.selectFirst(".lch a, .chapternum")?.text ?? urlElements.text;
      var chapter = MChapter();
      chapter.name = name;
      chapter.url = urlElements.attr("href");
      chapter.dateUpload =
          parseDates(
            [
              element.selectFirst(".chapterdate")?.text ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
            ],
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
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse('$baseUrl$url'))).body;

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
    final document = parseHtml(res);
    final elements = document.select(
      ".utao .uta .imgu, .listupd .bs .bsx, .listo .bs .bsx",
    );
    for (var element in elements) {
      String img = element.getSrc;
      if (img.contains("data:image")) {
        img = element.getDataSrc;
      }
      var manga = MManga();
      manga.name = element.selectFirst("a").attr("title");
      manga.imageUrl = img;
      manga.link = element.selectFirst("a").attr("href");
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  List<dynamic> getFilterList() {
    return ignoreFilter()
        ? []
        : [
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

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
        key: "override_baseurl",
        title: "Override BaseUrl",
        summary: "",
        value: source.baseUrl,
        dialogTitle: "Override BaseUrl",
        dialogMessage: "Default: ${source.baseUrl}",
        text: source.baseUrl,
      ),
    ];
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }

  String getMangaUrlDirectory(String sourceName) {
    if (["Sushi-Scan"].contains(sourceName)) {
      return "/catalogue";
    }
    return "/manga";
  }

  String getMangaSearchUrl(int page, String query) {
    if (["Sushi-Scan"].contains(source.name)) {
      return "/page/$page/?s=$query";
    }
    return "/?s=$query&page=$page";
  }

  bool ignoreFilter() {
    return ["Sushi-Scan"].contains(source.name);
  }
}

MangaReader main(MSource source) {
  return MangaReader(source: source);
}

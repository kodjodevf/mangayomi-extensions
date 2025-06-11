import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MMRCMS extends MProvider {
  MMRCMS({required this.source});

  MSource source;
  static final Set<String> latestTitles = <String>{};
  final Client client = Client();

  MManga mangaFromElement(MElement element) {
    final anchor = element.selectFirst(".media-heading a, .manga-heading a");
    final link = anchor?.getHref;

    return MManga()
      ..name = anchor?.text
      ..imageUrl = guessCover(link, url: element.selectFirst("img")?.getSrc)
      ..link = link;
  }

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(
      Uri.parse(
        "${source.baseUrl}/filterList?page=$page&sortBy=views&asc=false",
      ),
    )).body;
    final document = parseHtml(res);
    final mangaList = <MManga>[];
    for (final el in document.select("div.chapter-container, div.media")) {
      final manga = mangaFromElement(el);
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    if (page == 1) latestTitles.clear();

    final res = (await client.get(
      Uri.parse("${source.baseUrl}/latest-release?page=$page"),
    )).body;

    final document = parseHtml(res);
    final mangaList = <MManga>[];

    for (var el in document.select("div.mangalist div.manga-item")) {
      final manga = mangaFromElement(el);
      final link = manga.link;

      if (link != null && latestTitles.add(link)) {
        mangaList.add(manga);
      }
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
        } else {
          urls.add('${source.baseUrl}/manga/$data');
        }
        names.add(value);
        images.add(
          "${source.baseUrl}/uploads/manga/$data/cover/cover_250x350.jpg",
        );
      }
    } else {
      urls = xpath(res, '//div/div/div/a/@href');
      names = xpath(res, '//div/div/div/a/text()');
      for (var mangaUrl in urls) {
        images.add(guessCover(mangaUrl));
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
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    final manga = MManga();

    // Title
    final mangaTitle = document
        .selectFirst(".panel-heading, .listmanga-header, .widget-title")
        ?.text;
    manga.name = mangaTitle;

    // Cover
    manga.imageUrl = guessCover(
      url,
      url: document.selectFirst(".row img.img-responsive")?.getSrc,
    );

    // Description
    manga.description = extractDescription(document);

    document.select('.panel-body h3, .row .dl-horizontal dt').forEach((
      element,
    ) {
      final label = _getOwnText(
        element,
      ).toLowerCase().replaceFirst(RegExp(r' :$'), '');

      final valueElement = element.selectFirst('div.text');
      if (valueElement.text == null)
        final valueElement = element.nextElementSibling;

      _assignMangaInfo(manga, label, valueElement);
    });

    // Chapters
    List<MChapter>? chaptersList = [];
    for (var ch in document.select("ul.chapters > li:not(.btn)")) {
      chaptersList.add(chapterFromElement(ch, mangaTitle));
    }
    manga.chapters = chaptersList;

    return manga;
  }

  MChapter chapterFromElement(MElement element, String mangaTitle) {
    final chapter = MChapter();

    final titleWrapper = element.selectFirst(".chapter-title-rtl");
    final anchor = titleWrapper?.selectFirst("a");

    if (anchor != null) {
      chapter.url = anchor.getHref ?? '';
      chapter.name = cleanChapterName(titleWrapper.text, mangaTitle);

      final dateElement = element.selectFirst(".date-chapter-title-rtl");

      if (dateElement != null && dateElement.text.isNotEmpty) {
        chapter.dateUpload = parseDates(
          [dateElement.text],
          source.dateFormat,
          source.dateFormatLocale,
        )[0];
      } else {
        chapter.dateUpload = DateTime.now().millisecondsSinceEpoch.toString();
      }
    }

    return chapter;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final res = (await client.get(Uri.parse(url))).body;

    List<String> pagesUrl = [];
    final pages = xpath(
      res,
      '//*[@id="all"]/img[@class="img-responsive"]/@data-src',
    );
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
      ]),
    ];
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }

  String guessCover(String mangaUrl, {String? url}) {
    if (url == null || url?.endsWith("no-image.png")) {
      String slug = substringAfterLast(mangaUrl, '/');
      return "${source.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg";
    } else if (url?.startsWith(source.baseUrl)) {
      return url;
    } else {
      return Uri.parse(source.baseUrl).resolve(url).toString();
    }
  }

  String extractDescription(MDocument document) {
    final container = document.selectFirst(".row .well");
    if (container == null) return "";

    String text = container.text;

    container.select("h5").forEach((element) {
      text = text.replaceAll(element.text, "");
    });

    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String _getOwnText(MElement element) {
    final text = element.text;
    final childrenText = element.children.map((e) => e.text).join();
    return text.replaceFirst(childrenText, '').trim();
  }

  void _assignMangaInfo(MManga manga, String label, MElement valueElement) {
    if (_detailAuthor.contains(label)) {
      manga.author = valueElement.text;
    } else if (_detailArtist.contains(label)) {
      manga.artist = valueElement.text;
    } else if (_detailGenre.contains(label)) {
      manga.genre = valueElement?.select("a").map((e) => e.text).toList;
    } else if (_detailStatus.contains(label)) {
      manga.status = parseStatus(valueElement.text, statusList);
    }
  }

  String cleanChapterName(String name, String mangaTitle) {
    const chapterString = "Chapter";
    const chapterNamePrefix = "";

    try {
      final initialName = name.replaceFirst(
        '$chapterNamePrefix$mangaTitle',
        chapterString,
      );

      final parts = initialName.split(':');

      if (parts.isEmpty) return name;

      final firstPart = parts[0].trim();
      if (parts.length == 1) return firstPart;

      final secondPart = parts.sublist(1).join(':').trim();

      return firstPart == secondPart ? firstPart : "$firstPart: $secondPart";
    } catch (e) {
      return name;
    }
  }

  const _detailAuthor = {
    'author(s)',
    'autor(es)',
    'auteur(s)',
    '著作',
    'yazar(lar)',
    'mangaka(lar)',
    'pengarang/penulis',
    'pengarang',
    'penulis',
    'autor',
    'المؤلف',
    'перевод',
    'autor/autorzy',
  };

  const _detailArtist = {
    'artist(s)',
    'artiste(s)',
    'sanatçi(lar)',
    'artista(s)',
    'artist(s)/ilustrator',
    'الرسام',
    'seniman',
    'rysownik/rysownicy',
    'artista',
  };

  const _detailGenre = {
    'categories',
    'categorías',
    'catégories',
    'ジャンル',
    'kategoriler',
    'categorias',
    'kategorie',
    'التصنيفات',
    'жанр',
    'kategori',
    'tagi',
    'género',
  };

  const _detailStatus = {
    'status',
    'statut',
    'estado',
    '状態',
    'durum',
    'الحالة',
    'статус',
  };

  const statusList = [
    {
      // Ongoing Statuses (0)
      'ongoing': 0,
      'مستمرة': 0,
      'en cours': 0,
      'em lançamento': 0,
      'prace w toku': 0,
      'ativo': 0,
      'em andamento': 0,
      'activo': 0,

      // Complete Statuses (1)
      'complete': 1,
      'مكتملة': 1,
      'complet': 1,
      'completo': 1,
      'zakończone': 1,
      'concluído': 1,
      'finalizado': 1,

      // Dropped Statuses (3)
      'dropped': 3,
    },
  ];
}

MMRCMS main(MSource source) {
  return MMRCMS(source: source);
}

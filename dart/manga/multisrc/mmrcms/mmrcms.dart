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
      Uri.parse("${getBaseUrl()}/filterList?page=$page&sortBy=views&asc=false"),
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
      Uri.parse("${getBaseUrl()}/latest-release?page=$page"),
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
    String url = getBaseUrl();
    List<MManga> mangaList = [];

    bool hasNextPage = false;
    if (query.isNotEmpty) {
      url = "$url/search?query=$query";
      final res = (await client.get(Uri.parse(url))).body;
      final jsonList = json.decode(res)["suggestions"];

      for (var da in jsonList) {
        String value = da["value"];
        String data = da["data"];
        final mangaSubString = getMangaSubString();
        final path = mangaSubString.isEmpty ? data : '$mangaSubString/$data';

        mangaList.add(
          MManga(
            name: value,
            link: '${getBaseUrl()}/$path',
            imageUrl: guessCover('/$path'),
          ),
        );
      }
    }

    return MPages(mangaList, hasNextPage);
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
    final response = await client.get(Uri.parse(url));
    final document = parseHtml(response.body);

    List<String> pagesUrl = [];
    for (var img in document.select('#all img.img-responsive[data-src]')) {
      String? src = img.attr('data-src');
      if (src.startsWith('//')) {
        pagesUrl.add('https:${src}');
      } else {
        pagesUrl.add(src);
      }
    }

    return pagesUrl;
  }

  @override
  List<dynamic> getFilterList() {
    return [];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
        key: "domain_url",
        title: getTitleByLang(source.lang),
        summary: "",
        value: source.baseUrl,
        dialogTitle: "URL",
        dialogMessage: "",
      ),
    ];
  }

  String getBaseUrl() {
    final baseUrl = getPreferenceValue(source.id, "domain_url")?.trim();

    if (baseUrl == null || baseUrl.isEmpty) {
      return source.baseUrl;
    }

    return baseUrl.endsWith("/")
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  String getTitleByLang(String? lang) {
    const titles = {
      'ar': 'تحرير الرابط',
      'en': 'Edit URL',
      'fr': 'Modifier l’URL',
      'es': 'Editar URL',
      'de': 'URL bearbeiten',
      'tr': 'URL’yi düzenle',
      'ru': 'Редактировать URL',
      'id': 'Edit URL',
      'pt': 'Editar URL',
      'it': 'Modifica URL',
      'ja': 'URLを編集',
      'zh': '编辑网址',
      'ko': 'URL 편집',
      'fa': 'ویرایش نشانی',
    };

    return titles[lang?.toLowerCase()] ?? titles['en']!;
  }

  String getMangaSubString() {
    const sourceTypeMap = {'Scan VF': "", "Read Comics Online": "comic"};

    return sourceTypeMap[source.name] ?? "manga";
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }

  String guessCover(String mangaUrl, {String? url}) {
    String baseUrl = getBaseUrl();
    if (url == null || url?.endsWith("no-image.png")) {
      String slug = substringAfterLast(mangaUrl, '/');
      return "${baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg";
    } else if (url?.startsWith(baseUrl)) {
      return url;
    } else {
      return Uri.parse(baseUrl).resolve(url).toString();
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

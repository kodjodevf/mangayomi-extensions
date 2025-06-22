import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Madara extends MProvider {
  Madara({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(
      Uri.parse(
        "${getBaseUrl()}/${getMangaSubString()}/page/$page/?m_orderby=views",
      ),
    )).body;
    final document = parseHtml(res);
    return mangaFromElements(document.select("div.page-item-detail"));
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(
      Uri.parse(
        "${getBaseUrl()}/${getMangaSubString()}/page/$page/?m_orderby=latest",
      ),
    )).body;
    final document = parseHtml(res);
    return mangaFromElements(document.select("div.page-item-detail"));
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;

    String url = "${getBaseUrl()}/?s=$query&post_type=wp-manga";

    for (var filter in filters) {
      if (filter.type == "AuthorFilter") {
        if (filter.state.isNotEmpty) {
          url += "${ll(url)}author=${Uri.encodeComponent(filter.state)}";
        }
      } else if (filter.type == "ArtistFilter") {
        if (filter.state.isNotEmpty) {
          url += "${ll(url)}artist=${Uri.encodeComponent(filter.state)}";
        }
      } else if (filter.type == "YearFilter") {
        if (filter.state.isNotEmpty) {
          url += "${ll(url)}release=${Uri.encodeComponent(filter.state)}";
        }
      } else if (filter.type == "StatusFilter") {
        List<String> status = filter.state
            .where((item) => item.state)
            .map((item) => item.value.toString())
            .toList();
        if (status.isNotEmpty) {
          url += "${ll(url)}status[]=${status.join('&status[]=')}";
        }
      } else if (filter.type == "OrderByFilter") {
        if (filter.state != 0) {
          final order = filter.values[filter.state].value;
          url += "${ll(url)}m_orderby=$order";
        }
      } else if (filter.type == "AdultContentFilter") {
        final ctn = filter.values[filter.state].value;
        if (ctn.isNotEmpty) {
          url += "${ll(url)}adult=$ctn";
        }
      } else if (filter.type == "GenreListFilter") {
        final genres = (filter.state as List).where((e) => e.state).toList();
        if (genres.isNotEmpty) {
          for (var genre in genres) {
            url += "${ll(url)}genre[]=${genre.value},";
          }
        }
      }
    }

    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    return mangaFromElements(document.select("div.c-tabs-item__content"));
  }

  List<MChapter> getChapters(MDocument chapDoc) {
    List<MChapter> chapters = [];
    for (MElement element in chapDoc.select("li.wp-manga-chapter") ?? []) {
      var ch = element.selectFirst("a");
      if (ch != null) {
        var url = ch.attr("href");
        if (url != null && url.isNotEmpty) {
          url = substringBefore(url, "?style=paged");
          if (url.endsWith("?style=paged")) {
            url = url + "?style=paged";
          }
          var chapter = MChapter();
          chapter.url = url;
          chapter.name = ch.text;
          if (source.dateFormat.isNotEmpty) {
            var chd = element.selectFirst("span.chapter-release-date");
            if (chd != null && chd.text.isNotEmpty) {
              var dates = parseDates(
                [chd.text],
                source.dateFormat,
                source.dateFormatLocale,
              );
              chapter.dateUpload = dates[0];
            } else {
              chapter.dateUpload = DateTime.now().millisecondsSinceEpoch
                  .toString();
            }
          }
          chapters.add(chapter);
        }
      }
    }
    return chapters;
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {
        // Ongoing
        "OnGoing": 0,
        "Продолжается": 0,
        "Updating": 0,
        "Em Lançamento": 0,
        "Em lançamento": 0,
        "Em andamento": 0,
        "Em Andamento": 0,
        "En cours": 0,
        "En Cours": 0,
        "En cours de publication": 0,
        "Ativo": 0,
        "Lançando": 0,
        "Đang Tiến Hành": 0,
        "Devam Ediyor": 0,
        "Devam ediyor": 0,
        "Devam Ediyo": 0,
        "Devam Eden": 0,
        "In Corso": 0,
        "In Arrivo": 0,
        "مستمرة": 0,
        "مستمر": 0,
        "En Curso": 0,
        "En curso": 0,
        "Curso": 0,
        "Emision": 0,
        "En marcha": 0,
        "Publicandose": 0,
        "Publicándose": 0,
        "En emision": 0,
        "连载中": 0,
        "Đang làm": 0,
        "Em postagem": 0,
        "Em progresso": 0,
        "Em curso": 0,
        "Atualizações Semanais": 0,

        // Completed
        "Completed": 1,
        "Completo": 1,
        "Completado": 1,
        "Concluído": 1,
        "Concluido": 1,
        "Finalizado": 1,
        "Achevé": 1,
        "Terminé": 1,
        "Complété": 1,
        "Hoàn Thành": 1,
        "Tamamlandı": 1,
        "Tamamlanan": 1,
        "Đã hoàn thành": 1,
        "Завершено": 1,
        "مكتملة": 1,
        "مكتمل": 1,
        "已完结": 1,

        // On Hold
        "On Hold": 2,
        "Pausado": 2,
        "En espera": 2,
        "Durduruldu": 2,
        "Beklemede": 2,
        "Đang chờ": 2,
        "متوقف": 2,
        "En Pause": 2,
        "Заморожено": 2,
        "En attente": 2,

        // Canceled
        "Canceled": 3,
        "Cancelado": 3,
        "İptal Edildi": 3,
        "Güncel": 3,
        "Đã hủy": 3,
        "ملغي": 3,
        "Abandonné": 3,
        "Заброшено": 3,
        "Annulé": 3,

        // Publishing Finished 4
      },
    ];
    MManga manga = MManga();
    String res = "";
    res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    manga.author = document.selectFirst("div.author-content > a")?.text ?? "";

    final descriptionElement = document.select(
      "div.description-summary div.summary__content, div.summary_content div.post-content_item > h5 + div, div.summary_content div.manga-excerpt, .manga-summary",
    );
    if (descriptionElement.isNotEmpty) {
      final paragraphs = descriptionElement
          .expand((e) => e.select("p"))
          .toList();

      if (paragraphs.isNotEmpty &&
          paragraphs.any((p) => p.text.trim().isNotEmpty)) {
        manga.description = paragraphs
            .map((p) => p.text.replaceAll("<br>", "\n").trim())
            .join("\n\n");
      } else {
        manga.description = descriptionElement
            .map((e) => e.text.trim())
            .join("\n\n");
      }
    }

    final imageElement = document.selectFirst("div.summary_image img");
    manga.imageUrl = extractImageUrl(imageElement);

    final id =
        document
            .selectFirst("div[id^=manga-chapters-holder]")
            ?.attr("data-id") ??
        "";
    String mangaId = "";
    if (id.isNotEmpty) {
      mangaId = id;
    }
    final status =
        document
            .selectFirst(
              ".summary-content > .tags-content, div.summary-content, div.summary-heading:contains(Status) + div",
            )
            ?.text ??
        "";

    manga.status = parseStatus(status, statusList);
    manga.genre =
        document.select("div.genres-content a")?.map((e) => e.text).toList() ??
        [];

    final baseUrl = "${getBaseUrl()}/";
    final headers = {"Referer": baseUrl, "X-Requested-With": "XMLHttpRequest"};

    final oldXhrChaptersRequest = await client.post(
      Uri.parse("${baseUrl}wp-admin/admin-ajax.php"),
      headers: headers,
      body: {"action": "manga_get_chapters", "manga": mangaId},
    );
    if (oldXhrChaptersRequest.statusCode == 400) {
      res = (await client.post(
        Uri.parse("${url}ajax/chapters"),
        headers: headers,
      )).body;
    } else {
      res = oldXhrChaptersRequest.body;
    }

    MDocument chapDoc = parseHtml(res);
    manga.chapters = getChapters(chapDoc);
    if (manga.chapters.isEmpty) {
      res = (await client.post(
        Uri.parse("${url}ajax/chapters"),
        headers: headers,
      )).body;
      chapDoc = parseHtml(res);
      manga.chapters = getChapters(chapDoc);
    }

    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final res = (await client.get(Uri.parse(url)));
    final document = parseHtml(res.body);

    final pageElements = document.select(
      "div.page-break, li.blocks-gallery-item, .reading-content .text-left:not(:has(.blocks-gallery-item)) img",
    );

    List<String> imgs = [];
    for (var element in pageElements) {
      try {
        final imgElement = element.selectFirst("img");
        final img = extractImageUrl(imageElement);
        imgs.add(img);
      } catch (_) {}
    }

    List<String> pageUrls = [];

    if (imgs.length == 1) {
      final pagesNumber = document
          .selectFirst("#single-pager")
          .select("option")
          .length;
      final imgUrl = imgs.first;
      for (var i = 0; i < pagesNumber; i++) {
        final val = i + 1;
        if (i.toString().length == 1) {
          pageUrls.add(imgUrl.replaceAll("01", '0$val'));
        } else {
          pageUrls.add(imgUrl.replaceAll("01", val.toString()));
        }
      }
    } else {
      return imgs;
    }
    return pageUrls;
  }

  MPages mangaFromElements(List<MElement> elements) {
    List<MManga> mangaList = [];

    for (var i = 0; i < elements.length; i++) {
      final postTitle = elements[i].selectFirst("div.post-title a");
      final imageElement = elements[i].selectFirst("img");
      final image = extractImageUrl(imageElement);

      MManga manga = MManga();
      manga.name = postTitle.text;
      manga.imageUrl = substringBefore(image, " ");
      manga.link = postTitle.getHref;
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  List<dynamic> getFilterList() {
    return [
      TextFilter("AuthorFilter", "Author"),
      TextFilter("ArtistFilter", "Artist"),
      TextFilter("YearFilter", "Year of Released"),
      GroupFilter("StatusFilter", "Status", [
        CheckBoxFilter("Completed", "end"),
        CheckBoxFilter("Ongoing", "on-going"),
        CheckBoxFilter("Canceled", "canceled"),
        CheckBoxFilter("On Hold", "on-hold"),
      ]),
      SelectFilter("OrderByFilter", "Order By", 0, [
        SelectFilterOption("Relevance", ""),
        SelectFilterOption("Latest", "latest"),
        SelectFilterOption("A-Z", "alphabet"),
        SelectFilterOption("Rating", "rating"),
        SelectFilterOption("Trending", "trending"),
        SelectFilterOption("Most Views", "views"),
        SelectFilterOption("New", "new-manga"),
      ]),
      SelectFilter("AdultContentFilter", "Adult Content", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("None", "0"),
        SelectFilterOption("Only", "1"),
      ]),
    ];
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

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }

  String? extractImageUrl(Element? imageElement) {
    if (imageElement == null) return "";

    return imageElement.attr("data-src") ??
        imageElement.attr("data-lazy-src") ??
        imageElement.attr("srcset")?.split(" ")?.first ??
        imageElement.getSrc ??
        "";
  }

  String getMangaSubString() {
    const worksSources = {"Olaoe", "Mangax Core"};
    return worksSources.contains(source.name) ? "works" : "manga";
  }
}

Madara main(MSource source) {
  return Madara(source: source);
}

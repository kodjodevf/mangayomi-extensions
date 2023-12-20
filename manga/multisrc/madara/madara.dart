import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Madara extends MProvider {
  Madara();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final url = "${source.baseUrl}/manga/page/$page/?m_orderby=views";
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));
    final document = parseHtml(res);
    return mangaFromElements(document.select("div.page-item-detail"));
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final url = "${source.baseUrl}/manga/page/$page/?m_orderby=latest";
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));
    final document = parseHtml(res);
    return mangaFromElements(document.select("div.page-item-detail"));
  }

  @override
  Future<MPages> search(
      MSource source, String query, int page, FilterList filterList) async {
    final filters = filterList.filters;

    String url = "${source.baseUrl}/?s=$query&post_type=wp-manga";

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
        final status = (filter.state as List).where((e) => e.state).toList();
        if (status.isNotEmpty) {
          for (var st in status) {
            url += "${ll(url)}status[]=${st.value},";
          }
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
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));
    final document = parseHtml(res);
    return mangaFromElements(document.select("div.c-tabs-item__content"));
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {
        "OnGoing": 0,
        "Продолжается": 0,
        "Updating": 0,
        "Em Lançamento": 0,
        "Em lançamento": 0,
        "Em andamento": 0,
        "Em Andamento": 0,
        "En cours": 0,
        "Ativo": 0,
        "Lançando": 0,
        "Đang Tiến Hành": 0,
        "Devam Ediyor": 0,
        "Devam ediyor": 0,
        "In Corso": 0,
        "In Arrivo": 0,
        "مستمرة": 0,
        "مستمر": 0,
        "En Curso": 0,
        "En curso": 0,
        "Emision": 0,
        "En marcha": 0,
        "Publicandose": 0,
        "En emision": 0,
        "连载中": 0,
        "Completed": 1,
        "Completo": 1,
        "Completado": 1,
        "Concluído": 1,
        "Concluido": 1,
        "Finalizado": 1,
        "Terminé": 1,
        "Hoàn Thành": 1,
        "مكتملة": 1,
        "مكتمل": 1,
        "已完结": 1,
        "On Hold": 2,
        "Pausado": 2,
        "En espera": 2,
        "Canceled": 3,
        "Cancelado": 3,
      }
    ];
    MManga manga = MManga();
    String res = "";
    final datas = {"url": url, "sourceId": source.id};
    res = await http('GET', json.encode(datas));
    final document = parseHtml(res);
    manga.author = document.selectFirst("div.author-content > a")?.text ?? "";

    manga.description = document
            .selectFirst(
                "div.description-summary div.summary__content, div.summary_content div.post-content_item > h5 + div, div.summary_content div.manga-excerpt, div.sinopsis div.contenedor, .description-summary > p")
            ?.text ??
        "";

    final imageElement = document.selectFirst("div.summary_image img");
    final image = imageElement?.attr("data-src") ??
        imageElement?.attr("data-lazy-src") ??
        imageElement?.attr("srcset") ??
        imageElement?.getSrc;
    if (image != null) {
      manga.imageUrl = image;
    }

    final id = document
            .selectFirst("div[id^=manga-chapters-holder]")
            ?.attr("data-id") ??
        "";
    String mangaId = "";
    if (id.isNotEmpty) {
      mangaId = id;
    }
    final status = document.selectFirst("div.summary-content")?.text ?? "";
    manga.status = parseStatus(status, statusList);
    manga.genre =
        document.select("div.genres-content a")?.map((e) => e.text).toList() ??
            [];

    final baseUrl = "${source.baseUrl}/";
    final headers = {
      "Referer": baseUrl,
      "Content-Type": "application/x-www-form-urlencoded",
      "X-Requested-With": "XMLHttpRequest"
    };
    final urll =
        "${baseUrl}wp-admin/admin-ajax.php?action=manga_get_chapters&manga=$mangaId";
    final datasP = {"url": urll, "headers": headers, "sourceId": source.id};
    res = await http('POST', json.encode(datasP));
    if (res == "error" || mangaId.isEmpty) {
      final urlP = "${url}ajax/chapters";
      final datasP = {"url": urlP, "headers": headers, "sourceId": source.id};
      res = await http('POST', json.encode(datasP));
    }

    List<MChapter> chaptersList =
        parseHtml(res).select('li.wp-manga-chapter').map((MElement e) {
      String date = "";
      List<MElement>? dateEList = e
          .select('img')
          ?.where((MElement e) => !(e.className.contains("thumb")))
          .toList();
      if (dateEList != null && dateEList.isNotEmpty) {
        final dateE = (dateEList.first as MElement).attr("alt");
        if (dateE != null) {
          date = parseDates([dateE], source.dateFormat, source.dateFormatLocale)
              .first;
        }
      }
      if (date.isEmpty) {
        final dateE = e.selectFirst('span a')?.attr("title");
        if (dateE != null) {
          date = parseDates([dateE], source.dateFormat, source.dateFormatLocale)
              .first;
        }
      }
      if (date.isEmpty) {
        final dateE = e.selectFirst('span.chapter-release-date')?.text;
        if (dateE != null) {
          date = parseDates([dateE], source.dateFormat, source.dateFormatLocale)
              .first;
        }
      }
      MChapter chapter = MChapter();
      chapter.name = e.selectFirst('a').text;
      chapter.url = e.selectFirst('a').getHref;
      if (source.dateFormat.isNotEmpty) chapter.dateUpload = date;
      return chapter;
    }).toList();
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource source, String url) async {
    final datas = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(datas));
    final document = parseHtml(res);
    final pageElement = document.selectFirst(
        "div.page-break, li.blocks-gallery-item, .reading-content, .text-left img");

    List<String> imgs = pageElement.select("img").map((e) => e.getSrc).toList();

    List<String> pageUrls = [];

    if (imgs.length == 1) {
      final pagesNumber =
          document.selectFirst("#single-pager").select("option");

      for (var i = 0; i < pagesNumber.length; i++) {
        final val = i + 1;
        if (i.toString().length == 1) {
          pageUrls.add(imgs.first.replaceAll("01", '0$val'));
        } else {
          pageUrls.add(imgs.first.replaceAll("01", val.toString()));
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
      final image = imageElement?.attr("data-src") ??
          imageElement?.attr("data-lazy-src") ??
          imageElement?.attr("srcset") ??
          imageElement?.getSrc ??
          "";
      MManga manga = MManga();
      manga.name = postTitle.text;
      manga.imageUrl = substringBefore(image, " ");
      manga.link = postTitle.getHref;
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  List<dynamic> getFilterList(MSource source) {
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

Madara main() {
  return Madara();
}

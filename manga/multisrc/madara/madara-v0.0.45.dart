import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Madara extends MProvider {
  Madara();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final url = "${source.baseUrl}/manga/page/$page/?m_orderby=views";
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));

    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[@class^="post-title"]/h3/a/@href');
    final names = xpath(res, '//*[@id^="manga-item"]/a/@title');
    var images = xpath(res, '//*[@id^="manga-item"]/a/img/@data-src');
    if (images.isEmpty) {
      images = xpath(res, '//*[@id^="manga-item"]/a/img/@data-lazy-src');
      if (images.isEmpty) {
        images = xpath(res, '//*[@id^="manga-item"]/a/img/@srcset');
        if (images.isEmpty) {
          images = xpath(res, '//*[@id^="manga-item"]/a/img/@src');
        }
      }
    }

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = substringBefore(images[i], " ");
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final url = "${source.baseUrl}/manga/page/$page/?m_orderby=latest";
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));

    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[@class^="post-title"]/h3/a/@href');
    final names = xpath(res, '//*[@id^="manga-item"]/a/@title');
    var images = xpath(res, '//*[@id^="manga-item"]/a/img/@data-src');
    if (images.isEmpty) {
      images = xpath(res, '//*[@id^="manga-item"]/a/img/@data-lazy-src');
      if (images.isEmpty) {
        images = xpath(res, '//*[@id^="manga-item"]/a/img/@srcset');
        if (images.isEmpty) {
          images = xpath(res, '//*[@id^="manga-item"]/a/img/@src');
        }
      }
    }

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = substringBefore(images[i], " ");
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
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

    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/@href');
    final names = xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/@title');
    var images =
        xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@data-src');
    if (images.isEmpty) {
      images = xpath(
          res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@data-lazy-src');
      if (images.isEmpty) {
        images =
            xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@srcset');
        if (images.isEmpty) {
          images =
              xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@src');
        }
      }
    }

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = substringBefore(images[i], " ");
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
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

    final author = querySelectorAll(res,
        selector: "div.author-content > a",
        typeElement: 0,
        attributes: "",
        typeRegExp: 0);
    if (author.isNotEmpty) {
      manga.author = author.first;
    }
    final description = querySelectorAll(res,
        selector:
            "div.description-summary div.summary__content, div.summary_content div.post-content_item > h5 + div, div.summary_content div.manga-excerpt, div.sinopsis div.contenedor, .description-summary > p",
        typeElement: 0,
        attributes: "",
        typeRegExp: 0);
    if (description.isNotEmpty) {
      manga.description = description.first;
    }
    final imageUrl = querySelectorAll(res,
        selector: "div.summary_image img",
        typeElement: 2,
        attributes: "",
        typeRegExp: 2);
    if (imageUrl.isNotEmpty) {
      manga.imageUrl = imageUrl.first;
    }
    String mangaId = "";

    final id = querySelectorAll(res,
        selector: "div[id^=manga-chapters-holder]",
        typeElement: 3,
        attributes: "data-id",
        typeRegExp: 0);
    if (id.isNotEmpty) {
      mangaId = id.first;
    }
    final status = querySelectorAll(res,
        selector: "div.summary-content",
        typeElement: 0,
        attributes: "",
        typeRegExp: 0);
    if (status.isNotEmpty) {
      manga.status = parseStatus(status.last, statusList);
    }
    manga.genre = querySelectorAll(res,
        selector: "div.genres-content a",
        typeElement: 0,
        attributes: "",
        typeRegExp: 0);
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
    print("datasP");
    if (res == "error" || mangaId.isEmpty) {
      final urlP = "${url}ajax/chapters";
      final datasP = {"url": urlP, "headers": headers, "sourceId": source.id};
      res = await http('POST', json.encode(datasP));
    }
    var chapUrls = xpath(res, '//li[@class^="wp-manga-chapter"]/a/@href');
    var chaptersNames = xpath(res, '//li[@class^="wp-manga-chapter"]/a/text()');
    var dateF = xpath(res, '//li[@class^="wp-manga-chapter"]/span/i/text()');
    if (dateF.isEmpty) {
      final resWebview = await getHtmlViaWebview(
          url, "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/@href");
      chapUrls = xpath(resWebview,
          "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/@href");
      chaptersNames = xpath(resWebview,
          "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/text()");
      dateF = xpath(resWebview,
          "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/span/i/text()");
    }
    List<String> dateUploads = [];
    if (source.dateFormat.isNotEmpty) {
      dateUploads =
          parseDates(dateF, source.dateFormat, source.dateFormatLocale);
      if (dateF.length < chaptersNames.length) {
        final length = chaptersNames.length - dateF.length;
        String date = "${DateTime.now().millisecondsSinceEpoch}";
        for (var i = 0; i < length - 1; i++) {
          date += "--..${DateTime.now().millisecondsSinceEpoch}";
        }

        final dateFF =
            parseDates(dateF, source.dateFormat, source.dateFormatLocale);
        List<String> chapterDate = date.split('--..');

        for (var date in dateFF) {
          chapterDate.add(date);
        }
        dateUploads = chapterDate;
      }
    }

    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chaptersNames.length; i++) {
      MChapter chapter = MChapter();
      chapter.name = chaptersNames[i];
      chapter.url = chapUrls[i];
      if (source.dateFormat.isNotEmpty) chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource source, String url) async {
    final datas = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(datas));

    final pagesSelectorRes = querySelectorAll(res,
            selector:
                "div.page-break, li.blocks-gallery-item, .reading-content, .text-left img",
            typeElement: 1,
            attributes: "",
            typeRegExp: 0)
        .first;
    final imgs = querySelectorAll(pagesSelectorRes,
        selector: "img", typeElement: 2, attributes: "", typeRegExp: 2);
    List<String> pageUrls = [];

    if (imgs.length == 1) {
      final pages = querySelectorAll(res,
              selector: "#single-pager",
              typeElement: 2,
              attributes: "",
              typeRegExp: 0)
          .first;

      final pagesNumber = querySelectorAll(pages,
          selector: "option", typeElement: 2, attributes: "", typeRegExp: 0);

      for (var i = 0; i < pagesNumber.length; i++) {
        final val = i + 1;
        if (i.toString().length == 1) {
          pageUrls.add(querySelectorAll(pagesSelectorRes,
                  selector: "img",
                  typeElement: 2,
                  attributes: "",
                  typeRegExp: 2)
              .first
              .replaceAll("01", '0$val'));
        } else {
          pageUrls.add(querySelectorAll(pagesSelectorRes,
                  selector: "img",
                  typeElement: 2,
                  attributes: "",
                  typeRegExp: 2)
              .first
              .replaceAll("01", val.toString()));
        }
      }
    } else {
      return imgs;
    }
    return pageUrls;
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

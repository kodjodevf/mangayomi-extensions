import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularManga(MManga manga) async {
  final url = "${manga.baseUrl}/manga/page/${manga.page}/?m_orderby=views";
  final data = {"url": url, "sourceId": manga.sourceId};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.urls = MBridge.xpath(res, '//*[@class^="post-title"]/h3/a/@href');
  var images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-src');
  if (images.isEmpty) {
    images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-lazy-src');
    if (images.isEmpty) {
      images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@srcset');
      if (images.isEmpty) {
        images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@src');
      }
    }
  }
  manga.images = images;
  manga.names = MBridge.xpath(res, '//*[@id^="manga-item"]/a/@title');

  return manga;
}

getMangaDetail(MManga manga) async {
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
  MHttpResponse response = MHttpResponse();
  final datas = {"url": manga.link, "sourceId": manga.sourceId};
  response = await MBridge.http('GET', json.encode(datas));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.author = MBridge.querySelectorAll(res,
          selector: "div.author-content > a",
          typeElement: 0,
          attributes: "",
          typeRegExp: 0)
      .first;
  manga.description = MBridge.querySelectorAll(res,
          selector:
              "div.description-summary div.summary__content, div.summary_content div.post-content_item > h5 + div, div.summary_content div.manga-excerpt, div.sinopsis div.contenedor, .description-summary > p",
          typeElement: 0,
          attributes: "",
          typeRegExp: 0)
      .first;
  manga.imageUrl = MBridge.querySelectorAll(res,
          selector: "div.summary_image img",
          typeElement: 2,
          attributes: "",
          typeRegExp: 2)
      .first;
  final mangaId = MBridge.querySelectorAll(res,
          selector: "div[id^=manga-chapters-holder]",
          typeElement: 3,
          attributes: "data-id",
          typeRegExp: 0)
      .first;
  manga.status = MBridge.parseStatus(
      MBridge.querySelectorAll(res,
              selector: "div.summary-content",
              typeElement: 0,
              attributes: "",
              typeRegExp: 0)
          .last,
      statusList);

  manga.genre = MBridge.querySelectorAll(res,
      selector: "div.genres-content a",
      typeElement: 0,
      attributes: "",
      typeRegExp: 0);

  final baseUrl = "${manga.baseUrl}/";
  final headers = {
    "Referer": baseUrl,
    "Content-Type": "application/x-www-form-urlencoded",
    "X-Requested-With": "XMLHttpRequest"
  };
  final url =
      "${baseUrl}wp-admin/admin-ajax.php?action=manga_get_chapters&manga=$mangaId";
  final datasP = {"url": url, "headers": headers, "sourceId": manga.sourceId};

  response = await MBridge.http('POST', json.encode(datasP));
  if (response.statusCode != 200) {
    final urlP = "${manga.link}ajax/chapters";
    final datasP = {
      "url": urlP,
      "headers": headers,
      "sourceId": manga.sourceId
    };
    response = await MBridge.http('POST', json.encode(datasP));
  }

  String resP = response.body;
  manga.urls = MBridge.xpath(resP, "//li/a/@href");
  var chaptersNames = MBridge.xpath(resP, "//li/a/text()");

  var dateF = MBridge.xpath(resP, "//li/span/i/text()");
  if (dateF.isEmpty) {
    final resWebview = await MBridge.getHtmlViaWebview(manga.link,
        "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/@href");
    manga.urls = MBridge.xpath(resWebview,
        "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/@href");
    chaptersNames = MBridge.xpath(resWebview,
        "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/text()");
    dateF = MBridge.xpath(resWebview,
        "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/span/i/text()");
  }

  manga.names = chaptersNames;
  if (dateF.length == chaptersNames.length) {
    manga.chaptersDateUploads = MBridge.listParseDateTime(
        dateF, manga.dateFormat, manga.dateFormatLocale);
  } else if (dateF.length < chaptersNames.length) {
    final length = chaptersNames.length - dateF.length;
    String date = "${DateTime.now().millisecondsSinceEpoch}";
    for (var i = 0; i < length - 1; i++) {
      date += "--..${DateTime.now().millisecondsSinceEpoch}";
    }

    final dateFF = MBridge.listParseDateTime(
        dateF, manga.dateFormat, manga.dateFormatLocale);
    List<String> chapterDate = date.split('--..');

    for (var date in dateFF) {
      chapterDate.add(date);
    }
    manga.chaptersDateUploads = chapterDate;
  }
  return manga;
}

getChapterPages(MManga manga) async {
  final datas = {"url": manga.link, "sourceId": manga.sourceId};
  final response = await MBridge.http('GET', json.encode(datas));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  final pagesSelectorRes = MBridge.querySelectorAll(res,
          selector:
              "div.page-break, li.blocks-gallery-item, .reading-content, .text-left img",
          typeElement: 1,
          attributes: "",
          typeRegExp: 0)
      .first;
  final imgs = MBridge.querySelectorAll(pagesSelectorRes,
      selector: "img", typeElement: 2, attributes: "", typeRegExp: 2);
  var pageUrls = [];

  if (imgs.length == 1) {
    final pages = MBridge.querySelectorAll(res,
            selector: "#single-pager",
            typeElement: 2,
            attributes: "",
            typeRegExp: 0)
        .first;

    final pagesNumber = MBridge.querySelectorAll(pages,
        selector: "option", typeElement: 2, attributes: "", typeRegExp: 0);

    for (var i = 0; i < pagesNumber.length; i++) {
      final val = i + 1;
      if (i.toString().length == 1) {
        pageUrls.add(MBridge.querySelectorAll(pagesSelectorRes,
                selector: "img", typeElement: 2, attributes: "", typeRegExp: 2)
            .first
            .replaceAll("01", '0$val'));
      } else {
        pageUrls.add(MBridge.querySelectorAll(pagesSelectorRes,
                selector: "img", typeElement: 2, attributes: "", typeRegExp: 2)
            .first
            .replaceAll("01", val.toString()));
      }
    }
  } else {
    return imgs;
  }
  return pageUrls;
}

getLatestUpdatesManga(MManga manga) async {
  final url = "${manga.baseUrl}/manga/page/${manga.page}/?m_orderby=latest";
  final datas = {"url": url, "sourceId": manga.sourceId};
  final response = await MBridge.http('GET', json.encode(datas));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.urls = MBridge.xpath(res, '//*[@class^="post-title"]/h3/a/@href');
  var images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-src');
  if (images.isEmpty) {
    images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-lazy-src');
    if (images.isEmpty) {
      images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@srcset');
      if (images.isEmpty) {
        images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@src');
      }
    }
  }
  manga.images = images;
  manga.names = MBridge.xpath(res, '//*[@id^="manga-item"]/a/@title');
  return manga;
}

searchManga(MManga manga) async {
  final urll = "${manga.baseUrl}/?s=${manga.query}&post_type=wp-manga";
  final datas = {"url": urll, "sourceId": manga.sourceId};
  final response = await MBridge.http('GET', json.encode(datas));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.urls =
      MBridge.xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/@href');
  var images = MBridge.xpath(
      res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@data-src');
  if (images.isEmpty) {
    images = MBridge.xpath(
        res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@data-lazy-src');
    if (images.isEmpty) {
      images = MBridge.xpath(
          res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@srcset');
      if (images.isEmpty) {
        images = MBridge.xpath(
            res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@src');
      }
    }
  }
  manga.images = images;
  manga.names =
      MBridge.xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/@title');
  return manga;
}

Map<String, String> getHeader(String url) {
  final headers = {
    "Referer": "$url/",
  };
  return headers;
}

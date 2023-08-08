import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/manga/page/${manga.page}/?m_orderby=views";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls = MBridge.xpath(res, '//*[@class^="post-title"]/h3/a/@href', '-.')
      .split("-.");
  String images =
      MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-src', '-.');
  if (images.isEmpty) {
    images =
        MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-lazy-src', '-.');
    if (images.isEmpty) {
      images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@srcset', '-.');
      if (images.isEmpty) {
        images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@src', '-.');
      }
    }
  }
  manga.images = images.split("-.");
  manga.names =
      MBridge.xpath(res, '//*[@id^="manga-item"]/a/@title', '-.').split("-.");

  return manga;
}

getMangaDetail(MangaModel manga) async {
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

  final datas = {
    "url": manga.link,
    "headers": null,
    "sourceId": manga.sourceId
  };
  final res = await MBridge.http(json.encode(datas), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.author =
      MBridge.querySelectorAll(res, "div.author-content > a", 0, "", 0, 0, "");
  manga.description = MBridge.querySelectorAll(
      res,
      "div.description-summary div.summary__content, div.summary_content div.post-content_item > h5 + div, div.summary_content div.manga-excerpt, div.sinopsis div.contenedor, .description-summary > p",
      0,
      "",
      0,
      0,
      "");
  manga.imageUrl =
      MBridge.querySelectorAll(res, "div.summary_image img", 2, "", 2, 1, "");
  final mangaId = MBridge.querySelectorAll(
      res, "div[id^=manga-chapters-holder]", 3, "data-id", 0, 1, "");
  manga.status = MBridge.parseStatus(
      MBridge.querySelectorAll(res, "div.summary-content", 0, "", 0, 2, ""),
      statusList);

  manga.genre =
      MBridge.querySelectorAll(res, "div.genres-content a", 0, "", 0, 0, "-.")
          .split("-.");

  final baseUrl = "${manga.baseUrl}/";
  final headers = {
    "Referer": baseUrl,
    "Content-Type": "application/x-www-form-urlencoded",
    "X-Requested-With": "XMLHttpRequest"
  };
  final url =
      "${baseUrl}wp-admin/admin-ajax.php?action=manga_get_chapters&manga=$mangaId";
  final datasP = {"url": url, "headers": headers, "sourceId": manga.sourceId};

  String resP = await MBridge.http(json.encode(datasP), 1);
  if (resP == "400") {
    final urlP = "${manga.link}ajax/chapters";
    final datasP = {
      "url": urlP,
      "headers": headers,
      "sourceId": manga.sourceId
    };
    resP = await MBridge.http(json.encode(datasP), 1);
  }
  manga.urls = MBridge.xpath(resP, "//li/a/@href", '-.').split("-.");
  List<dynamic> chaptersNames =
      MBridge.xpath(resP, "//li/a/text()", '-.').split("-.");

  List<dynamic> dateF =
      MBridge.xpath(resP, "//li/span/i/text()", '-.').split("-.");
  if (MBridge.xpath(resP, "//li/a/text()", "").isEmpty) {
    final resWebview = await MBridge.getHtmlViaWebview(manga.link,
        "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/@href");
    manga.urls = MBridge.xpath(resWebview,
            "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/@href", '-.')
        .split("-.");
    chaptersNames = MBridge.xpath(resWebview,
            "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/a/text()", '-.')
        .split("-.");
    dateF = MBridge.xpath(
            resWebview,
            "//*[@id='manga-chapters-holder']/div[2]/div/ul/li/span/i/text()",
            '-.')
        .split("-.");
  }

  manga.names = chaptersNames;
  List<String> chapterDate = [];
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
    List<String> chapterDate = MBridge.listParse(date.split('--..'), 0);

    for (var date in dateFF) {
      chapterDate.add(date);
    }
    manga.chaptersDateUploads = chapterDate;
  }
  return manga;
}

getChapterUrl(MangaModel manga) async {
  final datas = {
    "url": manga.link,
    "headers": null,
    "sourceId": manga.sourceId
  };
  final res = await MBridge.http(json.encode(datas), 0);
  if (res.isEmpty) {
    return [];
  }
  final pagesSelectorRes = MBridge.querySelector(
      res,
      "div.page-break, li.blocks-gallery-item, .reading-content, .text-left img",
      1,
      "");
  final imgs =
      MBridge.querySelectorAll(pagesSelectorRes, "img", 2, "", 2, 0, '-.')
          .split('-.');
  List<dynamic> pageUrls = [];

  if (imgs.length == 1) {
    final pages = MBridge.querySelector(res, "#single-pager", 2, "");

    final pagesNumber =
        MBridge.querySelectorAll(pages, "option", 2, "", 0, 0, '-.')
            .split('-.');

    for (var i = 0; i < pagesNumber.length; i++) {
      final val = i + 1;
      if (i.toString().length == 1) {
        pageUrls.add(
            MBridge.querySelectorAll(pagesSelectorRes, "img", 2, "", 2, 0, "")
                .replaceAll("01", '0$val'));
      } else {
        pageUrls.add(
            MBridge.querySelectorAll(pagesSelectorRes, "img", 2, "", 2, 0, "")
                .replaceAll("01", val.toString()));
      }
    }
  } else {
    return imgs;
  }
  return pageUrls;
}

getLatestUpdatesManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/manga/page/${manga.page}/?m_orderby=latest";
  final datas = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(datas), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls = MBridge.xpath(res, '//*[@class^="post-title"]/h3/a/@href', '-.')
      .split("-.");
  String images =
      MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-src', '-.');
  if (images.isEmpty) {
    images =
        MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@data-lazy-src', '-.');
    if (images.isEmpty) {
      images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@srcset', '-.');
      if (images.isEmpty) {
        images = MBridge.xpath(res, '//*[@id^="manga-item"]/a/img/@src', '-.');
      }
    }
  }
  manga.images = images.split("-.");
  manga.names =
      MBridge.xpath(res, '//*[@id^="manga-item"]/a/@title', '-.').split("-.");
  return manga;
}

searchManga(MangaModel manga) async {
  final urll = "${manga.baseUrl}/?s=${manga.query}&post_type=wp-manga";
  final datas = {"url": urll, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(datas), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls =
      MBridge.xpath(res, '//*[@class^="tab-thumb c-image-hover"]/a/@href', '-.')
          .split("-.");
  String images = MBridge.xpath(
      res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@data-src', '-.');
  if (images.isEmpty) {
    images = MBridge.xpath(res,
        '//*[@class^="tab-thumb c-image-hover"]/a/img/@data-lazy-src', '-.');
    if (images.isEmpty) {
      images = MBridge.xpath(
          res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@srcset', '-.');
      if (images.isEmpty) {
        images = MBridge.xpath(
            res, '//*[@class^="tab-thumb c-image-hover"]/a/img/@src', '-.');
      }
    }
  }
  manga.images = images.split("-.");
  manga.names = MBridge.xpath(
          res, '//*[@class^="tab-thumb c-image-hover"]/a/@title', '-.')
      .split("-.");
  return manga;
}

Map<String, String> getHeader(String url) {
  final headers = {
    "Referer": "$url/",
  };
  return headers;
}

import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularManga(MangaModel manga) async {
  final url =
      "${manga.baseUrl}${getMangaUrlDirectory(manga.source)}/?page=${manga.page}&order=popular";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls =
      MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@href', '._')
          .split('._');
  manga.names =
      MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@title', '._')
          .split('._');
  manga.images = MBridge.xpath(
          res, '//*[ @class="imgu"  or @class="bsx"]/a/div[1]/img/@src', '._')
      .split('._');
  return manga;
}

getLatestUpdatesManga(MangaModel manga) async {
  final url =
      "${manga.baseUrl}${getMangaUrlDirectory(manga.source)}/?page=${manga.page}&order=update";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls =
      MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@href', '._')
          .split('._');
  manga.names =
      MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@title', '._')
          .split('._');
  manga.images = MBridge.xpath(
          res, '//*[ @class="imgu"  or @class="bsx"]/a/div[1]/img/@src', '._')
      .split('._');
  return manga;
}

getMangaDetail(MangaModel manga) async {
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

  final datas = {
    "url": manga.link,
    "headers": null,
    "sourceId": manga.sourceId
  };
  final res = await MBridge.http(json.encode(datas), 0);

  if (res.isEmpty) {
    return manga;
  }
  manga.author = MBridge.xpath(
          res,
          '//*[@class="imptdt" and contains(text(), "Author") or @class="infotable" and contains(text(), "Author") or @class="infotable" and contains(text(), "Auteur") or @class="fmed" and contains(text(), "Auteur") or @class="infotable" and contains(text(), "Autor")]/text()',
          '')
      .replaceAll("Autor", "")
      .replaceAll("Author", "")
      .replaceAll("Auteur", "")
      .replaceAll("[Add, ]", "");

  manga.description = MBridge.querySelectorAll(
      res, ".desc, .entry-content[itemprop=description]", 0, "", 0, 0, "");

  final status = MBridge.xpath(
          res,
          '//*[@class="imptdt" and contains(text(), "Status") or @class="imptdt" and contains(text(), "Estado") or @class="infotable" and contains(text(), "Status") or @class="infotable" and contains(text(), "Statut") or @class="imptdt" and contains(text(), "Statut")]/text()',
          '')
      .replaceAll("Status", "")
      .replaceAll("Estado", "")
      .replaceAll("Statut", "");

  manga.status = MBridge.parseStatus(status, statusList);

  manga.genre = MBridge.xpath(
          res,
          '//*[@class="gnr"  or @class="mgen"  or @class="seriestugenre" ]/a/text()',
          "-.")
      .split("-.");
  manga.urls = MBridge.xpath(
          res,
          '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a[not(@href="#/chapter-{{number}}")]/@href',
          "-.")
      .split("-.");
  manga.names = MBridge.xpath(
          res,
          '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a/span[@class="chapternum" and not(text()="Chapter {{number}}") or @class="lch" and not(text()="Chapter {{number}}")]/text()',
          "-.")
      .split("-.");

  final chaptersDateUploads = MBridge.xpath(
          res,
          '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a/span[@class="chapterdate" and not(text()="{{date}}")]/text()',
          "-.")
      .split("-.");

  manga.chaptersDateUploads = MBridge.listParseDateTime(
      chaptersDateUploads, manga.dateFormat, manga.dateFormatLocale);

  return manga;
}

searchManga(MangaModel manga) async {
  final url =
      "${manga.baseUrl}/manga/?&title=${manga.query}&page=${manga.page}";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls =
      MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@href', '._')
          .split('._');
  manga.names =
      MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@title', '._')
          .split('._');
  manga.images = MBridge.xpath(
          res, '//*[ @class="imgu"  or @class="bsx"]/a/div[1]/img/@src', '._')
      .split('._');
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
  if (manga.source == "Sushi-Scans") {
    final pages = MBridge.xpath(res, '//*[@id="readerarea"]/p/img/@src', "._._")
        .split("._._");
    return pages;
  }
  List<String> pagesUrl = [];
  final pages = MBridge.xpath(res, '//*[@id="readerarea"]/img/@src', "._._")
      .split("._._");
  if (pages.length == 1) {
    final images =
        MBridge.regExp(res, "\"images\"\\s*:\\s*(\\[.*?])", "", 1, 1);
    final pages = MBridge.jsonDecodeToList(images, 0);
    for (var page in pages) {
      pagesUrl.add(page);
    }
  } else {
    return pages;
  }

  return pagesUrl;
}

String getMangaUrlDirectory(String sourceName) {
  if (sourceName == "Sushi-Scan") {
    return "/catalogue";
  }
  return "/manga";
}

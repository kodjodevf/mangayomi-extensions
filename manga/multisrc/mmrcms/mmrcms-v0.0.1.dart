import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

searchManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/search?query=${manga.query}";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  final jsonList = MBridge.jsonPathToList(res, r'$.suggestions[*]', 0);
  List<String> urls = [];
  List<String> names = [];
  List<String> images = [];
  for (var da in jsonList) {
    final value = MBridge.getMapValue(da, "value", 0);
    final data = MBridge.getMapValue(da, "data", 0);

    if (manga.source == 'Scan VF') {
      urls.add('${manga.baseUrl}/$data');
    } else {
      urls.add('${manga.baseUrl}/manga/$data');
    }
    names.add(value);
    if (manga.source == "Manga-FR") {
      images.add("${manga.baseUrl}/uploads/manga/$data.jpg");
    } else {
      images
          .add("${manga.baseUrl}/uploads/manga/$data/cover/cover_250x350.jpg");
    }
  }
  manga.names = names;
  manga.urls = urls;
  manga.images = images;
  return manga;
}

getPopularManga(MangaModel manga) async {
  final url =
      "${manga.baseUrl}/filterList?page=${manga.page}&sortBy=views&asc=false";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls =
      MBridge.xpath(res, '//*[ @class="chart-title"]/@href', '._').split('._');
  manga.names =
      MBridge.xpath(res, '//*[ @class="chart-title"]/text()', '._').split('._');
  List<String> images = [];
  for (var url in manga.urls) {
    if (manga.source == "Manga-FR") {
      images.add(
          "${manga.baseUrl}/uploads/manga/${MBridge.listParse(MBridge.stringParse(url, 0).split('/'), 2)[0]}.jpg");
    } else {
      images.add(
          "${manga.baseUrl}/uploads/manga/${MBridge.listParse(MBridge.stringParse(url, 0).split('/'), 2)[0]}/cover/cover_250x350.jpg");
    }
  }
  manga.images = images;
  return manga;
}

getMangaDetail(MangaModel manga) async {
  final statusList = [
    {
      "complete": 1,
      "complet": 1,
      "completo": 1,
      "zakończone": 1,
      "concluído": 1,
      "مكتملة": 1,
      "ongoing": 0,
      "en cours": 0,
      "em lançamento": 0,
      "prace w toku": 0,
      "ativo": 0,
      "مستمرة": 0,
      "em andamento": 0
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
      '//*[@class="dl-horizontal"]/dt[contains(text(), "Auteur(s)") or contains(text(), "Author(s)") or contains(text(), "Autor(es)") or contains(text(), "Yazar(lar) or contains(text(), "Mangaka(lar)")]//following-sibling::dd[1]/text()',
      '');
  final status = MBridge.xpath(
      res,
      '//*[@class="dl-horizontal"]/dt[contains(text(), "Statut") or contains(text(), "Status") or contains(text(), "Estado") or contains(text(), "Durum")]/following-sibling::dd[1]/text()',
      '');
  manga.status = MBridge.parseStatus(status, statusList);
  manga.description = MBridge.xpath(
      res, '//*[@class="well" or @class="manga well"]/p/text()', '');
  manga.genre = MBridge.xpath(
          res,
          '//*[@class="dl-horizontal"]/dt[contains(text(), "Categories") or contains(text(), "Categorias") or contains(text(), "Categorías") or contains(text(), "Catégories") or contains(text(), "Kategoriler" or contains(text(), "Kategorie") or contains(text(), "Kategori") or contains(text(), "Tagi"))]/following-sibling::dd[1]/text()',
          '')
      .split(',');
  manga.names =
      MBridge.xpath(res, '//*[@class="chapter-title-rtl"]/a/text()', "-.")
          .split("-.");
  manga.urls =
      MBridge.xpath(res, '//*[@class="chapter-title-rtl"]/a/@href', "-.")
          .split("-.");
  final date =
      MBridge.xpath(res, '//*[@class="date-chapter-title-rtl"]/text()', "-.")
          .split("-.");
  manga.chaptersDateUploads =
      MBridge.listParseDateTime(date, "d MMM. yyyy", "en_US");

  return manga;
}

getLatestUpdatesManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/latest-release?page=${manga.page}";
  final data = {"url": url, "headers": null, "sourceId": manga.sourceId};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.urls = MBridge.xpath(res, '//*[@class="manga-item"]/h3/a/@href', '._')
      .split('._');
  manga.names = MBridge.xpath(res, '//*[@class="manga-item"]/h3/a/text()', '._')
      .split('._');
  List<String> images = [];
  for (var url in manga.urls) {
    if (manga.source == "Manga-FR") {
      images.add(
          "${manga.baseUrl}/uploads/manga/${MBridge.listParse(MBridge.stringParse(url, 0).split('/'), 2)[0]}.jpg");
    } else {
      images.add(
          "${manga.baseUrl}/uploads/manga/${MBridge.listParse(MBridge.stringParse(url, 0).split('/'), 2)[0]}/cover/cover_250x350.jpg");
    }
  }
  manga.images = images;
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
  List<String> pagesUrl = [];
  final pages = MBridge.listParse(
      MBridge.xpath(res,
              '//*[@id="all"]/img[@class="img-responsive"]/@data-src', "._._")
          .split("._._"),
      0);
  for (var page in pages) {
    if (page.startsWith('//')) {
      pagesUrl.add(page.replaceAll('//', 'https://'));
    } else {
      pagesUrl.add(page);
    }
  }

  return pagesUrl;
}

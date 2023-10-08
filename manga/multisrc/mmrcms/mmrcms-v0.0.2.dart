import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

searchManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/search?query=${manga.query}";
  final data = {"url": url, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return manga;
  }
  final jsonList = json.decode(res)["suggestions"];
  List<String> urls = [];
  List<String> names = [];
  List<String> images = [];
  for (var da in jsonList) {
    String value = da["value"];
    String data = da["data"];
    if (manga.source == 'Scan VF') {
      urls.add('${manga.baseUrl}/$data');
    } else if (manga.source == 'Manga-FR') {
      urls.add('${manga.baseUrl}/lecture-en-ligne/$data');
    } else {
      urls.add('${manga.baseUrl}/manga/$data');
    }
    names.add(value);
    if (manga.source == "Manga-FR") {
      images.add("${manga.baseUrl}/uploads/manga/$data.jpg");
    } else {
      images.add("${manga.baseUrl}/uploads/manga/$data/cover/cover_250x350.jpg");
    }
  }
  manga.names = names;
  manga.urls = urls;
  manga.images = images;
  return manga;
}

getPopularManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/filterList?page=${manga.page}&sortBy=views&asc=false";
  final data = {"url": url, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return manga;
  }
  manga.urls = MBridge.xpath(res, '//*[ @class="chart-title"]/@href');
  manga.names = MBridge.xpath(res, '//*[ @class="chart-title"]/text()');
  List<String> images = [];
  for (var url in manga.urls) {
    String slug = MBridge.substringAfterLast(url, '/');
    if (manga.source == "Manga-FR") {
      images.add("${manga.baseUrl}/uploads/manga/${slug}.jpg");
    } else {
      images.add("${manga.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg");
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

  final datas = {"url": manga.link, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(datas));
  if (res.isEmpty) {
    return manga;
  }
  manga.author = MBridge.xpath(res,
          '//*[@class="dl-horizontal"]/dt[contains(text(), "Auteur(s)") or contains(text(), "Author(s)") or contains(text(), "Autor(es)") or contains(text(), "Yazar(lar) or contains(text(), "Mangaka(lar)")]//following-sibling::dd[1]/text()')
      .first;
  final status = MBridge.xpath(res,
          '//*[@class="dl-horizontal"]/dt[contains(text(), "Statut") or contains(text(), "Status") or contains(text(), "Estado") or contains(text(), "Durum")]/following-sibling::dd[1]/text()')
      .first;
  manga.status = MBridge.parseStatus(status, statusList);
  manga.description = MBridge.xpath(res, '//*[@class="well" or @class="manga well"]/p/text()').first;
  manga.genre = MBridge.xpath(res,
      '//*[@class="dl-horizontal"]/dt[contains(text(), "Categories") or contains(text(), "Categorias") or contains(text(), "Categorías") or contains(text(), "Catégories") or contains(text(), "Kategoriler" or contains(text(), "Kategorie") or contains(text(), "Kategori") or contains(text(), "Tagi"))]/following-sibling::dd[1]/text()');
  manga.names = MBridge.xpath(res, '//*[@class="chapter-title-rtl"]/a/text()');
  manga.urls = MBridge.xpath(res, '//*[@class="chapter-title-rtl"]/a/@href');
  final date = MBridge.xpath(res, '//*[@class="date-chapter-title-rtl"]/text()');
  manga.chaptersDateUploads = MBridge.listParseDateTime(date, "d MMM. yyyy", "en_US");

  return manga;
}

getLatestUpdatesManga(MangaModel manga) async {
  final url = "${manga.baseUrl}/latest-release?page=${manga.page}";
  final data = {"url": url, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return manga;
  }
  manga.urls = MBridge.xpath(res, '//*[@class="manga-item"]/h3/a/@href');
  manga.names = MBridge.xpath(res, '//*[@class="manga-item"]/h3/a/text()');
  List<String> images = [];
  for (var url in manga.urls) {
    String slug = MBridge.substringAfterLast(url, '/');
    if (manga.source == "Manga-FR") {
      images.add("${manga.baseUrl}/uploads/manga/${slug}.jpg");
    } else {
      images.add("${manga.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg");
    }
  }
  manga.images = images;
  return manga;
}

getChapterUrl(MangaModel manga) async {
  final datas = {"url": manga.link, "sourceId": manga.sourceId};
  final res = await MBridge.http('GET', json.encode(datas));
  if (res.isEmpty) {
    return [];
  }
  List<String> pagesUrl = [];
  final pages = MBridge.xpath(res, '//*[@id="all"]/img[@class="img-responsive"]/@data-src');
  for (var page in pages) {
    if (page.startsWith('//')) {
      pagesUrl.add(page.replaceAll('//', 'https://'));
    } else {
      pagesUrl.add(page);
    }
  }

  return pagesUrl;
}

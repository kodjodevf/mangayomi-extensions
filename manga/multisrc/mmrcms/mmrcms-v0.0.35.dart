import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MMRCMS extends MProvider {
  MMRCMS();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final url =
        "${source.baseUrl}/filterList?page=$page&sortBy=views&asc=false";
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));

    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[ @class="chart-title"]/@href');
    final names = xpath(res, '//*[ @class="chart-title"]/text()');
    List<String> images = [];
    for (var url in urls) {
      String slug = substringAfterLast(url, '/');
      if (source.name == "Manga-FR") {
        images.add("${source.baseUrl}/uploads/manga/${slug}.jpg");
      } else {
        images.add(
            "${source.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg");
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
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final url = "${source.baseUrl}/latest-release?page=$page";
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));

    List<MManga> mangaList = [];
    final urls = xpath(res, '//*[@class="manga-item"]/h3/a/@href');
    final names = xpath(res, '//*[@class="manga-item"]/h3/a/text()');
    List<String> images = [];
    for (var url in urls) {
      String slug = substringAfterLast(url, '/');
      if (source.name == "Manga-FR") {
        images.add("${source.baseUrl}/uploads/manga/${slug}.jpg");
      } else {
        images.add(
            "${source.baseUrl}/uploads/manga/${slug}/cover/cover_250x350.jpg");
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
  Future<MPages> search(MSource source, String query, int page) async {
    final url = "${source.baseUrl}/search?query=$query";
    final data = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(data));

    List<MManga> mangaList = [];
    final jsonList = json.decode(res)["suggestions"];
    List<String> urls = [];
    List<String> names = [];
    List<String> images = [];
    for (var da in jsonList) {
      String value = da["value"];
      String data = da["data"];
      if (source.name == 'Scan VF') {
        urls.add('${source.baseUrl}/$data');
      } else if (source.name == 'Manga-FR') {
        urls.add('${source.baseUrl}/lecture-en-ligne/$data');
      } else {
        urls.add('${source.baseUrl}/manga/$data');
      }
      names.add(value);
      if (source.name == "Manga-FR") {
        images.add("${source.baseUrl}/uploads/manga/$data.jpg");
      } else {
        images.add(
            "${source.baseUrl}/uploads/manga/$data/cover/cover_250x350.jpg");
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
  Future<MManga> getDetail(MSource source, String url) async {
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
    MManga manga = MManga();
    final datas = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(datas));

    final author = xpath(res,
        '//*[@class="dl-horizontal"]/dt[contains(text(), "Auteur(s)") or contains(text(), "Author(s)") or contains(text(), "Autor(es)") or contains(text(), "Yazar(lar) or contains(text(), "Mangaka(lar)")]//following-sibling::dd[1]/text()');
    if (author.isNotEmpty) {
      manga.author = author.first;
    }
    final status = xpath(res,
        '//*[@class="dl-horizontal"]/dt[contains(text(), "Statut") or contains(text(), "Status") or contains(text(), "Estado") or contains(text(), "Durum")]/following-sibling::dd[1]/text()');
    if (status.isNotEmpty) {
      manga.status = parseStatus(status.first, statusList);
    }

    final description =
        xpath(res, '//*[@class="well" or @class="manga well"]/p/text()');
    if (description.isNotEmpty) {
      manga.description = description.first;
    }

    manga.genre = xpath(res,
        '//*[@class="dl-horizontal"]/dt[contains(text(), "Categories") or contains(text(), "Categorias") or contains(text(), "Categorías") or contains(text(), "Catégories") or contains(text(), "Kategoriler" or contains(text(), "Kategorie") or contains(text(), "Kategori") or contains(text(), "Tagi"))]/following-sibling::dd[1]/text()');

    var chapUrls = xpath(res, '//*[@class="chapter-title-rtl"]/a/@href');
    var chaptersNames = xpath(res, '//*[@class="chapter-title-rtl"]/a/text()');
    var chaptersDates =
        xpath(res, '//*[@class="date-chapter-title-rtl"]/text()');

    var dateUploads =
        parseDates(chaptersDates, source.dateFormat, source.dateFormatLocale);

    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chaptersNames.length; i++) {
      MChapter chapter = MChapter();
      chapter.name = chaptersNames[i];
      chapter.url = chapUrls[i];
      chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource source, String url) async {
    final datas = {"url": url, "sourceId": source.id};
    final res = await http('GET', json.encode(datas));

    List<String> pagesUrl = [];
    final pages =
        xpath(res, '//*[@id="all"]/img[@class="img-responsive"]/@data-src');
    for (var page in pages) {
      if (page.startsWith('//')) {
        pagesUrl.add(page.replaceAll('//', 'https://'));
      } else {
        pagesUrl.add(page);
      }
    }

    return pagesUrl;
  }
}

MMRCMS main() {
  return MMRCMS();
}

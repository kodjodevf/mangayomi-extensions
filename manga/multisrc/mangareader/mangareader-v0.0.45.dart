import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaReader extends MSourceProvider {
  MangaReader();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final url =
        "${sourceInfo.baseUrl}${getMangaUrlDirectory(sourceInfo.name)}/?page=$page&order=popular";
    final data = {"url": url, "sourceId": sourceInfo.id};
    final res = await MBridge.http('GET', json.encode(data));

    return mangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final url =
        "${sourceInfo.baseUrl}${getMangaUrlDirectory(sourceInfo.name)}/?page=$page&order=update";
    final data = {"url": url, "sourceId": sourceInfo.id};
    final res = await MBridge.http('GET', json.encode(data));

    return mangaRes(res);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final url =
        "${sourceInfo.baseUrl}${getMangaUrlDirectory(sourceInfo.name)}/?&title=$query&page=$page";
    final data = {"url": url, "sourceId": sourceInfo.id};
    final res = await MBridge.http('GET', json.encode(data));

    return mangaRes(res);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
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

    MManga manga = MManga();
    final datas = {"url": url, "sourceId": sourceInfo.id};
    final res = await MBridge.http('GET', json.encode(datas));

    manga.author = MBridge.xpath(
            res,
            '//*[@class="imptdt" and contains(text(), "Author") or @class="infotable" and contains(text(), "Author") or @class="infotable" and contains(text(), "Auteur") or @class="fmed" and contains(text(), "Auteur") or @class="infotable" and contains(text(), "Autor")]/text()',
            '')
        .first
        .replaceAll("Autor", "")
        .replaceAll("Author", "")
        .replaceAll("Auteur", "")
        .replaceAll("[Add, ]", "");

    manga.description = MBridge.querySelectorAll(res,
            selector: ".desc, .entry-content[itemprop=description]",
            typeElement: 0,
            attributes: "",
            typeRegExp: 0)
        .first;

    final status = MBridge.xpath(
            res,
            '//*[@class="imptdt" and contains(text(), "Status") or @class="imptdt" and contains(text(), "Estado") or @class="infotable" and contains(text(), "Status") or @class="infotable" and contains(text(), "Statut") or @class="imptdt" and contains(text(), "Statut")]/text()',
            '')
        .first
        .replaceAll("Status", "")
        .replaceAll("Estado", "")
        .replaceAll("Statut", "");

    manga.status = MBridge.parseStatus(status, statusList);

    manga.genre = MBridge.xpath(res,
        '//*[@class="gnr"  or @class="mgen"  or @class="seriestugenre" ]/a/text()');

    var chapUrls = MBridge.xpath(res,
        '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a[not(@href="#/chapter-{{number}}")]/@href');
    var chaptersNames = MBridge.xpath(res,
        '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a/span[@class="chapternum" and not(text()="Chapter {{number}}") or @class="lch" and not(text()="Chapter {{number}}")]/text()');
    var chapterDates = MBridge.xpath(res,
        '//*[@class="bxcl"  or @class="cl"  or @class="chbox" or @class="eph-num" or @id="chapterlist"]/div/a/span[@class="chapterdate" and not(text()="{{date}}")]/text()');

    var dateUploads = MBridge.parseDates(
        chapterDates, sourceInfo.dateFormat, sourceInfo.dateFormatLocale);

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
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    final datas = {"url": url, "sourceId": sourceInfo.id};
    final res = await MBridge.http('GET', json.encode(datas));

    List<String> pages = [];
    List<String> pagesUrl = [];
    pages = MBridge.xpath(res, '//*[@id="readerarea"]/p/img/@src');
    if (pages.isEmpty || pages.length == 1) {
      pages = MBridge.xpath(res, '//*[@id="readerarea"]/img/@src');
    }
    if (pages.isEmpty || pages.length == 1) {
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

  MPages mangaRes(String res) {
    List<MManga> mangaList = [];
    final urls =
        MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@href');
    final names =
        MBridge.xpath(res, '//*[ @class="imgu"  or @class="bsx"]/a/@title');
    final images = MBridge.xpath(
        res, '//*[ @class="imgu"  or @class="bsx"]/a/div[1]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  String getMangaUrlDirectory(String sourceName) {
    if (sourceName == "Sushi-Scan") {
      return "/catalogue";
    }
    return "/manga";
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    return [];
  }
}

MangaReader main() {
  return MangaReader();
}

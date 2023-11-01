import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class NepNep extends MProvider {
  NepNep();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/search/"};
    final res = await http('GET', json.encode(data));

    final directory = directoryFromDocument(res);
    final resSort = sortMapList(json.decode(directory), "vm", 1);

    return parseDirectory(resSort);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/search/"};
    final res = await http('GET', json.encode(data));

    final directory = directoryFromDocument(res);
    final resSort = sortMapList(json.decode(directory), "lt", 1);

    return parseDirectory(resSort);
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    final data = {"url": "${source.baseUrl}/search/"};
    final res = await http('GET', json.encode(data));

    final directory = directoryFromDocument(res);
    final resSort = sortMapList(json.decode(directory), "lt", 1);
    final datas = json.decode(resSort) as List;
    final queryRes = datas.where((e) {
      String name = e['s'];
      return name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return parseDirectory(json.encode(queryRes));
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1, "Cancelled": 3, "Hiatus": 2}
    ];
    final headers = getHeader(source.baseUrl);
    final data = {"url": '${source.baseUrl}/manga/$url', "headers": headers};
    final res = await http('GET', json.encode(data));
    MManga manga = MManga();
    manga.author = xpath(res,
            '//li[contains(@class,"list-group-item") and contains(text(),"Author")]/a/text()')
        .first;
    manga.description = xpath(res,
            '//li[contains(@class,"list-group-item") and contains(text(),"Description:")]/div/text()')
        .first;
    final status = xpath(res,
            '//li[contains(@class,"list-group-item") and contains(text(),"Status")]/a/text()')
        .first;

    manga.status = parseStatus(toStatus(status), statusList);
    manga.genre = xpath(res,
        '//li[contains(@class,"list-group-item") and contains(text(),"Genre(s)")]/a/text()');

    final script =
        xpath(res, '//script[contains(text(), "MainFunction")]/text()').first;
    final vmChapters =
        substringBefore(substringAfter(script, "vm.Chapters = "), ";");
    final chapters = json.decode(vmChapters) as List;

    List<MChapter> chaptersList = [];

    for (var ch in chapters) {
      MChapter chapter = MChapter();
      String name = ch['ChapterName'] ?? "";
      String indexChapter = ch['Chapter'];
      if (name.isEmpty) {
        name = '${ch['Type']} ${chapterImage(indexChapter, true)}';
      }
      chapter.name = name;
      chapter.url =
          '/read-online/${substringAfter(url, "/manga/")}${chapterURLEncode(ch['Chapter'])}';
      chapter.dateUpload =
          parseDates([ch['Date']], source.dateFormat, source.dateFormatLocale)
              .first;
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(MSource source, String url) async {
    final headers = getHeader(source.baseUrl);
    List<String> pages = [];
    final data = {"url": '${source.baseUrl}$url', "headers": headers};
    print(data);
    final res = await http('GET', json.encode(data));
    final script =
        xpath(res, '//script[contains(text(), "MainFunction")]/text()').first;
    final chapScript = json.decode(
        substringBefore(substringAfter(script, "vm.CurChapter = "), ";"));
    final pathName = substringBefore(
        substringAfter(script, "vm.CurPathName = \"", ""), "\"");
    var directory = chapScript['Directory'] ?? '';
    if (directory.length > 0) {
      directory += '/';
    }
    final mangaName =
        substringBefore(substringAfter(url, "/read-online/"), "-chapter");
    var chNum = chapterImage(chapScript['Chapter'], false);
    var totalPages = int.parse(chapScript['Page']);
    for (int page = 1; page <= totalPages; page++) {
      String paddedPageNumber = "$page".padLeft(3, '0');
      String pageUrl =
          'https://$pathName/manga/$mangaName/$directory$chNum-$paddedPageNumber.png';

      pages.add(pageUrl);
    }
    return pages;
  }

  String directoryFromDocument(String res) {
    final script =
        xpath(res, '//script[contains(text(), "MainFunction")]/text()').first;
    return substringBefore(
            substringAfter(script, "vm.Directory = "), "vm.GetIntValue")
        .replaceAll(";", " ");
  }

  MPages parseDirectory(String res) {
    List<MManga> mangaList = [];
    final datas = json.decode(res) as List;
    for (var data in datas) {
      MManga manga = MManga();
      manga.name = data["s"];
      manga.imageUrl = 'https://temp.compsci88.com/cover/${data['i']}.jpg';
      manga.link = data["i"];
      mangaList.add(manga);
    }
    return MPages(mangaList, true);
  }

  String chapterImage(String e, bool cleanString) {
    var a = e.substring(1, e.length - 1);
    if (cleanString) {
      a = regExp(a, r'^0+', "", 0, 0);
    }

    var b = int.parse(e.substring(e.length - 1));

    if (b == 0 && a.isNotEmpty) {
      return a;
    } else if (b == 0 && a.isEmpty) {
      return '0';
    } else {
      return '$a.$b';
    }
  }

  String toStatus(String status) {
    if (status.contains("Ongoing")) {
      return "Ongoing";
    } else if (status.contains("Complete")) {
      return "Complete";
    } else if (status.contains("Cancelled")) {
      return "Cancelled";
    } else if (status.contains("Hiatus")) {
      return "Hiatus";
    }
    return "";
  }

  String chapterURLEncode(String e) {
    var index = ''.toString();
    var t = int.parse(e.substring(0, 1));

    if (t != 1) {
      index = '-index-$t';
    }

    var dgt = 0;
    var inta = int.parse(e);
    if (inta < 100100) {
      dgt = 4;
    } else if (inta < 101000) {
      dgt = 3;
    } else if (inta < 110000) {
      dgt = 2;
    } else {
      dgt = 1;
    }

    final n = e.substring(dgt, e.length - 1);
    var suffix = ''.toString();
    final path = int.parse(e.substring(e.length - 1));

    if (path != 0) {
      suffix = '.$path';
    }

    return '-chapter-$n$suffix$index.html';
  }
}

Map<String, String> getHeader(String url) {
  final headers = {
    'Referer': '$url/',
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:71.0) Gecko/20100101 Firefox/77.0"
  };
  return headers;
}

NepNep main() {
  return NepNep();
}

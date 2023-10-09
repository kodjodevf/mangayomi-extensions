import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

searchManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);

  String res = "".toString();
  if (!useNewQueryEndpoint(manga.source)) {
    final url = "${manga.apiUrl}/series/search";
    final body = {"term": manga.query};
    final data = {"url": url, "headers": headers, "body": body};
    res = await MBridge.http('POST', json.encode(data));
    if (res.isEmpty) {
      return manga;
    }
  } else {
    final newEndpointUrl = "${manga.apiUrl}/query";
    final newEndpointBody = {
      "query_string": manga.query,
      "series_status": "All",
      "page": manga.page,
      "order": "desc",
      "order_by": "total_views",
      "perPage": "12",
      "tags_ids": "[]",
      "series_type": "Comic"
    };
    final newEndpointData = {
      "url": newEndpointUrl,
      "headers": headers,
      "newEndpointBody": newEndpointBody
    };
    res = await MBridge.http('GET', json.encode(newEndpointData));
    if (res.isEmpty) {
      return manga;
    }
  }

  return mangaModelRes(res, manga);
}

getPopularManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  String res = "".toString();
  if (!useNewQueryEndpoint(manga.source)) {
    final url = "${manga.apiUrl}/series/querysearch";
    print(url);

    final body = {
      "page": manga.page,
      "order": "desc",
      "order_by": "total_views",
      "series_status": "Ongoing",
      "series_type": "Comic"
    };
    final data = {
      "url": url,
      "headers": headers,
      "sourceId": manga.sourceId,
      "body": body
    };

    res = await MBridge.http('POST', json.encode(data));
  } else {
    final newEndpointUrl = "${manga.apiUrl}/query";
    final newEndpointBody = {
      "query_string": "",
      "series_status": "All",
      "page": manga.page,
      "order": "desc",
      "order_by": "total_views",
      "perPage": "12",
      "tags_ids": "[]",
      "series_type": "Comic"
    };
    final newEndpointData = {
      "url": newEndpointUrl,
      "headers": headers,
      "sourceId": manga.sourceId,
      "body": newEndpointBody
    };
    print("sssssssssssssssssssss");
    res = await MBridge.http('GET', json.encode(newEndpointData));
  }
  if (res.isEmpty) {
    return manga;
  }
  return mangaModelRes(res, manga);
}

getLatestUpdatesManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  String res = "".toString();
  if (!useNewQueryEndpoint(manga.source)) {
    final url = "${manga.apiUrl}/series/querysearch";
    final body = {
      "page": manga.page,
      "order": "desc",
      "order_by": "latest",
      "series_status": "Ongoing",
      "series_type": "Comic"
    };
    final data = {
      "url": url,
      "headers": headers,
      "sourceId": manga.sourceId,
      "body": body
    };
    res = await MBridge.http('POST', json.encode(data));
  } else {
    final newEndpointUrl = "${manga.apiUrl}/query";
    final newEndpointBody = {
      "query_string": "",
      "series_status": "All",
      "page": manga.page,
      "order": "desc",
      "order_by": "latest",
      "perPage": "12",
      "tags_ids": "[]",
      "series_type": "Comic"
    };
    final newEndpointData = {
      "url": newEndpointUrl,
      "headers": headers,
      "sourceId": manga.sourceId,
      "body": newEndpointBody
    };
    res = await MBridge.http('GET', json.encode(newEndpointData));
    print(res);
  }

  if (res.isEmpty) {
    return manga;
  }
  return mangaModelRes(res, manga);
}

getMangaDetail(MangaModel manga) async {
  String currentSlug = MBridge.substringAfterLast(manga.link, "/");
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.apiUrl}/series/$currentSlug";
  final data = {"url": url, "headers": headers};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return manga;
  }
  print(res);
  manga.author = MBridge.getMapValue(res, "author");

  manga.description = MBridge.getMapValue(res, "description");
  manga.genre =
      MBridge.jsonPathToString(res, r"$.tags[*].name", "._").split("._");
  List<String> chapterTitles = [];
  List<String> chapterUrls = [];
  List<String> chapterDates = [];

  if (!useNewQueryEndpoint(manga.source)) {
    for (var chapter in json.decode(res)["chapters"]) {
      final chapterName = chapter["chapter_name"];
      final chapterSlug = chapter["chapter_slug"];
      final chapterId = chapter["id"];
      final createdAt = chapter["created_at"];
      chapterUrls.add("/series/$currentSlug/$chapterSlug#$chapterId");
      chapterTitles.add(chapterName);
      chapterDates.add(createdAt);
    }
  } else {
    final seasons = json.decode(res)["seasons"].first;
    for (var chapter in seasons["chapters"]) {
      final chapterName = chapter["chapter_name"];
      final chapterSlug = chapter["chapter_slug"];
      final chapterId = chapter["id"];
      final createdAt = chapter["created_at"];
      chapterUrls.add("/series/$currentSlug/$chapterSlug#$chapterId");
      chapterTitles.add(chapterName);
      chapterDates.add(createdAt);
    }
  }

  if (!useNewQueryEndpoint(manga.source)) {
    manga.urls = chapterUrls.reversed.toList();
    manga.names = chapterTitles.reversed.toList();
    manga.chaptersDateUploads = MBridge.listParseDateTime(
            chapterDates, manga.dateFormat, manga.dateFormatLocale)
        .reversed
        .toList();
  } else {
    manga.urls = chapterUrls;
    manga.names = chapterTitles;
    manga.chaptersDateUploads = MBridge.listParseDateTime(
        chapterDates, manga.dateFormat, manga.dateFormatLocale);
  }
  return manga;
}

getChapterUrl(MangaModel manga) async {
  String res = "".toString();
  final headers = getHeader(manga.baseUrl);
  if (!useslugStrategy(manga.source)) {
    String chapterId = MBridge.substringAfter(manga.link, '#');

    final url = "${manga.apiUrl}/series/chapter/$chapterId";
    final data = {"url": url, "headers": headers};
    res = await MBridge.http('GET', json.encode(data));
  } else {
    final url = "${manga.baseUrl}${manga.link}";
    final data = {"url": url, "headers": headers};
    res = await MBridge.http('GET', json.encode(data));
    List<String> pageUrls = [];
    var imagesRes = MBridge.querySelectorAll(res,
        selector: "div.min-h-screen > div.container > p.items-center",
        typeElement: 1,
        attributes: "",
        typeRegExp: 0);
    pageUrls = MBridge.xpath(imagesRes.first, '//img/@src');

    pageUrls.addAll(MBridge.xpath(imagesRes.first, '//img/@data-src'));

    return pageUrls.where((e) => e.isNotEmpty).toList();
  }

  if (res.isEmpty) {
    return [];
  }
  final pages = MBridge.jsonPathToList(res, r"$.content.images[*]", 0);
  List<String> pageUrls = [];
  for (var u in pages) {
    final url = u.replaceAll('"', "");
    if (url.startsWith("http")) {
      pageUrls.add(url);
    } else {
      pageUrls.add("${manga.apiUrl}/$url");
    }
  }
  return pageUrls;
}

Map<String, String> getHeader(String url) {
  final headers = {
    'Origin': url,
    'Referer': '$url/',
    'Accept': 'application/json, text/plain, */*',
    'Content-Type': 'application/json'
  };
  return headers;
}

bool useNewQueryEndpoint(String sourceName) {
  List<String> sources = ["YugenMangas", "Perf Scan", "Reaper Scans"];
  return sources.contains(sourceName);
}

bool useslugStrategy(String sourceName) {
  List<String> sources = ["YugenMangas", "Reaper Scans", "Perf Scan"];
  return sources.contains(sourceName);
}

MangaModel mangaModelRes(String res, MangaModel manga) {
  List<String> names = [];
  List<String> urls = [];
  List<String> images = [];

  if (res.startsWith("{")) {
    for (var a in json.decode(res)["data"]) {
      String thumbnail = a["thumbnail"];
      if (thumbnail.startsWith("https://")) {
        images.add(thumbnail);
      } else {
        images.add("${manga.apiUrl}/cover/$thumbnail");
      }
      names.add(a["title"]);
      final seriesSlug = MBridge.regExp(a["series_slug"], "-\\d+", "", 0, 0);
      urls.add("/series/$seriesSlug");
    }
  } else {
    for (var a in json.decode(res)) {
      String thumbnail = a["thumbnail"];
      if (thumbnail.startsWith("https://")) {
        images.add(thumbnail);
      } else {
        images.add("${manga.apiUrl}/cover/$thumbnail");
      }
      names.add(a["title"]);
      final seriesSlug = MBridge.regExp(a["series_slug"], "-\\d+", "", 0, 0);
      urls.add("/series/$seriesSlug");
    }
  }

  manga.urls = urls;
  manga.images = images;
  manga.names = names;
  return manga;
}

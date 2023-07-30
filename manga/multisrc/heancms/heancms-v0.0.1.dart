import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

searchManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.apiUrl}/series/search";
  final body = {"term": manga.query};
  final data = {"url": url, "headers": headers, "body": body};
  final res = await MBridge.http(json.encode(data), 1);
  if (res.isEmpty) {
    return manga;
  }
  List<String> jsonList = [];
  List<String> names = [];
  List<String> urls = [];
  List<String> images = [];
  if (res.startsWith("{")) {
    jsonList = MBridge.jsonPathToList(res, r'$.data[*]', 0);
  } else {
    jsonList = MBridge.jsonDecodeToList(res,0);
  }
  for (var a in jsonList) {
    final thumbnail = MBridge.getMapValue(a, "thumbnail", 0);
    if (thumbnail.startsWith("https://")) {
      images.add(thumbnail);
    } else {
      images.add("${manga.apiUrl}/cover/$thumbnail");
    }
    names.add(MBridge.getMapValue(a, "title", 0));
    final seriesSlug = MBridge.regExp(
        MBridge.getMapValue(a, "series_slug", 0), "-\\d+", "", 0, 0);
    urls.add("/series/$seriesSlug");
  }
  manga.urls = urls;
  manga.images = images;
  manga.names = names;
  return manga;
}

getPopularManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.apiUrl}/series/querysearch";
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
  final res = await MBridge.http(json.encode(data), 1);
  if (res.isEmpty) {
    return manga;
  }
  List<String> jsonList = [];
  List<String> names = [];
  List<String> urls = [];
  List<String> images = [];
  if (res.startsWith("{")) {
    jsonList = MBridge.jsonPathToList(res, r'$.data[*]', 0);
  } else {
    jsonList = MBridge.jsonDecodeToList(res,0);
  }
  for (var a in jsonList) {
    final thumbnail = MBridge.getMapValue(a, "thumbnail", 0);
    if (thumbnail.startsWith("https://")) {
      images.add(thumbnail);
    } else {
      images.add("${manga.apiUrl}/cover/$thumbnail");
    }
    names.add(MBridge.getMapValue(a, "title", 0));
    final seriesSlug = MBridge.regExp(
        MBridge.getMapValue(a, "series_slug", 0), "-\\d+", "", 0, 0);
    urls.add("/series/$seriesSlug");
  }
  manga.urls = urls;
  manga.images = images;
  manga.names = names;
  return manga;
}

getLatestUpdatesManga(MangaModel manga) async {
  final headers = getHeader(manga.baseUrl);
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
  final res = await MBridge.http(json.encode(data), 1);
  if (res.isEmpty) {
    return manga;
  }
  List<String> jsonList = [];
  List<String> names = [];
  List<String> urls = [];
  List<String> images = [];
  if (res.startsWith("{")) {
    jsonList = MBridge.jsonPathToList(res, r'$.data[*]', 0);
  } else {
    jsonList = MBridge.jsonDecodeToList(res,0);
  }
  for (var a in jsonList) {
    final thumbnail = MBridge.getMapValue(a, "thumbnail", 0);
    if (thumbnail.startsWith("https://")) {
      images.add(thumbnail);
    } else {
      images.add("${manga.apiUrl}/cover/$thumbnail");
    }
    names.add(MBridge.getMapValue(a, "title", 0));
    final seriesSlug = MBridge.regExp(
        MBridge.getMapValue(a, "series_slug", 0), "-\\d+", "", 0, 0);
    urls.add("/series/$seriesSlug");
  }
  manga.urls = urls;
  manga.images = images;
  manga.names = names;
  return manga;
}

getMangaDetail(MangaModel manga) async {
  String currentSlug = MBridge.listParse(manga.link.split('/'), 2)[0];

  final headers = getHeader(manga.baseUrl);
  final url = "${manga.apiUrl}/series/$currentSlug";
  final data = {"url": url, "headers": headers};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return manga;
  }
  manga.author = MBridge.getMapValue(res, "author", 0);

  manga.description = MBridge.getMapValue(res, "description", 0);
  manga.genre =
      MBridge.jsonPathToString(res, r"$.tags[*].name", "._").split("._");

  final chapters = MBridge.jsonPathToList(res, r"$.chapters[*]", 0);
  List<String> chapterTitles = [];
  List<String> chapterUrls = [];
  List<String> chapterDates = [];
  for (var chapter in chapters) {
    final chapterName = MBridge.getMapValue(chapter, "chapter_name", 0);
    final chapterSlug = MBridge.getMapValue(chapter, "chapter_slug", 0);
    final chapterId = MBridge.getMapValue(chapter, "id", 0);
    final createdAt = MBridge.getMapValue(chapter, "created_at", 0);
    chapterUrls.add("/series/$currentSlug/$chapterSlug#$chapterId");
    chapterTitles.add(chapterName);
    chapterDates.add(createdAt);
  }
  manga.urls = chapterUrls;
  manga.names = chapterTitles;
  manga.chaptersDateUploads = MBridge.listParse(
      MBridge.listParseDateTime(
          chapterDates, manga.dateFormat, manga.dateFormatLocale),
      0);
  return manga;
}

getChapterUrl(MangaModel manga) async {
  String chapterId = MBridge.listParse(manga.link.split('#'), 2)[0];

  final headers = getHeader(manga.baseUrl);
  final url = "${manga.apiUrl}/series/chapter/$chapterId";
  final data = {"url": url, "headers": headers};
  final res = await MBridge.http(json.encode(data), 0);
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

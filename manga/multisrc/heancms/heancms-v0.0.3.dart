import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

searchManga(MManga manga) async {
  final headers = getHeader(manga.baseUrl);
  MHttpResponse response = MHttpResponse();
  if (!useNewQueryEndpoint(manga.source)) {
    final url = "${manga.apiUrl}/series/search";
    final body = {"term": manga.query};
    final data = {"url": url, "headers": headers, "body": body};
    response = await MBridge.http('POST', json.encode(data));
  } else {
    final newEndpointUrl =
        "${manga.apiUrl}/query/?page=${manga.page}&query_string=${manga.query}&series_status=All&order=desc&orderBy=total_views&perPage=12&tags_ids=[]&series_type=Comic";

    final newEndpointData = {"url": newEndpointUrl, "headers": headers};
    response = await MBridge.http('GET', json.encode(newEndpointData));
  }
  if (response.hasError) {
    return response;
  }
  return mMangaRes(response, manga);
}

getPopularManga(MManga manga) async {
  final headers = getHeader(manga.baseUrl);
  MHttpResponse response = MHttpResponse();
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
    response = await MBridge.http('POST', json.encode(data));
  } else {
    final newEndpointUrl =
        "${manga.apiUrl}/query/?page=${manga.page}&query_string=&series_status=All&order=desc&orderBy=total_views&perPage=12&tags_ids=[]&series_type=Comic";

    final newEndpointData = {
      "url": newEndpointUrl,
      "headers": headers,
      "sourceId": manga.sourceId
    };
    response = await MBridge.http('GET', json.encode(newEndpointData));
  }
  return mMangaRes(response, manga);
}

getLatestUpdatesManga(MManga manga) async {
  final headers = getHeader(manga.baseUrl);
  MHttpResponse response = MHttpResponse();
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
    response = await MBridge.http('POST', json.encode(data));
  } else {
    final newEndpointUrl =
        "${manga.apiUrl}/query/?page=${manga.page}&query_string=&series_status=All&order=desc&orderBy=latest&perPage=12&tags_ids=[]&series_type=Comic";

    final newEndpointData = {"url": newEndpointUrl, "headers": headers};
    response = await MBridge.http('GET', json.encode(newEndpointData));
  }

  return mMangaRes(response, manga);
}

getMangaDetail(MManga manga) async {
  String currentSlug = MBridge.substringAfterLast(manga.link, "/");
  final headers = getHeader(manga.baseUrl);
  final url = "${manga.apiUrl}/series/$currentSlug";
  final data = {"url": url, "headers": headers};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
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

getChapterPages(MManga manga) async {
  MHttpResponse response = MHttpResponse();
  final headers = getHeader(manga.baseUrl);

  String res = "".toString();
  if (!useslugStrategy(manga.source)) {
    String chapterId = MBridge.substringAfter(manga.link, '#');
    final url = "${manga.apiUrl}/series/chapter/$chapterId";
    final data = {"url": url, "headers": headers};
    response = await MBridge.http('GET', json.encode(data));
    res = response.body;
  } else {
    final url = "${manga.baseUrl}${manga.link}";
    final data = {"url": url, "headers": headers};
    response = await MBridge.http('GET', json.encode(data));
    if (response.hasError) {
      return response;
    }
    res = response.body;
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
  if (response.hasError) {
    return response;
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

MManga mMangaRes(MHttpResponse response, MManga manga) {
  String res = response.body;
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
      final seriesSlug = a["series_slug"];
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
      final seriesSlug = a["series_slug"];
      urls.add("/series/$seriesSlug");
    }
    manga.hasNextPage = false;
  }

  manga.urls = urls;
  manga.images = images;
  manga.names = names;
  return manga;
}

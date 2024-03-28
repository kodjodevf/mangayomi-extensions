import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class HeanCms extends MProvider {
  HeanCms({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final headers = getHeader(source.baseUrl);
    String res = "";
    if (!useNewQueryEndpoint(source.name)) {
      final url = "${source.apiUrl}/series/querysearch";

      final body = {
        "page": page,
        "order": "desc",
        "order_by": "total_views",
        "series_status": "Ongoing",
        "series_type": "Comic"
      };
      res = (await client.post(Uri.parse(url), headers: headers, body: body))
          .body;
    } else {
      final newEndpointUrl =
          "${source.apiUrl}/query/?page=$page&query_string=&series_status=All&order=desc&orderBy=total_views&perPage=12&tags_ids=[]&series_type=Comic";
      res =
          (await client.get(Uri.parse(newEndpointUrl), headers: headers)).body;
    }
    return mMangaRes(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final headers = getHeader(source.baseUrl);
    String res = "";
    if (!useNewQueryEndpoint(source.name)) {
      final url = "${source.apiUrl}/series/querysearch";
      final body = {
        "page": page,
        "order": "desc",
        "order_by": "latest",
        "series_status": "Ongoing",
        "series_type": "Comic"
      };
      res = (await client.post(Uri.parse(url), headers: headers, body: body))
          .body;
    } else {
      final newEndpointUrl =
          "${source.apiUrl}/query/?page=$page&query_string=&series_status=All&order=desc&orderBy=latest&perPage=12&tags_ids=[]&series_type=Comic";
      res =
          (await client.get(Uri.parse(newEndpointUrl), headers: headers)).body;
    }
    return mMangaRes(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final headers = getHeader(source.baseUrl);
    String res = "";
    if (!useNewQueryEndpoint(source.source)) {
      final url = "${source.apiUrl}/series/search";
      final body = {"term": query};
      res = (await client.post(Uri.parse(url), headers: headers, body: body))
          .body;
    } else {
      final newEndpointUrl =
          "${source.apiUrl}/query/?page=$page&query_string=$query&series_status=All&order=desc&orderBy=total_views&perPage=12&tags_ids=[]&series_type=Comic";
      res =
          (await client.get(Uri.parse(newEndpointUrl), headers: headers)).body;
    }
    return mMangaRes(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    MManga manga = MManga();
    String currentSlug = substringAfterLast(url, "/");
    final headers = getHeader(source.baseUrl);
    final res = (await client.get(
            Uri.parse("${source.apiUrl}/series/$currentSlug"),
            headers: headers))
        .body;
    manga.author = getMapValue(res, "author");
    manga.description = getMapValue(res, "description");
    manga.genre = jsonPathToString(res, r"$.tags[*].name", "._").split("._");
    List<String> chapterTitles = [];
    List<String> chapterUrls = [];
    List<String> chapterDates = [];

    if (!useNewQueryEndpoint(source.name)) {
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
    final dateUploads =
        parseDates(chapterDates, source.dateFormat, source.dateFormatLocale);
    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chapterTitles.length; i++) {
      MChapter chapter = MChapter();
      chapter.name = chapterTitles[i];
      chapter.url = chapterUrls[i];
      chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    if (!useNewQueryEndpoint(source.name)) {
      chaptersList = chaptersList.reversed.toList();
    }

    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final headers = getHeader(source.baseUrl);

    String res = "".toString();
    if (!useslugStrategy(source.name)) {
      String chapterId = substringAfter(url, '#');
      res = (await client.get(
              Uri.parse("${source.apiUrl}/series/chapter/$chapterId"),
              headers: headers))
          .body;
    } else {
      res = (await client.get(Uri.parse("${source.baseUrl}$url"),
              headers: headers))
          .body;

      List<String> pageUrls = [];
      var imagesRes = parseHtml(res)
          .selectFirst("div.min-h-screen > div.container > p.items-center")
          .innerHtml;

      pageUrls = xpath(imagesRes, '//img/@src');

      pageUrls.addAll(xpath(imagesRes, '//img/@data-src'));

      return pageUrls.where((e) => e.isNotEmpty).toList();
    }

    final pages = jsonPathToList(res, r"$.content.images[*]", 0);
    List<String> pageUrls = [];
    for (var u in pages) {
      final url = u.replaceAll('"', "");
      if (url.startsWith("http")) {
        pageUrls.add(url);
      } else {
        pageUrls.add("${source.apiUrl}/$url");
      }
    }
    return pageUrls;
  }

  MPages mMangaRes(String res) {
    bool hasNextPage = true;
    List<MManga> mangaList = [];
    List<String> names = [];
    List<String> urls = [];
    List<String> images = [];
    if (res.startsWith("{")) {
      for (var a in json.decode(res)["data"]) {
        String thumbnail = a["thumbnail"];
        if (thumbnail.startsWith("https://")) {
          images.add(thumbnail);
        } else {
          images.add("${source.apiUrl}/cover/$thumbnail");
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
          images.add("${source.apiUrl}/cover/$thumbnail");
        }
        names.add(a["title"]);
        final seriesSlug = a["series_slug"];
        urls.add("/series/$seriesSlug");
      }
      hasNextPage = false;
    }

    for (var i = 0; i < names.length; i++) {
      MManga manga = MManga();
      manga.name = names[i];
      manga.imageUrl = images[i];
      manga.link = urls[i];
      mangaList.add(manga);
    }
    return MPages(mangaList, hasNextPage);
  }

  bool useNewQueryEndpoint(String sourceName) {
    List<String> sources = [
      "YugenMangas",
      "Perf Scan",
      "Reaper Scans",
      "OmegaScans"
    ];
    return sources.contains(sourceName);
  }

  bool useslugStrategy(String sourceName) {
    List<String> sources = [
      "YugenMangas",
      "Reaper Scans",
      "Perf Scan",
      "OmegaScans"
    ];
    return sources.contains(sourceName);
  }
}

Map<String, String> getHeader(String url) {
  final headers = {'Origin': url, 'Referer': '$url/'};
  return headers;
}

HeanCms main(MSource source) {
  return HeanCms(source: source);
}

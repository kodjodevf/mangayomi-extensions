import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaBuddy extends MProvider {
  MangaBuddy({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  bool get supportsLatest => true;

  @override
  Map<String, String> get headers => {};
  
  @override
  MPages mangaFromElements(List<MElement> elements, bool hasNextPage) {
    List<MManga> mangaList = [];

    for (var i = 0; i < elements.length; i++) {
      final title = elements[i].selectFirst("div.meta > div.title > h3 > a");
      final imageElement = elements[i].selectFirst("div.thumb > a > img");
      final image = imageElement?.attr("data-src") ??
             imageElement?.getSrc ??
             "";

      MManga manga = MManga();
      manga.name = title.text ?? title.attr("title");
      manga.imageUrl = image;
      manga.link = title.attr("href").contains(source.baseUrl) ? title.attr("href") : "${source.baseUrl}${title.attr("href")}";
      mangaList.add(manga);
    }


    return MPages(mangaList, hasNextPage);
  }
  
  @override
  Future<MPages> getPopular(int page) async {
      final res = await client.get(Uri.parse("${source.baseUrl}/popular?page=$page"));
      final doc = parseHtml(res.body);
      
      final nextElement = doc.selectFirst("a.page-link[title='Next']");
      bool hasNext = nextElement.text != null;
      
      return mangaFromElements(doc.select("div.list.manga-list > div.book-item > div.book-detailed-item"), true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
      final res = await client.get(Uri.parse("${source.baseUrl}/latest?page=$page"));
      final doc = parseHtml(res.body);
      
      final nextElement = doc.selectFirst("a.page-link[title='Next']");
      bool hasNext = nextElement.text != null;
      
      return mangaFromElements(doc.select("div.list.manga-list > div.book-item > div.book-detailed-item"), true);
  }

  @override
  Future<MPages> search(String initialQuery, int page, FilterList filterList) async {
    final filters = filterList.filters;
    final filterString = "";
    final query = initialQuery;
    for (var filter in filters) {
    
      if (filter.type == "SearchFilter"){
        query = filter.state.toString();
      } else if (filter.type == "GenresFilter") {
        for (var genre in filter.state) {
          if (genre.state == true) {
            filterString += ("&genre[]=${genre.value.toString()}");
          } 
        }
      } else if (filter.type == "StatusFilter") {
        filterString += ("&status=${filter.values[filter.state].value.toString()}");
      } else if (filter.type == "OrderFilter") {
        filterString += ("&sort=${filter.values[filter.state].value.toString()}");
      }
    }


    final res = await client.get(Uri.parse("${source.baseUrl}/search?$filterString&q=$query&page=$page"));
    final doc = parseHtml(res.body);

    return mangaFromElements(doc.select("div.list.manga-list > div.book-item > div.book-detailed-item"), true);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [{
      "Ongoing": 0,
      "Completed": 1,
    }];
    final res = await client.get(Uri.parse(url));
    final doc = parseHtml(res.body);
    
    MManga manga = MManga();
    
    final chapterIdElement = doc.selectFirst("div.layout > script");
    final idRegex = RegExp(r"var\s+bookId\s*=\s*(\d+);");

    final imageElement = doc.selectFirst("div.book-info div.img-cover > img");  
    final statusElement = doc.selectFirst("div.book-info div.detail > div.meta.box.mt-1.p-10 > p > a[href^='/status/'] > span");
    final authorElements = doc.select("div.book-info div.detail > div.meta.box.mt-1.p-10 > p > a[href^='/authors/'] > span");
    final genreList = doc.select("div.book-info div.detail > div.meta.box.mt-1.p-10 > p > a[href^='/genres/']");
    final descriptionElement = doc.selectFirst("div.section-body.summary > p.content");

    final chapterIdMatch = idRegex.firstMatch(chapterIdElement?.text);
    final chapterId = chapterIdMatch != null ? chapterIdMatch.group(1) ?? "" : "";

    final image = imageElement?.attr("data-src") ?? imageElement?.getSrc ?? "";
    final status = statusElement.text ?? "Ongoing";
    final author = authorElements.isNotEmpty ? authorElements.map((e) => e.text).join(" | ") : "unknown";
    final genres = genreList.map((e) => (e.text as String).replaceAll(",", "").trim()).toList();

    final description = descriptionElement?.text ?? "";

    manga.author = author;
    manga.description = description;
    manga.imageUrl = image;
    manga.genre = genres;

    manga.chapters = await getChapters(chapterId);
   	manga.status = parseStatus(status, statusList);
    return manga;
  }
  
  @override
  Future<List<MChapter>> getChapters(String chapterId) async {
    List<MChapter> chapters = [];

    final res = await client.get(Uri.parse("${source.baseUrl}/api/manga/$chapterId/chapters?source=detail"));
    MDocument doc = parseHtml(res.body);

    MElement chapterList = doc.selectFirst("ul.chapter-list");

    for (MElement chapterElement in chapterList.select("li")) {
      var chapter = MChapter();

      final name = chapterElement.selectFirst("strong.chapter-title")?.text;
      final url = chapterElement.selectFirst("a")?.attr("href");
      final uploadDate = chapterElement.selectFirst("time.chapter-update")?.text;

      chapter.name = name;
      chapter.url = url;
      chapter.dateUpload = parseDateToUnix(uploadDate).toString();

      chapters.add(chapter);
    }

    return chapters;
  }

  @override
  int parseDateToUnix(String dateStr) {

    const monthMap = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
      'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };


    final parts = dateStr.split(' ');
    if (parts.length != 3) return DateTime.now().millisecondsSinceEpoch;

    final monthStr = parts[0];
    final dayStr = parts[1].replaceAll(',', '');
    final yearStr = parts[2];

    final month = monthMap[monthStr] ?? 1;
    final day = int.tryParse(dayStr) ?? 1;
    final year = int.tryParse(yearStr) ?? DateTime.now().year;

    final dt = DateTime(year, month, day);
    return dt.millisecondsSinceEpoch;
  }

  @override
  Future<List<Map<String, dynamic>>> getPageList(String url) async {
    List<Map<String, dynamic>> images = [];

    final res = await client.get(Uri.parse("${source.baseUrl}$url"));
    final doc = parseHtml(res.body);

    final imageScript = doc.select("div#viewer-page.main-container.viewer > script");

    final rawImageText = imageScript[imageScript.length-1]?.text ?? "";

    final imageList = rawImageText.replaceAll("var chapImages =", "").replaceAll("'", "").trim().split(",");

    for (final image in imageList) {
      images.add({
        "url": image.trim(),
        "headers": {
          "Referer": source.baseUrl,
        }
      });
    }

    return images;
  }



  @override
  List<dynamic> getFilterList() {
    return [
      TextFilter("SearchFilter", "Search..."),
      GroupFilter("GenresFilter", "Genres A-M", [
        CheckBoxFilter("Action", "action"),
        CheckBoxFilter("Adaptation", "adaptation"),
        CheckBoxFilter("Adult", "adult"),
        CheckBoxFilter("Adventure", "adventure"),
        CheckBoxFilter("Animal", "animal"),
        CheckBoxFilter("Anthology", "anthology"),
        CheckBoxFilter("Cartoon", "cartoon"),
        CheckBoxFilter("Comedy", "comedy"),
        CheckBoxFilter("Comic", "comic"),
        CheckBoxFilter("Cooking", "cooking"),
        CheckBoxFilter("Demons", "demons"),
        CheckBoxFilter("Doujinshi", "doujinshi"),
        CheckBoxFilter("Drama", "drama"),
        CheckBoxFilter("Ecchi", "ecchi"),
        CheckBoxFilter("Fantasy", "fantasy"),
        CheckBoxFilter("Full Color", "full-color"),
        CheckBoxFilter("Game", "game"),
        CheckBoxFilter("Gender bender", "gender-bender"),
        CheckBoxFilter("Ghosts", "ghosts"),
        CheckBoxFilter("Harem", "harem"),
        CheckBoxFilter("Historical", "historical"),
        CheckBoxFilter("Horror", "horror"),
        CheckBoxFilter("Isekai", "isekai"),
        CheckBoxFilter("Josei", "josei"),
        CheckBoxFilter("Long strip", "long-strip"),
        CheckBoxFilter("Mafia", "mafia"),
        CheckBoxFilter("Magic", "magic"),
        CheckBoxFilter("Manga", "manga"),
        CheckBoxFilter("Manhua", "manhua"),
        CheckBoxFilter("Manhwa", "manhwa"),
        CheckBoxFilter("Martial arts", "martial-arts"),
        CheckBoxFilter("Mature", "mature"),
        CheckBoxFilter("Mecha", "mecha"),
        CheckBoxFilter("Medical", "medical"),
        CheckBoxFilter("Military", "military"),
        CheckBoxFilter("Monster", "monster"),
        CheckBoxFilter("Monster girls", "monster-girls"),
        CheckBoxFilter("Monsters", "monsters"),
        CheckBoxFilter("Music", "music"),
        CheckBoxFilter("Mystery", "mystery"),
      ]),
      GroupFilter("GenresFilter", "Genres N-Z", [
        CheckBoxFilter("Office", "office"),
        CheckBoxFilter("Office workers", "office-workers"),
        CheckBoxFilter("One shot", "one-shot"),
        CheckBoxFilter("Police", "police"),
        CheckBoxFilter("Psychological", "psychological"),
        CheckBoxFilter("Reincarnation", "reincarnation"),
        CheckBoxFilter("Romance", "romance"),
        CheckBoxFilter("School life", "school-life"),
        CheckBoxFilter("Sci fi", "sci-fi"),
        CheckBoxFilter("Science fiction", "science-fiction"),
        CheckBoxFilter("Seinen", "seinen"),
        CheckBoxFilter("Shoujo", "shoujo"),
        CheckBoxFilter("Shoujo ai", "shoujo-ai"),
        CheckBoxFilter("Shounen", "shounen"),
        CheckBoxFilter("Shounen ai", "shounen-ai"),
        CheckBoxFilter("Slice of life", "slice-of-life"),
        CheckBoxFilter("Smut", "smut"),
        CheckBoxFilter("Soft Yaoi", "soft-yaoi"),
        CheckBoxFilter("Sports", "sports"),
        CheckBoxFilter("Super Power", "super-power"),
        CheckBoxFilter("Superhero", "superhero"),
        CheckBoxFilter("Supernatural", "supernatural"),
        CheckBoxFilter("Thriller", "thriller"),
        CheckBoxFilter("Time travel", "time-travel"),
        CheckBoxFilter("Tragedy", "tragedy"),
        CheckBoxFilter("Vampire", "vampire"),
        CheckBoxFilter("Vampires", "vampires"),
        CheckBoxFilter("Video games", "video-games"),
        CheckBoxFilter("Villainess", "villainess"),
        CheckBoxFilter("Web comic", "web-comic"),
        CheckBoxFilter("Webtoons", "webtoons"),
        CheckBoxFilter("Yaoi", "yaoi"),
        CheckBoxFilter("Yuri", "yuri"),
        CheckBoxFilter("Zombies", "zombies"),
      ]),
      SeparatorFilter(),
      SelectFilter("StatusFilter", "Status", 0, [
        SelectFilterOption("All (Default)", "all"),
        SelectFilterOption("Ongoing", "ongoing"),
        SelectFilterOption("Completed", "completed"),
      ]),
      SelectFilter("OrderFilter", "Order By", 0, [
        SelectFilterOption("Views (Default)", "views"),
        SelectFilterOption("Latest Updated", "updated_at"),
        SelectFilterOption("Creation Date", "created_at"),
        SelectFilterOption("Name A-Z", "name"),
        SelectFilterOption("Rating", "rating"),
      ]),
    ];
  }
}

MangaBuddy main(MSource source) {
  return MangaBuddy(source:source);
}

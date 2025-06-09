import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class MangaPark extends MProvider {
  MangaPark({required this.source});

  MSource source;

  final Client client = Client(source);
  
  @override
  Future<MPages> getMangaItems(int page, final method) async {
    List<MPages> mangaList = [];


    final res = await client.post(
      Uri.parse("${source.apiUrl}"), 
      headers: {
        "Accept": "*/*",
        "accept-language": "en-US,en;q=0.9,de;q=0.8,ja;q=0.7,es;q=0.6,nl;q=0.5",
        "content-type": "application/json",
        "referer": "https://mangapark.io/",
        "cookie": "nsfw=${preferenceNsfwContent()}; imgser=${preferenceImgServer()}; wd=2504x735"
      },
      body: jsonEncode({
        "query": """
          query get_latestReleases(\$select: LatestReleases_Select) {
            get_latestReleases(select: \$select) {
              paging {
                total pages page init size skip limit prev next
              }
              items {
                id
                data {
                  id dbStatus name origLang tranLang sfw_result
                  urlPath urlCover600 urlCoverOri
                  is_hot is_new follows
                  last_chapterNodes(amount: 1) {
                    id
                    data {
                      id dateCreate dbStatus isFinal dname urlPath is_new
                    }
                  }
                }
                sser_follow
              }
            }
          }
        """,
        "variables": {
          "select": {
            "where": method,
            "init": 24,
            "size": 24,
            "page": page
          }
        }
    }));

    final json = jsonDecode(res.body);
    final data = json["data"]["get_latestReleases"];
    final items = data["items"];
    final bool isNextPage = data["paging"]["pages"] > page;

    for (var item in items) {
      final mangaData = item["data"];
      MManga manga = MManga();
      manga.name = mangaData["name"];
      manga.imageUrl = "${source.baseUrl}${mangaData["urlCover600"]}";
      manga.link = "${source.baseUrl}${mangaData["urlPath"]}";
      mangaList.add(manga);
    }

    return MPages(mangaList, isNextPage);
  }

  @override
  Future<MPages> getPopular(int page) async {
    return getMangaItems(page, "popular");
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    return getMangaItems(page, "release");
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    List<MManga> mangaList = [];
    final filters = filterList.filters;
    String url = "";
    String genres = "&genres=";
    String translFrom = "&orig=";
    String translTo = "&lang=";


    for (var filter in filters) {
      if (filter.type == "SearchFilter") {
        if (filter.state.toString() != "") {
          query = filter.state.toString();
        }
      } else if (filter.type == "GenresFilter") {
        for (int i = 0; i < filter.state.length; i++) {
          if (filter.state[i].state.toString() == "2") {
            genres += "|${filter.state[i].value.toString()},";
          } else if (filter.state[i].state.toString() == "1") {
            genres += "${filter.state[i].value.toString()},";
          }
        }
      } else if (filter.type == "TranslatedFromFilter") {
        for (int i = 0; i < filter.state.length; i++) {
          if (filter.state[i].state) {
            translFrom += "${filter.state[i].value.toString()},";
          }
        }
      } else if (filter.type == "TranslatedToFilter") {
          for (int i = 0; i < filter.state.length; i++) {
            if (filter.state[i].state) {
              translTo += "${filter.state[i].value.toString()},";
            }
          }
      } else if (filter.type == "OrigWorkFilter") {
        url += "&status=${filter.values[filter.state].value.toString()}";
      } else if (filter.type == "MparkUplFilter") {
        url += "&upload=${filter.values[filter.state].value.toString()}";
      } else if (filter.type == "ChapCountFilter") {
        url += "&chapters=${filter.values[filter.state].value.toString()}";
      } else if (filter.type == "SortFilter") {
        url += "&sortby=${filter.values[filter.state].value.toString()}";
      }
    }
    url += genres + translFrom + translTo;

    final res = await client.get(Uri.parse("${source.baseUrl}/search?word=${Uri.encodeComponent(query.trim())}&page=$page$url"),
    headers: {
      "Accept": "*/*",
      "accept-language": "en-US,en;q=0.9,de;q=0.8,ja;q=0.7,es;q=0.6,nl;q=0.5",
      "referer": "https://mangapark.io/",
      "cookie": "nsfw=${preferenceNsfwContent()}; imgser=${preferenceImgServer()}; wd=2504x735"
    });
    final doc = parseHtml(res.body);

    final elements = doc.select("div.grid.gap-5.grid-cols-1.border-t.border-t-base-200.pt-5 > div");
    if (elements.length == 0) {
      return MPages(mangaList, false);
    }
    for (final element in elements) {
      final nameElement = element.selectFirst("h3 > a > span");
      final imageElement = element.selectFirst("div > div > a > img");
      final urlElement = element.selectFirst("div > div > a");
      final name = nameElement.text ?? "No Name";
      final image = imageElement.attr("src").contains(source.baseUrl) ? imageElement.attr("src") : "${source.baseUrl}${imageElement.attr("src")}";
      final url = urlElement.attr("href").contains(source.baseUrl) ? urlElement.attr("href") : "${source.baseUrl}${urlElement.attr("href")}";

      MManga manga = MManga();

      manga.name = name;
      manga.imageUrl = image;
      manga.link = url;

      mangaList.add(manga);
    }
    final lastPageNumber = int.tryParse(doc.selectFirst("div.flex.items-center.flex-wrap.space-x-1.my-10.justify-center > a:last-child")?.text.trim());
    bool hasNextPage = (lastPageNumber > page);

    return MPages(mangaList, hasNextPage);
  }

  @override
  Future<MManga> getDetail(String url) async {
  final statusList = [{
    "Pending": 0,
    "Ongoing": 0,
    "Completed": 1,
    "Hiatus": 2,
    "Cancelled": 3,
    "Unknown": 5,
  }];

  final res = await client.get(Uri.parse("$url"), 
  headers: {
    "Accept": "*/*",
    "accept-language": "en-US,en;q=0.9,de;q=0.8,ja;q=0.7,es;q=0.6,nl;q=0.5",
    "referer": "https://mangapark.io/",
    "cookie": "nsfw=${preferenceNsfwContent()}; imgser=${preferenceImgServer()}; wd=2504x735"
  });
  final doc = parseHtml(res.body);

  final statusElement = doc.selectFirst("div:nth-child(2) > div:nth-child(4) > span.font-bold.uppercase");
  final authorElements = doc.select("div.flex.flex-col > div.flex > div.grow.pl-3.space-y-2 > div.mt-2.text-sm > a");
  final genreList = doc.select("div.flex.items-center.flex-wrap > span > span:nth-child(1)");
  final descriptionElement = doc.selectFirst("div.limit-html-p");

  final author = authorElements.isNotEmpty ? authorElements.map((e) => e.text).join(" | ") : "Anonymous";
  final genres = genreList.map((e) => (e.text as String).replaceAll(",", "").trim()).toList() ?? [];

  final status = statusElement?.text ?? "Unknown";
  final description = descriptionElement.text ?? "no Description...";
  final chapters = getChapters(doc);


  MManga manga = MManga();

  manga.genre = genres;
  manga.author = author;
  manga.chapters = chapters;
  manga.description = description;
  manga.status = parseStatus(status, statusList);

  return manga;
  }

  List<MChapter> getChapters(MDocument doc) {
    List<MChapter> chapters = [];
       if (doc.selectFirst("div.group.flex.flex-col").outerHtml == null) {
        throw("Something went wrong. if this is a age-restricted manga, try to turn of the NSFW filter in the settings, then reload the manga.");
      }
      
      MElement chapterList = doc.selectFirst("div.group.flex.flex-col");

      for (MElement chapterElement in chapterList.select("div.justify-between")) {
        var chapter = MChapter();

        final chapterName = chapterElement.selectFirst("div > a");
        final scanlatorElement = chapterElement.selectFirst("a.link-hover > span");      
        
        final name = chapterName.text ?? "No Name Given";
        final url = chapterName.attr("href").contains(source.baseUrl) ? chapterName.attr("href") : "${source.baseUrl}${chapterName.attr("href")}";
        final uploadDate = chapterElement.selectFirst("time")?.attr("data-time");
        final scanlator = scanlatorElement.text ?? "Anonymous";

        chapter.name = name;
        chapter.url = url;
        chapter.dateUpload = uploadDate;
        chapter.scanlator = scanlator;
        chapters.add(chapter);
      }
    return chapters;
  }

  @override
  Future<List<Map<String, dynamic>>> getPageList(String url) async{
    List<Map<String, dynamic>> images = [];
    final res = await client.get(Uri.parse(url), 
    headers: {
      "cookie": "${preferenceImgServer() == "" ? "" : "imgser=${preferenceImgServer()};"} nsfw=${preferenceNsfwContent()}; wd=2504x1362",
      "referer": url,
    });
    final doc = parseHtml(res.body);

    final imageObjects = doc.select('div[data-name="image-item"] img');

    for (final imageObject in imageObjects) {
      final imageUrl = imageObject.attr("src");
      images.add({
        "url": imageUrl.trim(),
        "headers": {
          "referer": url,
        }
      });
    }
    return images;
  }

  @override
  List<dynamic> getFilterList() {
    return [
      TextFilter("SearchFilter", "Search..."),
      SelectFilter("SortFilter", "Order By", 0, [
        SelectFilterOption("Rating Score", "field_score"),
        SelectFilterOption("Most Follows", "field_follow"),
        SelectFilterOption("Most Reviews", "field_review"),
        SelectFilterOption("Most Comments", "field_comment"),
        SelectFilterOption("Most Chapters", "field_chapter"),
        SelectFilterOption("New Chapters", "field_update"),
        SelectFilterOption("Recently Created", "field_create"),
        SelectFilterOption("Name A-Z", "field_name"),
        SelectFilterOption("Most Views: Last 60 Minutes", "views_h001"),
        SelectFilterOption("Most Views: Last 12 Hours", "views_h012"),
        SelectFilterOption("Most Views: Last 24 Hours", "views_h024"),
        SelectFilterOption("Most Views: Last 7 Days", "views_d007"),
        SelectFilterOption("Most Views: Last 30 Days", "views_d030"),
        SelectFilterOption("Most Views: Last 90 Days", "views_d090"),
        SelectFilterOption("Most Views: Last 180 Days", "views_d180"),
        SelectFilterOption("Most Views: Last 360 Days", "views_d360"),
        SelectFilterOption("Most Views: All Time", "views_d000"),
        SelectFilterOption("Emotion: Awesome", "emotion_e1"),
        SelectFilterOption("Emotion: Funny", "emotion_e2"),
        SelectFilterOption("Emotion: Love", "emotion_e3"),
        SelectFilterOption("Emotion: Hot", "emotion_e4"),
        SelectFilterOption("Emotion: Sweet", "emotion_e5"),
        SelectFilterOption("Emotion: Cool", "emotion_e6"),
        SelectFilterOption("Emotion: Scared", "emotion_e7"),
        SelectFilterOption("Emotion: Angry", "emotion_e8"),
        SelectFilterOption("Emotion: Sad", "emotion_e9"),
      ]),
      SeparatorFilter(),
      GroupFilter("GenresFilter", "Manga Style", [
        TriStateFilter("Artbook", "artbook"),
        TriStateFilter("Cartoon", "cartoon"),
        TriStateFilter("Comic", "comic"),
        TriStateFilter("Doujinshi", "doujinshi"),
        TriStateFilter("Imageset", "imageset"),
        TriStateFilter("Manga", "manga"),
        TriStateFilter("Manhua", "manhua"),
        TriStateFilter("Manhwa", "manhwa"),
        TriStateFilter("Webtoon", "webtoon"),
        TriStateFilter("Western", "western"),
        TriStateFilter("Oneshot", "oneshot"),
        TriStateFilter("4-Koma", "_4_koma"),
        TriStateFilter("Art-by-AI", "ai_art"),
        TriStateFilter("Story-by-AI", "ai_story"),
      ]),
      SeparatorFilter(),
      GroupFilter("GenresFilter", "General Filters", [
        TriStateFilter("Shoujo(G)", "shoujo"),
        TriStateFilter("Shounen(B)", "shounen"),
        TriStateFilter("Josei(W)", "josei"),
        TriStateFilter("Seinen(M)", "seinen"),
        TriStateFilter("Yuri(GL)", "yuri"),
        TriStateFilter("Yaoi(BL)", "yaoi"),
        TriStateFilter("Futa(⚤)", "futa"),
        TriStateFilter("Bara(ML)", "bara"),
        TriStateFilter("Kodomo(Kid)", "kodomo"),
        TriStateFilter("Silver & Golden", "old_people"),
        TriStateFilter("Shoujo ai", "shoujo_ai"),
        TriStateFilter("Shounen ai", "shounen_ai"),
        TriStateFilter("Non-human", "non_human"),
      ]),
      GroupFilter("GenresFilter", "Explicit Filters", [
        TriStateFilter("Gore", "gore"),
        TriStateFilter("Bloody", "bloody"),
        TriStateFilter("Violence", "violence"),
        TriStateFilter("Ecchi", "ecchi"),
        TriStateFilter("Adult", "adult"),
        TriStateFilter("Mature", "mature"),
        TriStateFilter("Smut", "smut"),
        TriStateFilter("Hentai", "hentai"),
      ]),
      GroupFilter("GenresFilter", "Detailed Filters (A-M)", [
        TriStateFilter("Action", "action"),
        TriStateFilter("Adaptation", "adaptation"),
        TriStateFilter("Adventure", "adventure"),
        TriStateFilter("Age Gap", "age_gap"),
        TriStateFilter("Aliens", "aliens"),
        TriStateFilter("Animals", "animals"),
        TriStateFilter("Anthology", "anthology"),
        TriStateFilter("Beasts", "beasts"),
        TriStateFilter("Bodyswap", "bodyswap"),
        TriStateFilter("Blackmail", "blackmail"),
        TriStateFilter("Brocon/Siscon", "brocon_siscon"),
        TriStateFilter("Cars", "cars"),
        TriStateFilter("Cheating/Infidelity", "cheating_infidelity"),
        TriStateFilter("Childhood Friends", "childhood_friends"),
        TriStateFilter("College life", "college_life"),
        TriStateFilter("Comedy", "comedy"),
        TriStateFilter("Contest winning", "contest_winning"),
        TriStateFilter("Cooking", "cooking"),
        TriStateFilter("Crime", "crime"),
        TriStateFilter("Crossdressing", "crossdressing"),
        TriStateFilter("Cultivation", "cultivation"),
        TriStateFilter("Death Game", "death_game"),
        TriStateFilter("DegenerateMC", "degeneratemc"),
        TriStateFilter("Delinquents", "delinquents"),
        TriStateFilter("Dementia", "dementia"),
        TriStateFilter("Demons", "demons"),
        TriStateFilter("Drama", "drama"),
        TriStateFilter("Fantasy", "fantasy"),
        TriStateFilter("Fan-Colored", "fan_colored"),
        TriStateFilter("Fetish", "fetish"),
        TriStateFilter("Full Color", "full_color"),
        TriStateFilter("Game", "game"),
        TriStateFilter("Gender Bender", "gender_bender"),
        TriStateFilter("Genderswap", "genderswap"),
        TriStateFilter("Ghosts", "ghosts"),
        TriStateFilter("Gyaru", "gyaru"),
        TriStateFilter("Harem", "harem"),
        TriStateFilter("Harlequin", "harlequin"),
        TriStateFilter("Historical", "historical"),
        TriStateFilter("Horror", "horror"),
        TriStateFilter("Incest", "incest"),
        TriStateFilter("Isekai", "isekai"),
        TriStateFilter("Kids", "kids"),
        TriStateFilter("Loli", "loli"),
        TriStateFilter("Magic", "magic"),
        TriStateFilter("Magical Girls", "magical_girls"),
        TriStateFilter("Martial Arts", "martial_arts"),
        TriStateFilter("Master-Servant", "master_servant"),
        TriStateFilter("Mecha", "mecha"),
        TriStateFilter("Medical", "medical"),
        TriStateFilter("Military", "military"),
        TriStateFilter("Monster Girls", "monster_girls"),
        TriStateFilter("Monsters", "monsters"),
        TriStateFilter("Music", "music"),
        TriStateFilter("Mystery", "mystery"),
      ]),
      GroupFilter("GenresFilter", "Detailed Filters (N-Z)", [
        TriStateFilter("Netori", "netori"),
        TriStateFilter("Netorare/NTR", "netorare"),
        TriStateFilter("Ninja", "ninja"),
        TriStateFilter("Office Workers", "office_workers"),
        TriStateFilter("Omegaverse", "omegaverse"),
        TriStateFilter("Parody", "parody"),
        TriStateFilter("Philosophical", "philosophical"),
        TriStateFilter("Police", "police"),
        TriStateFilter("Post-Apocalyptic", "post_apocalyptic"),
        TriStateFilter("Psychological", "psychological"),
        TriStateFilter("Reincarnation", "reincarnation"),
        TriStateFilter("Revenge", "revenge"),
        TriStateFilter("Reverse Harem", "reverse_harem"),
        TriStateFilter("Romance", "romance"),
        TriStateFilter("Samurai", "samurai"),
        TriStateFilter("School Life", "school_life"),
        TriStateFilter("Sci-Fi", "sci_fi"),
        TriStateFilter("Shota", "shota"),
        TriStateFilter("Showbiz", "showbiz"),
        TriStateFilter("Slice of Life", "slice_of_life"),
        TriStateFilter("SM/BDSM", "sm_bdsm"),
        TriStateFilter("Space", "space"),
        TriStateFilter("Sports", "sports"),
        TriStateFilter("Spy", "spy"),
        TriStateFilter("Step Family", "step_family"),
        TriStateFilter("Super Power", "super_power"),
        TriStateFilter("Superhero", "superhero"),
        TriStateFilter("Supernatural", "supernatural"),
        TriStateFilter("Survival", "survival"),
        TriStateFilter("Teacher-Student", "teacher_student"),
        TriStateFilter("Thriller", "thriller"),
        TriStateFilter("Time Travel", "time_travel"),
        TriStateFilter("Traditional Games", "traditional_games"),
        TriStateFilter("Tragedy", "tragedy"),
        TriStateFilter("Vampires", "vampires"),
        TriStateFilter("Video Games", "video_games"),
        TriStateFilter("Villainess", "villainess"),
        TriStateFilter("Virtual Reality", "virtual_reality"),
        TriStateFilter("Wuxia", "wuxia"),
        TriStateFilter("Xianxia", "xianxia"),
        TriStateFilter("Xuanhuan", "xuanhuan"),
        TriStateFilter("Zombies", "zombies"),
      ]),
      SeparatorFilter(),
      GroupFilter("TranslatedFromFilter", "Original Work Language", [
        CheckBoxFilter("Chinese", "zh"),
        CheckBoxFilter("English", "en"),
        CheckBoxFilter("Japanese", "jp"),
        CheckBoxFilter("Korean", "ko"),
      ]),
      GroupFilter("TranslatedToFilter", "Translated Language", [
        CheckBoxFilter("Dutch", "nl"),
        CheckBoxFilter("English", "en"),
        CheckBoxFilter("German", "de"),
        CheckBoxFilter("Japanese", "jp"),
        CheckBoxFilter("Spanish", "es"),
        CheckBoxFilter("Spanish (LA)", "es_419"),
      ]),
      SeparatorFilter(),
      SelectFilter("OrigWorkFilter", "Original Work Status", 0, [
        SelectFilterOption("Any", ""),
        SelectFilterOption("Pending", "pending"),
        SelectFilterOption("Ongoing", "ongoing"),
        SelectFilterOption("Completed", "completed"),
        SelectFilterOption("Hiatus", "hiatus"),
        SelectFilterOption("Cancelled", "cancelled"),
      ]),
      SelectFilter("MparkUplFilter", "MangaPark Upload Status", 0, [
        SelectFilterOption("Any", ""),
        SelectFilterOption("Pending", "pending"),
        SelectFilterOption("Ongoing", "ongoing"),
        SelectFilterOption("Completed", "completed"),
        SelectFilterOption("Hiatus", "hiatus"),
        SelectFilterOption("Cancelled", "cancelled"),
      ]),
      SeparatorFilter(),
      SelectFilter("ChapCountFilter", "Number of Chapters", 0, [
        SelectFilterOption("Any", ""),
        SelectFilterOption("0", "0"),
        SelectFilterOption("1+", "1"),
        SelectFilterOption("10+", "10"),
        SelectFilterOption("20+", "20"),
        SelectFilterOption("30+", "30"),
        SelectFilterOption("40+", "40"),
        SelectFilterOption("50+", "50"),
        SelectFilterOption("60+", "60"),
        SelectFilterOption("70+", "70"),
        SelectFilterOption("80+", "80"),
        SelectFilterOption("90+", "90"),
        SelectFilterOption("100+", "100"),
        SelectFilterOption("200+", "200"),
        SelectFilterOption("300+", "300"),
        SelectFilterOption("299~200", "200-299"),
        SelectFilterOption("199~100", "100-199"),
        SelectFilterOption("99~90", "90-99"),
        SelectFilterOption("89~80", "80-89"),
        SelectFilterOption("79~70", "70-79"),
        SelectFilterOption("69~60", "60-69"),
        SelectFilterOption("59~50", "50-59"),
        SelectFilterOption("49~40", "40-49"),
        SelectFilterOption("39~30", "30-39"),
        SelectFilterOption("29~20", "20-29"),
        SelectFilterOption("19~10", "10-19"),
        SelectFilterOption("9~1", "1-9"),
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
        key: "NsfwFilter",
        title: "Display NSFW content",
        summary: "",
        valueIndex: 0,
        entries: ["False", "True"],
        entryValues: ["0", "2"],
      ),
      ListPreference(
        key: "ImgServer",
        title: "Choose Image Server",
        summary: "",
        valueIndex: 0,
        entries: ["Default", "mpfip.org", "mpizz.org", "mpmok.org", "mpqom.org", "mpqrc.org", "mprnm.org", "mpubn.org", "mpujj.org", "mpvim.org", "mypypl.org"],
        entryValues: ["", "mpfip.org", "mpizz.org", "mpmok.org", "mpqom.org", "mpqrc.org", "mprnm.org", "mpubn.org", "mpujj.org", "mpvim.org", "mypypl.org"],
      ),
    ];
  }

  int preferenceNsfwContent() {
    return getPreferenceValue(source.id, "NsfwFilter");
  } 

  String preferenceImgServer() {
    return getPreferenceValue(source.id, "ImgServer");
  }

}

MangaPark main(MSource source) {
  return MangaPark(source:source);
}

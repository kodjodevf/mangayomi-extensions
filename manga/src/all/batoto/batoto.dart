import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Batoto extends MProvider {
  Batoto({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = await client.get(Uri.parse(
        "${preferenceMirror(source.id)}/browse?${lang(source.lang)}&sort=views_a&page=$page"));
    return mangaElementM(res.body);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = await client.get(Uri.parse(
        "${preferenceMirror(source.id)}/browse?${lang(source.lang)}&sort=update&page=$page"));
    return mangaElementM(res.body);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    String min = "";
    String max = "";
    if (query.isNotEmpty) {
      url = "${preferenceMirror(source.id)}/search?word=$query&page=$page";
      for (var filter in filters) {
        if (filter.type == "LetterFilter") {
          if (filter.state == 1) {
            url += "&mode=letter";
          }
        }
      }
    } else {
      url = "${preferenceMirror(source.id)}/browse";
      for (var filter in filters) {
        if (filter.type == "LangGroupFilter") {
          final langs = (filter.state as List).where((e) => e.state).toList();
          if (langs.isEmpty) {
            url += "${ll(url)}lang=${source.lang}";
          } else {
            url += "${ll(url)}lang=";
            for (var lang in langs) {
              url += "${lang.value},";
            }
            url += "${source.lang}";
          }
        }
        //
        else if (filter.type == "GenreGroupFilter") {
          final included = (filter.state as List)
              .where((e) => e.state == 1 ? true : false)
              .toList();
          final excluded = (filter.state as List)
              .where((e) => e.state == 2 ? true : false)
              .toList();
          if (included.isNotEmpty) {
            url += "${ll(url)}genres=";
            for (var val in included) {
              url += "${val.value},";
            }
          }
          if (excluded.isNotEmpty) {
            url += "|";
            for (var val in excluded) {
              url += "${val.value},";
            }
          }
        } else if (filter.type == "StatusFilter") {
          url += "${ll(url)}release=${filter.values[filter.state].value}";
        } else if (filter.type == "SortFilter") {
          final value = filter.state.ascending ? "az" : "za";
          url +=
              "${ll(url)}sort=${filter.values[filter.state.index].value}.$value";
        } else if (filter.type == "OriginGroupFilter") {
          final origins = (filter.state as List).where((e) => e.state).toList();
          if (origins.isNotEmpty) {
            url += "${ll(url)}origs=";
            for (var orig in origins) {
              url += "${orig.value},";
            }
          }
        } else if (filter.type == "MinChapterTextFilter") {
          min = filter.state;
        } else if (filter.type == "MaxChapterTextFilter") {
          max = filter.state;
        }
      }
    }
    url += "${ll(url)}page=$page";

    if (max.isNotEmpty || min.isNotEmpty) {
      url += "${ll(url)}chapters=$min-$max";
    }

    final res = await client.get(Uri.parse(url));
    return mangaElementM(res.body);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1, "Cancelled": 3, "Hiatus": 2}
    ];

    final res =
        (await client.get(Uri.parse("${preferenceMirror(source.id)}$url")))
            .body;
    MManga manga = MManga();
    final workStatus = xpath(res,
            '//*[@class="attr-item"]/b[contains(text(),"Original work")]/following-sibling::span[1]/text()')
        .first;
    manga.status = parseStatus(workStatus, statusList);

    manga.author = xpath(res,
            '//*[@class="attr-item"]/b[contains(text(),"Authors")]/following-sibling::span[1]/text()')
        .first;
    manga.genre = xpath(res,
            '//*[@class="attr-item"]/b[contains(text(),"Genres")]/following-sibling::span[1]/text()')
        .first
        .split(",");
    manga.description = xpath(res, '//*[@class="limit-html"]/text()').first;

    final chapElements = parseHtml(res).select("div.main div.p-2");

    List<String> times = [];
    List<String> chapsUrls = [];
    List<String> chapsNames = [];
    List<String> scanlators = [];
    for (MElement el in chapElements) {
      final chapHtml = el.selectFirst("a.chapt").outerHtml;
      final element = el.outerHtml;
      final group = xpath(element, '//*[@class="extra"]/a/text()').first;
      final name = xpath(chapHtml, '//a/text()').first;
      final url = xpath(chapHtml, '//a/@href').first;
      final time =
          xpath(element, '//*[@class="extra"]/i[@class="ps-3"]/text()').first;
      times.add(time);
      chapsUrls.add(url);
      scanlators.add(group);
      chapsNames.add(name.replaceAll("\n ", "").replaceAll("  ", ""));
    }
    var dateUploads =
        parseDates(times, source.dateFormat, source.dateFormatLocale);
    List<MChapter>? chaptersList = [];
    for (var i = 0; i < chapsNames.length; i++) {
      MChapter chapter = MChapter();
      chapter.name = chapsNames[i];
      chapter.url = chapsUrls[i];
      chapter.scanlator = scanlators[i];
      chapter.dateUpload = dateUploads[i];
      chaptersList.add(chapter);
    }
    manga.chapters = chaptersList;
    return manga;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final res =
        (await client.get(Uri.parse("${preferenceMirror(source.id)}$url")))
            .body;

    final script = xpath(res,
            '//script[contains(text(), "imgHttps") and contains(text(), "batoWord") and contains(text(), "batoPass")]/text()')
        .first;
    final imgHttpsString =
        substringBefore(substringAfter(script, 'const imgHttps ='), ';');
    var imageUrls = json.decode(imgHttpsString);
    final batoWord =
        substringBefore(substringAfterLast(script, 'const batoWord ='), ';');
    final batoPass =
        substringBefore(substringAfterLast(script, 'const batoPass ='), ';');
    final evaluatedPass = deobfuscateJsPassword(batoPass);
    final imgAccListString =
        decryptAESCryptoJS(batoWord.replaceAll('"', ""), evaluatedPass);
    var imgAccList = json.decode(imgAccListString);
    List<String> pagesUrl = [];
    for (int i = 0; i < imageUrls.length; i++) {
      String imgUrl = imageUrls[i];
      String imgAcc = "";
      if (imgAccList.length >= (i + 1)) {
        imgAcc = "?${imgAccList[i]}";
      }
      pagesUrl.add("$imgUrl$imgAcc");
    }

    return pagesUrl;
  }

  MPages mangaElementM(String res) async {
    final lang = source.lang.replaceAll("-", "_");

    final mangaElements = parseHtml(res).select("div#series-list div.col");

    List<MManga> mangaList = [];
    for (MElement element in mangaElements) {
      if (source.lang == "all" ||
          source.lang == "en" && element.outerHtml.contains('no-flag') ||
          element.outerHtml.contains('data-lang="$lang"')) {
        final itemHtml = element.selectFirst("a.item-cover").outerHtml;

        MManga manga = MManga();
        manga.name = element.selectFirst("a.item-title").text;
        manga.imageUrl =
            parseHtml(itemHtml).selectFirst("img").getSrc.replaceAll(";", "&");
        manga.link = parseHtml(itemHtml).selectFirst("a").getHref;
        mangaList.add(manga);
      }
    }

    return MPages(mangaList, true);
  }

  String lang(String lang) {
    lang = lang.replaceAll("-", "_");
    if (lang == "all") {
      return "";
    }
    return "langs=$lang";
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }

  @override
  List<dynamic> getFilterList() {
    return [
      SelectFilter("LetterFilter", "Letter matching mode (Slow)", 0, [
        SelectFilterOption("Disabled", "disabled"),
        SelectFilterOption("Enabled", "enabled"),
      ]),
      SeparatorFilter(),
      HeaderFilter("NOTE: Ignored if using text search!"),
      SeparatorFilter(),
      SortFilter("SortFilter", "Sort", SortState(5, false), [
        SelectFilterOption("Z-A", "title"),
        SelectFilterOption("Last Updated", "update"),
        SelectFilterOption("Newest Added", "create"),
        SelectFilterOption("Most Views Totally", "views_a"),
        SelectFilterOption("Most Views 365 days", "views_y"),
        SelectFilterOption("Most Views 30 days", "views_m"),
        SelectFilterOption("Most Views 7 days", "views_w"),
        SelectFilterOption("Most Views 24 hours", "views_d"),
        SelectFilterOption("Most Views 60 minutes", "views_h")
      ]),
      SelectFilter("StatusFilter", "Status", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Pending", "pending"),
        SelectFilterOption("Ongoing", "ongoing"),
        SelectFilterOption("Completed", "completed"),
        SelectFilterOption("Hiatus", "hiatus"),
        SelectFilterOption("Cancelled", "cancelled"),
      ]),
      GroupFilter("GenreGroupFilter", "Genre", [
        {
          "type": "TriState",
          "filter": {"name": "Artbook", "value": "artbook"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Cartoon", "value": "cartoon"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Comic", "value": "comic"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Doujinshi", "value": "doujinshi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Imageset", "value": "imageset"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Manga", "value": "manga"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Manhua", "value": "manhua"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Manhwa", "value": "manhwa"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Webtoon", "value": "webtoon"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Western", "value": "western"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shoujo(G)", "value": "shoujo"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shounen(B)", "value": "shounen"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Josei(W)", "value": "josei"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Seinen(M)", "value": "seinen"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Yuri(GL)", "value": "yuri"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Yaoi(BL)", "value": "yaoi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Futa(WL)", "value": "futa"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Bara(ML)", "value": "bara"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Gore", "value": "gore"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Bloody", "value": "bloody"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Violence", "value": "violence"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Ecchi", "value": "ecchi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Adult", "value": "adult"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Mature", "value": "mature"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Smut", "value": "smut"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Hentai", "value": "hentai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "4-Koma", "value": "_4_koma"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Action", "value": "action"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Adaptation", "value": "adaptation"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Adventure", "value": "adventure"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Age Gap", "value": "age_gap"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Aliens", "value": "aliens"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Animals", "value": "animals"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Anthology", "value": "anthology"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Beasts", "value": "beasts"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Bodyswap", "value": "bodyswap"}
        },
        {
          "type": "TriState",
          "filter": {"name": "cars", "value": "cars"}
        },
        {
          "type": "TriState",
          "filter": {
            "name": "Cheating/Infidelity",
            "value": "cheating_infidelity"
          }
        },
        {
          "type": "TriState",
          "filter": {"name": "Childhood Friends", "value": "childhood_friends"}
        },
        {
          "type": "TriState",
          "filter": {"name": "College Life", "value": "college_life"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Comedy", "value": "comedy"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Contest Winning", "value": "contest_winning"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Cooking", "value": "cooking"}
        },
        {
          "type": "TriState",
          "filter": {"name": "crime", "value": "crime"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Crossdressing", "value": "crossdressing"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Delinquents", "value": "delinquents"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Dementia", "value": "dementia"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Demons", "value": "demons"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Drama", "value": "drama"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Dungeons", "value": "dungeons"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Emperor's Daughter", "value": "emperor_daughte"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Fantasy", "value": "fantasy"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Fan-Colored", "value": "fan_colored"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Fetish", "value": "fetish"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Full Color", "value": "full_color"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Game", "value": "game"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Gender Bender", "value": "gender_bender"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Genderswap", "value": "genderswap"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Ghosts", "value": "ghosts"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Gyaru", "value": "gyaru"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Harem", "value": "harem"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Harlequin", "value": "harlequin"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Historical", "value": "historical"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Horror", "value": "horror"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Incest", "value": "incest"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Isekai", "value": "isekai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Kids", "value": "kids"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Loli", "value": "loli"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Magic", "value": "magic"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Magical Girls", "value": "magical_girls"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Martial Arts", "value": "martial_arts"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Mecha", "value": "mecha"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Medical", "value": "medical"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Military", "value": "military"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Monster Girls", "value": "monster_girls"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Monsters", "value": "monsters"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Music", "value": "music"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Mystery", "value": "mystery"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Netorare/NTR", "value": "netorare"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Ninja", "value": "ninja"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Office Workers", "value": "office_workers"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Omegaverse", "value": "omegaverse"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Oneshot", "value": "oneshot"}
        },
        {
          "type": "TriState",
          "filter": {"name": "parody", "value": "parody"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Philosophical", "value": "philosophical"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Police", "value": "police"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Post-Apocalyptic", "value": "post_apocalyptic"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Psychological", "value": "psychological"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Regression", "value": "regression"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Reincarnation", "value": "reincarnation"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Reverse Harem", "value": "reverse_harem"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Reverse Isekai", "value": "reverse_isekai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Romance", "value": "romance"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Royal Family", "value": "royal_family"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Royalty", "value": "royalty"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Samurai", "value": "samurai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "School Life", "value": "school_life"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Sci-Fi", "value": "sci_fi"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shota", "value": "shota"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shoujo Ai", "value": "shoujo_ai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Shounen Ai", "value": "shounen_ai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Showbiz", "value": "showbiz"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Slice of Life", "value": "slice_of_life"}
        },
        {
          "type": "TriState",
          "filter": {"name": "SM/BDSM/SUB-DOM", "value": "sm_bdsm"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Space", "value": "space"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Sports", "value": "sports"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Super Power", "value": "super_power"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Superhero", "value": "superhero"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Supernatural", "value": "supernatural"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Survival", "value": "survival"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Thriller", "value": "thriller"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Time Travel", "value": "time_travel"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Tower Climbing", "value": "tower_climbing"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Traditional Games", "value": "traditional_games"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Tragedy", "value": "tragedy"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Transmigration", "value": "transmigration"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Vampires", "value": "vampires"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Villainess", "value": "villainess"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Video Games", "value": "video_games"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Virtual Reality", "value": "virtual_reality"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Wuxia", "value": "wuxia"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Xianxia", "value": "xianxia"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Xuanhuan", "value": "xuanhuan"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Zombies", "value": "zombies"}
        },
        {
          "type": "TriState",
          "filter": {"name": "shotacon", "value": "shotacon"}
        },
        {
          "type": "TriState",
          "filter": {"name": "lolicon", "value": "lolicon"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Award Winning", "value": "award_winning"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Youkai", "value": "youkai"}
        },
        {
          "type": "TriState",
          "filter": {"name": "Uncategorized", "value": "uncategorized"}
        }
      ]),
      GroupFilter("OriginGroupFilter", "Origin", [
        {
          "type": "CheckBox",
          "filter": {"name": "Chinese", "value": "zh"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "English", "value": "en"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Japanese", "value": "ja"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Korean", "value": "ko"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Afrikaans", "value": "af"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Albanian", "value": "sq"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Amharic", "value": "am"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Arabic", "value": "ar"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Armenian", "value": "hy"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Azerbaijani", "value": "az"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Belarusian", "value": "be"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Bengali", "value": "bn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Bosnian", "value": "bs"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Bulgarian", "value": "bg"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Burmese", "value": "my"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Cambodian", "value": "km"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Catalan", "value": "ca"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Cebuano", "value": "ceb"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Chinese (Cantonese)", "value": "zh_hk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Chinese (Traditional)", "value": "zh_tw"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Croatian", "value": "hr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Czech", "value": "cs"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Danish", "value": "da"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Dutch", "value": "nl"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "English (United States)", "value": "en_us"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Esperanto", "value": "eo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Estonian", "value": "et"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Faroese", "value": "fo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Filipino", "value": "fil"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Finnish", "value": "fi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "French", "value": "fr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Georgian", "value": "ka"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "German", "value": "de"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Greek", "value": "el"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Guarani", "value": "gn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Gujarati", "value": "gu"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Haitian Creole", "value": "ht"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hausa", "value": "ha"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hebrew", "value": "he"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hindi", "value": "hi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hungarian", "value": "hu"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Icelandic", "value": "is"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Igbo", "value": "ig"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Indonesian", "value": "id"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Irish", "value": "ga"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Italian", "value": "it"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Javanese", "value": "jv"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kannada", "value": "kn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kazakh", "value": "kk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kurdish", "value": "ku"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kyrgyz", "value": "ky"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Laothian", "value": "lo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Latvian", "value": "lv"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Lithuanian", "value": "lt"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Luxembourgish", "value": "lb"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Macedonian", "value": "mk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Malagasy", "value": "mg"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Malay", "value": "ms"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Malayalam", "value": "ml"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Maltese", "value": "mt"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Maori", "value": "mi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Marathi", "value": "mr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Moldavian", "value": "mo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Mongolian", "value": "mn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Nepali", "value": "ne"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Norwegian", "value": "no"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Nyanja", "value": "ny"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Pashto", "value": "ps"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Persian", "value": "fa"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Polish", "value": "pl"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Portuguese", "value": "pt"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Portuguese (Brazil)", "value": "pt_br"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Romanian", "value": "ro"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Romansh", "value": "rm"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Russian", "value": "ru"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Samoan", "value": "sm"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Serbian", "value": "sr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Serbo-Croatian", "value": "sh"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sesotho", "value": "st"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Shona", "value": "sn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sindhi", "value": "sd"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sinhalese", "value": "si"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Slovak", "value": "sk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Slovenian", "value": "sl"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Somali", "value": "so"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Spanish", "value": "es"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Spanish (Latin America)", "value": "es_419"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Swahili", "value": "sw"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Swedish", "value": "sv"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tajik", "value": "tg"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tamil", "value": "ta"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Thai", "value": "th"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tigrinya", "value": "ti"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tonga", "value": "to"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Turkish", "value": "tr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Turkmen", "value": "tk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Ukrainian", "value": "uk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Urdu", "value": "ur"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Uzbek", "value": "uz"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Vietnamese", "value": "vi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Yoruba", "value": "yo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Zulu", "value": "zu"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Other", "value": "_t"}
        }
      ]),
      GroupFilter("LangGroupFilter", "Languages", [
        {
          "type": "CheckBox",
          "filter": {"name": "English", "value": "en"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Arabic", "value": "ar"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Bulgarian", "value": "bg"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Chinese", "value": "zh"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Czech", "value": "cs"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Danish", "value": "da"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Dutch", "value": "nl"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Filipino", "value": "fil"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Finnish", "value": "fi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "French", "value": "fr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "German", "value": "de"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Greek", "value": "el"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hebrew", "value": "he"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hindi", "value": "hi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hungarian", "value": "hu"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Indonesian", "value": "id"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Italian", "value": "it"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Japanese", "value": "ja"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Korean", "value": "ko"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Malay", "value": "ms"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Polish", "value": "pl"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Portuguese", "value": "pt"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Portuguese (Brazil)", "value": "pt_br"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Romanian", "value": "ro"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Russian", "value": "ru"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Spanish", "value": "es"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Spanish (Latin America)", "value": "es_419"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Swedish", "value": "sv"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Thai", "value": "th"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Turkish", "value": "tr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Ukrainian", "value": "uk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Vietnamese", "value": "vi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Afrikaans", "value": "af"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Albanian", "value": "sq"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Amharic", "value": "am"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Armenian", "value": "hy"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Azerbaijani", "value": "az"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Belarusian", "value": "be"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Bengali", "value": "bn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Bosnian", "value": "bs"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Burmese", "value": "my"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Cambodian", "value": "km"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Catalan", "value": "ca"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Cebuano", "value": "ceb"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Chinese (Cantonese)", "value": "zh_hk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Chinese (Traditional)", "value": "zh_tw"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Croatian", "value": "hr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "English (United States)", "value": "en_us"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Esperanto", "value": "eo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Estonian", "value": "et"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Faroese", "value": "fo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Georgian", "value": "ka"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Guarani", "value": "gn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Gujarati", "value": "gu"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Haitian Creole", "value": "ht"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hausa", "value": "ha"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Icelandic", "value": "is"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Igbo", "value": "ig"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Irish", "value": "ga"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Javanese", "value": "jv"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kannada", "value": "kn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kazakh", "value": "kk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kurdish", "value": "ku"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kyrgyz", "value": "ky"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Laothian", "value": "lo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Latvian", "value": "lv"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Lithuanian", "value": "lt"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Luxembourgish", "value": "lb"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Macedonian", "value": "mk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Malagasy", "value": "mg"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Malayalam", "value": "ml"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Maltese", "value": "mt"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Maori", "value": "mi"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Marathi", "value": "mr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Moldavian", "value": "mo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Mongolian", "value": "mn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Nepali", "value": "ne"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Norwegian", "value": "no"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Nyanja", "value": "ny"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Pashto", "value": "ps"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Persian", "value": "fa"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Romansh", "value": "rm"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Samoan", "value": "sm"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Serbian", "value": "sr"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Serbo-Croatian", "value": "sh"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sesotho", "value": "st"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Shona", "value": "sn"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sindhi", "value": "sd"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sinhalese", "value": "si"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Slovak", "value": "sk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Slovenian", "value": "sl"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Somali", "value": "so"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Swahili", "value": "sw"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tajik", "value": "tg"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tamil", "value": "ta"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tigrinya", "value": "ti"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Tonga", "value": "to"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Turkmen", "value": "tk"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Urdu", "value": "ur"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Uzbek", "value": "uz"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Yoruba", "value": "yo"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Zulu", "value": "zu"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Other", "value": "_t"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Basque", "value": "eu"}
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Portuguese (Portugal)", "value": "pt-PT"}
        }
      ]),
      TextFilter("MinChapterTextFilter", "Min. Chapters"),
      TextFilter("MaxChapterTextFilter", "Max. Chapters"),
      SeparatorFilter(),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "mirror",
          title: "Mirror",
          summary: "",
          valueIndex: 0,
          entries: mirrorEntries,
          entryValues: mirrorEntries.map((e) => "https://$e").toList()),
    ];
  }

  List<String> mirrorEntries = [
    "bato.to",
    "batocomic.com",
    "batocomic.net",
    "batocomic.org",
    "batotoo.com",
    "batotwo.com",
    "battwo.com",
    "comiko.net",
    "comiko.org",
    "mangatoto.com",
    "mangatoto.net",
    "mangatoto.org",
    "readtoto.com",
    "readtoto.net",
    "readtoto.org",
    "dto.to",
    "hto.to",
    "mto.to",
    "wto.to",
    "xbato.com",
    "xbato.net",
    "xbato.org",
    "zbato.com",
    "zbato.net",
    "zbato.org",
  ];

  String preferenceMirror(int sourceId) {
    return getPreferenceValue(sourceId, "mirror");
  }
}

Batoto main(MSource source) {
  return Batoto(source: source);
}

import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class ZoroTheme extends MProvider {
  ZoroTheme();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/most-popular?page=$page"};
    final res = await http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/recently-updated?page=$page"};
    final res = await http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MPages> search(
      MSource source, String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "${source.baseUrl}/";

    if (query.isEmpty) {
      url += "filter?";
    } else {
      url += "search?keyword=$query";
    }

    for (var filter in filters) {
      if (filter.type == "TypeFilter") {
        final type = filter.values[filter.state].value;
        if (type.isNotEmpty) {
          url += "${ll(url)}type=$type";
        }
      } else if (filter.type == "StatusFilter") {
        final status = filter.values[filter.state].value;
        if (status.isNotEmpty) {
          url += "${ll(url)}status=$status";
        }
      } else if (filter.type == "RatedFilter") {
        final rated = filter.values[filter.state].value;
        if (rated.isNotEmpty) {
          url += "${ll(url)}rated=$rated";
        }
      } else if (filter.type == "ScoreFilter") {
        final score = filter.values[filter.state].value;
        if (score.isNotEmpty) {
          url += "${ll(url)}score=$score";
        }
      } else if (filter.type == "SeasonFilter") {
        final season = filter.values[filter.state].value;
        if (season.isNotEmpty) {
          url += "${ll(url)}season=$season";
        }
      } else if (filter.type == "LanguageFilter") {
        final language = filter.values[filter.state].value;
        if (language.isNotEmpty) {
          url += "${ll(url)}language=$language";
        }
      } else if (filter.type == "SortFilter") {
        final sort = filter.values[filter.state].value;
        if (sort.isNotEmpty) {
          url += "${ll(url)}sort=$sort";
        }
      } else if (filter.type == "StartYearFilter") {
        final sy = filter.values[filter.state].value;
        if (sy.isNotEmpty) {
          url += "${ll(url)}sy=$sy";
        }
      } else if (filter.type == "StartMonthFilter") {
        final sm = filter.values[filter.state].value;
        if (sm.isNotEmpty) {
          url += "${ll(url)}sm=$sm";
        }
      } else if (filter.type == "StartDayFilter") {
        final sd = filter.values[filter.state].value;
        if (sd.isNotEmpty) {
          url += "${ll(url)}sd=$sd";
        }
      } else if (filter.type == "EndYearFilter") {
        final ey = filter.values[filter.state].value;
        if (ey.isNotEmpty) {
          url += "${ll(url)}sy=$ey";
        }
      } else if (filter.type == "EndMonthFilter") {
        final em = filter.values[filter.state].value;
        if (em.isNotEmpty) {
          url += "${ll(url)}sm=$em";
        }
      } else if (filter.type == "EndDayFilter") {
        final ed = filter.values[filter.state].value;
        if (ed.isNotEmpty) {
          url += "${ll(url)}sd=$ed";
        }
      } else if (filter.type == "GenreFilter") {
        final genre = (filter.state as List).where((e) => e.state).toList();
        if (genre.isNotEmpty) {
          url += "${ll(url)}genre=";
          for (var st in genre) {
            url += "${st.value},";
          }
        }
      }
    }
    url += "${ll(url)}page=$page";
    final data = {"url": url};
    final res = await http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {
        "Currently Airing": 0,
        "Finished Airing": 1,
      }
    ];
    final data = {"url": "${source.baseUrl}$url"};
    final res = await http('GET', json.encode(data));
    MManga anime = MManga();
    final status = xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Status:")]/span[2]/text()')
        .first;

    anime.status = parseStatus(status, statusList);
    anime.author = xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Studios:")]/span/text()')
        .first
        .replaceAll("Studios:", "");
    anime.description = xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Overview:")]/text()')
        .first
        .replaceAll("Overview:", "");
    final genre = xpath(res,
        '//*[@class="anisc-info"]/div[contains(text(),"Genres:")]/a/text()');

    anime.genre = genre;
    final id = substringAfterLast(url, '-');

    final urlEp =
        "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/list/$id";

    final dataEp = {
      "url": urlEp,
      "headers": {"referer": url}
    };
    final resEp = await http('GET', json.encode(dataEp));

    final html = json.decode(resEp)["html"];

    final epUrls = querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "href",
        typeRegExp: 0);
    final numbers = querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "data-number",
        typeRegExp: 0);

    final titles = querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "title",
        typeRegExp: 0);

    List<String> episodes = [];

    for (var i = 0; i < titles.length; i++) {
      final number = numbers[i];
      final title = titles[i];
      episodes.add("Episode $number: $title");
    }
    List<MChapter>? episodesList = [];
    for (var i = 0; i < episodes.length; i++) {
      MChapter episode = MChapter();
      episode.name = episodes[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    final id = substringAfterLast(url, '?ep=');

    final datas = {
      "url":
          "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/servers?episodeId=$id",
      "headers": {"referer": "${source.baseUrl}/$url"}
    };
    final res = await http('GET', json.encode(datas));
    final html = json.decode(res)["html"];

    final names = querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 0,
        attributes: "",
        typeRegExp: 0);

    final ids = querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 3,
        attributes: "data-id",
        typeRegExp: 0);

    final subDubs = querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 3,
        attributes: "data-type",
        typeRegExp: 0);

    List<MVideo> videos = [];
    final hosterSelection = preferenceHosterSelection(source.id);
    final typeSelection = preferenceTypeSelection(source.id);
    for (var i = 0; i < names.length; i++) {
      final name = names[i];
      final id = ids[i];
      final subDub = subDubs[i];
      final datasE = {
        "url":
            "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/sources?id=$id",
        "headers": {"referer": "${source.baseUrl}/$url"}
      };

      final resE = await http('GET', json.encode(datasE));
      String epUrl = substringBefore(substringAfter(resE, "\"link\":\""), "\"");

      List<MVideo> a = [];

      if (hosterSelection.contains(name) && typeSelection.contains(subDub)) {
        if (name.contains("Vidstreaming")) {
          a = await rapidCloudExtractor(epUrl, "Vidstreaming - $subDub");
        } else if (name.contains("Vidcloud")) {
          a = await rapidCloudExtractor(epUrl, "Vidcloud - $subDub");
        } else if (name.contains("StreamTape")) {
          a = await streamTapeExtractor(epUrl, "StreamTape - $subDub");
        }
        videos.addAll(a);
      }
    }

    return sortVideos(videos, source.id);
  }

  MPages animeElementM(String res) {
    List<MManga> animeList = [];

    final urls = xpath(
        res, '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@href');

    final names = xpath(res,
        '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@data-jname');

    final images = xpath(
        res, '//*[@class^="flw-item"]/div[@class="film-poster"]/img/@data-src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage =
        xpath(res, '//li[@class="page-item"]/a[@title="Next"]/@href', "");
    return MPages(animeList, !nextPage.isEmpty);
  }

  String ajaxRoute(String baseUrl) {
    if (baseUrl == "https://kaido.to") {
      return "";
    }
    return "/v2";
  }

  List<SelectFilterOption> yearList = [
    for (var i = 1917; i < 2024; i++)
      SelectFilterOption(i.toString(), i.toString()),
    SelectFilterOption("All", "")
  ];

  @override
  List<dynamic> getFilterList() {
    return [
      SelectFilter("TypeFilter", "Type", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Movie", "1"),
        SelectFilterOption("TV", "2"),
        SelectFilterOption("OVA", "3"),
        SelectFilterOption("ONA", "4"),
        SelectFilterOption("Special", "5"),
        SelectFilterOption("Music", "6")
      ]),
      SelectFilter("StatusFilter", "Status", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Finished Airing", "1"),
        SelectFilterOption("Currently Airing", "2"),
        SelectFilterOption("Not yet aired", "3")
      ]),
      SelectFilter("RatedFilter", "Rated", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("G", "1"),
        SelectFilterOption("PG", "2"),
        SelectFilterOption("PG-13", "3"),
        SelectFilterOption("R", "4"),
        SelectFilterOption("R+", "5"),
        SelectFilterOption("Rx", "6")
      ]),
      SelectFilter("ScoreFilter", "Score", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("(1) Appalling", "1"),
        SelectFilterOption("(2) Horrible", "2"),
        SelectFilterOption("(3) Very Bad", "3"),
        SelectFilterOption("(4) Bad", "4"),
        SelectFilterOption("(5) Average", "5"),
        SelectFilterOption("(6) Fine", "6"),
        SelectFilterOption("(7) Good", "7"),
        SelectFilterOption("(8) Very Good", "8"),
        SelectFilterOption("(9) Great", "9"),
        SelectFilterOption("(10) Masterpiece", "10")
      ]),
      SelectFilter("SeasonFilter", "Season", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Spring", "1"),
        SelectFilterOption("Summer", "2"),
        SelectFilterOption("Fall", "3"),
        SelectFilterOption("Winter", "4")
      ]),
      SelectFilter("LanguageFilter", "Language", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("SUB", "1"),
        SelectFilterOption("DUB", "2"),
        SelectFilterOption("SUB & DUB", "3")
      ]),
      SelectFilter("SortFilter", "Sort by", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Default", "default"),
        SelectFilterOption("Recently Added", "recently_added"),
        SelectFilterOption("Recently Updated", "recently_updated"),
        SelectFilterOption("Score", "score"),
        SelectFilterOption("Name A-Z", "name_az"),
        SelectFilterOption("Released Date", "released_date"),
        SelectFilterOption("Most Watched", "most_watched")
      ]),
      SelectFilter(
          "StartYearFilter", "Start year", 0, yearList.reversed.toList()),
      SelectFilter("StartMonthFilter", "Start month", 0, [
        SelectFilterOption("All", ""),
        for (var i = 1; i < 13; i++)
          SelectFilterOption(i.toString(), i.toString())
      ]),
      SelectFilter("StartDayFilter", "Start day", 0, [
        SelectFilterOption("All", ""),
        for (var i = 1; i < 32; i++)
          SelectFilterOption(i.toString(), i.toString()),
      ]),
      SelectFilter("EndYearFilter", "End year", 0, yearList.reversed.toList()),
      SelectFilter("EndmonthFilter", "End month", 0, [
        SelectFilterOption("All", ""),
        for (var i = 1; i < 32; i++)
          SelectFilterOption(i.toString(), i.toString())
      ]),
      SelectFilter("EndDayFilter", "End day", 0, [
        SelectFilterOption("All", ""),
        for (var i = 1; i < 32; i++)
          SelectFilterOption(i.toString(), i.toString())
      ]),
      GroupFilter("GenreFilter", "Genre", [
        CheckBoxFilter("Action", "1"),
        CheckBoxFilter("Adventure", "2"),
        CheckBoxFilter("Cars", "3"),
        CheckBoxFilter("Comedy", "4"),
        CheckBoxFilter("Dementia", "5"),
        CheckBoxFilter("Demons", "6"),
        CheckBoxFilter("Drama", "8"),
        CheckBoxFilter("Ecchi", "9"),
        CheckBoxFilter("Fantasy", "10"),
        CheckBoxFilter("Game", "11"),
        CheckBoxFilter("Harem", "35"),
        CheckBoxFilter("Historical", "13"),
        CheckBoxFilter("Horror", "14"),
        CheckBoxFilter("Isekai", "44"),
        CheckBoxFilter("Josei", "43"),
        CheckBoxFilter("Kids", "15"),
        CheckBoxFilter("Magic", "16"),
        CheckBoxFilter("Martial Arts", "17"),
        CheckBoxFilter("Mecha", "18"),
        CheckBoxFilter("Military", "38"),
        CheckBoxFilter("Music", "19"),
        CheckBoxFilter("Mystery", "7"),
        CheckBoxFilter("Parody", "20"),
        CheckBoxFilter("Police", "39"),
        CheckBoxFilter("Psychological", "40"),
        CheckBoxFilter("Romance", "22"),
        CheckBoxFilter("Samurai", "21"),
        CheckBoxFilter("School", "23"),
        CheckBoxFilter("Sci-Fi", "24"),
        CheckBoxFilter("Seinen", "42"),
        CheckBoxFilter("Shoujo", "25"),
        CheckBoxFilter("Shoujo Ai", "26"),
        CheckBoxFilter("Shounen", "27"),
        CheckBoxFilter("Shounen Ai", "28"),
        CheckBoxFilter("Slice of Life", "36"),
        CheckBoxFilter("Space", "29"),
        CheckBoxFilter("Sports", "30"),
        CheckBoxFilter("Super Power", "31"),
        CheckBoxFilter("Supernatural", "37"),
        CheckBoxFilter("Thriller", "41"),
        CheckBoxFilter("Vampire", "32"),
        CheckBoxFilter("Yaoi", "33"),
        CheckBoxFilter("Yuri", "34")
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences(MSource source) {
    return [
      ListPreference(
          key: "preferred_quality",
          title: "Preferred Quality",
          summary: "",
          valueIndex: 1,
          entries: ["1080p", "720p", "480p", "360p"],
          entryValues: ["1080", "720", "480", "360"]),
      ListPreference(
          key: "preferred_server",
          title: "Preferred server",
          summary: "",
          valueIndex: 0,
          entries: ["Vidstreaming", "VidCloud", "StreamTape"],
          entryValues: ["Vidstreaming", "VidCloud", "StreamTape"]),
      ListPreference(
          key: "preferred_type",
          title: "Preferred Type",
          summary: "",
          valueIndex: 0,
          entries: ["Sub", "Dub"],
          entryValues: ["sub", "dub"]),
      MultiSelectListPreference(
          key: "hoster_selection",
          title: "Enable/Disable Hosts",
          summary: "",
          entries: ["Vidstreaming", "VidCloud", "StreamTape"],
          entryValues: ["Vidstreaming", "Vidcloud", "StreamTape"],
          values: ["Vidstreaming", "Vidcloud", "StreamTape"]),
      MultiSelectListPreference(
          key: "type_selection",
          title: "Enable/Disable Types",
          summary: "",
          entries: ["Sub", "Dub"],
          entryValues: ["sub", "dub"],
          values: ["sub", "dub"]),
    ];
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String quality = getPreferenceValue(sourceId, "preferred_quality");
    String server = getPreferenceValue(sourceId, "preferred_server");
    String type = getPreferenceValue(sourceId, "preferred_type");
    videos = videos
        .where(
            (MVideo e) => e.quality.toLowerCase().contains(type.toLowerCase()))
        .toList();
    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;
      if (a.quality.contains(quality)) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.contains(quality)) {
        qualityMatchB = 1;
      }
      if (qualityMatchA != qualityMatchB) {
        return qualityMatchB - qualityMatchA;
      }

      final regex = RegExp(r'(\d+)p');
      final matchA = regex.firstMatch(a.quality);
      final matchB = regex.firstMatch(b.quality);
      final int qualityNumA = int.tryParse(matchA?.group(1) ?? '0') ?? 0;
      final int qualityNumB = int.tryParse(matchB?.group(1) ?? '0') ?? 0;
      return qualityNumB - qualityNumA;
    });

    videos.sort((MVideo a, MVideo b) {
      int serverMatchA = 0;
      if (a.quality.toLowerCase().contains(server.toLowerCase())) {
        serverMatchA = 1;
      }
      int serverMatchB = 0;
      if (b.quality.toLowerCase().contains(server.toLowerCase())) {
        serverMatchB = 1;
      }
      return serverMatchB - serverMatchA;
    });
    return videos;
  }

  List<String> preferenceHosterSelection(int sourceId) {
    return getPreferenceValue(sourceId, "hoster_selection");
  }

  List<String> preferenceTypeSelection(int sourceId) {
    return getPreferenceValue(sourceId, "type_selection");
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

ZoroTheme main() {
  return ZoroTheme();
}

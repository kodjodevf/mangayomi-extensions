import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class ZoroTheme extends MProvider {
  ZoroTheme({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}/most-popular?page=$page")))
        .body;

    return animeElementM(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}/recently-updated?page=$page")))
        .body;

    return animeElementM(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
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
    final res = (await client.get(Uri.parse(url))).body;

    return animeElementM(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Currently Airing": 0, "Finished Airing": 1}
    ];
    final res = (await client.get(Uri.parse("${source.baseUrl}$url"))).body;
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

    final resEp =
        (await client.get(Uri.parse(urlEp), headers: {"referer": url})).body;

    final html = json.decode(resEp)["html"];
    final epElements = parseHtml(html).select("a.ep-item");

    List<MChapter>? episodesList = [];

    for (var epElement in epElements) {
      final number = epElement.attr("data-number");
      final title = epElement.attr("title");

      MChapter episode = MChapter();
      episode.name = "Episode $number: $title";
      episode.url = epElement.getHref;
      episodesList.add(episode);
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final id = substringAfterLast(url, '?ep=');

    final res = (await client.get(
            Uri.parse(
                "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/servers?episodeId=$id"),
            headers: {"referer": "${source.baseUrl}/$url"}))
        .body;
    final html = json.decode(res)["html"];

    final serverElements = parseHtml(html).select("div.server-item");

    List<MVideo> videos = [];
    final hosterSelection = preferenceHosterSelection(source.id);
    final typeSelection = preferenceTypeSelection(source.id);
    for (var serverElement in serverElements) {
      final name = serverElement.text;
      final id = serverElement.attr("data-id");
      final subDub = serverElement.attr("data-type");

      final resE = (await client.get(
              Uri.parse(
                  "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/sources?id=$id"),
              headers: {"referer": "${source.baseUrl}/$url"}))
          .body;
      String epUrl = substringBefore(substringAfter(resE, "\"link\":\""), "\"");
      List<MVideo> a = [];
      if (hosterSelection.contains(name) && typeSelection.contains(subDub)) {
        if (name.contains("Vidstreaming")) {
          a = await rapidCloudExtractor(epUrl, "Vidstreaming - $subDub");
        } else if (name.contains("Vidcloud")) {
          a = await rapidCloudExtractor(epUrl, "Vidcloud - $subDub");
        } else if (name.contains("StreamTape")) {
          a = await streamTapeExtractor(epUrl, "StreamTape - $subDub");
        } else if (["HD-1", "HD-2"].any((element) => name.contains(element))) {
          a = await rapidCloudExtractor(epUrl, "$name - $subDub");
        }

        videos.addAll(a);
      }
    }

    return sortVideos(videos, source.id);
  }

  Future<List<MVideo>> rapidCloudExtractor(String url, String name) async {
    final serverUrl = ['https://megacloud.tv', 'https://rapid-cloud.co'];

    final serverType = url.startsWith('https://megacloud.tv') ? 0 : 1;
    final sourceUrl = [
      '/embed-2/ajax/e-1/getSources?id=',
      '/ajax/embed-6-v2/getSources?id='
    ];
    final sourceSpliter = ['/e-1/', '/embed-6-v2/'];
    final id = url.split(sourceSpliter[serverType]).last.split('?').first;
    final resServer = (await client.get(
            Uri.parse('${serverUrl[serverType]}${sourceUrl[serverType]}$id'),
            headers: {"X-Requested-With": "XMLHttpRequest"}))
        .body;
    final encrypted = getMapValue(resServer, "encrypted");
    String videoResJson = "";
    List<MVideo> videos = [];
    if (encrypted == "true") {
      final ciphered = getMapValue(resServer, "sources");
      List<List<int>> indexPairs = await generateIndexPairs(serverType);
      var password = '';
      String ciphertext = ciphered;
      int index = 0;
      for (List<int> item in json.decode(json.encode(indexPairs))) {
        int start = item.first + index;
        int end = start + item.last;
        String passSubstr = ciphered.substring(start, end);
        password += passSubstr;
        ciphertext = ciphertext.replaceFirst(passSubstr, "");
        index += item.last;
      }
      videoResJson = decryptAESCryptoJS(ciphertext, password);
    } else {
      videoResJson = resServer;
    }

    String masterUrl =
        ((json.decode(videoResJson) as List<Map<String, dynamic>>)
            .first)['file'];
    String type = ((json.decode(videoResJson) as List<Map<String, dynamic>>)
        .first)['type'];

    final tracks = (json.decode(resServer)['tracks'] as List)
        .where((e) => e['kind'] == 'captions' ? true : false)
        .toList();
    List<MTrack> subtitles = [];

    for (var sub in tracks) {
      try {
        MTrack subtitle = MTrack();
        subtitle
          ..label = sub["label"]
          ..file = sub["file"];
        subtitles.add(subtitle);
      } catch (_) {}
    }

    if (type == "hls") {
      final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;

      for (var it in substringAfter(masterPlaylistRes, "#EXT-X-STREAM-INF:")
          .split("#EXT-X-STREAM-INF:")) {
        final quality =
            "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

        String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

        if (!videoUrl.startsWith("http")) {
          videoUrl =
              "${masterUrl.split("/").sublist(0, masterUrl.split("/").length - 1).join("/")}/$videoUrl";
        }

        MVideo video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = "$name - $quality"
          ..subtitles = subtitles;
        videos.add(video);
      }
    } else {
      MVideo video = MVideo();
      video
        ..url = masterUrl
        ..originalUrl = masterUrl
        ..quality = "$name - Default"
        ..subtitles = subtitles;
      videos.add(video);
    }
    return videos;
  }

  Future<List<List<int>>> generateIndexPairs(int serverType) async {
    final jsPlayerUrl = [
      "https://megacloud.tv/js/player/a/prod/e1-player.min.js",
      "https://rapid-cloud.co/js/player/prod/e6-player-v2.min.js"
    ];
    final scriptText =
        (await client.get(Uri.parse(jsPlayerUrl[serverType]))).body;

    final switchCode = scriptText.substring(
        scriptText.lastIndexOf('switch'), scriptText.indexOf('=partKey'));

    List<int> indexes = [];
    for (var variableMatch
        in RegExp(r'=(\w+)').allMatches(switchCode).toList()) {
      final regex = RegExp(
          ',${(variableMatch as RegExpMatch).group(1)}=((?:0x)?([0-9a-fA-F]+))');
      Match? match = regex.firstMatch(scriptText);

      if (match != null) {
        String value = match.group(1);
        if (value.contains("0x")) {
          indexes.add(int.parse(substringAfter(value, "0x"), radix: 16));
        } else {
          indexes.add(int.parse(value));
        }
      }
    }

    return chunked(indexes, 2);
  }

  List<List<int>> chunked(List<int> list, int size) {
    List<List<int>> chunks = [];
    for (int i = 0; i < list.length; i += size) {
      int end = list.length;
      if (i + size < list.length) {
        end = i + size;
      }
      chunks.add(list.sublist(i, end));
    }
    return chunks;
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
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_quality",
          title: "Preferred Quality",
          summary: "",
          valueIndex: 1,
          entries: ["1080p", "720p", "480p", "360p"],
          entryValues: ["1080", "720", "480", "360"]),
      if (source.name == "HiAnime")
        ListPreference(
            key: "preferred_server1",
            title: "Preferred server",
            summary: "",
            valueIndex: 0,
            entries: ["HD-1", "HD-2", "StreamTape"],
            entryValues: ["HD-1", "HD-2", "StreamTape"]),
      if (source.name != "HiAnime")
        ListPreference(
            key: "preferred_server1",
            title: "Preferred server",
            summary: "",
            valueIndex: 0,
            entries: ["Vidstreaming", "VidCloud", "StreamTape"],
            entryValues: ["Vidstreaming", "VidCloud", "StreamTape"]),
      ListPreference(
          key: "preferred_type1",
          title: "Preferred Type",
          summary: "",
          valueIndex: 0,
          entries: ["Sub", "Dub"],
          entryValues: ["sub", "dub"]),
      if (source.name != "HiAnime")
        MultiSelectListPreference(
            key: "hoster_selection1",
            title: "Enable/Disable Hosts",
            summary: "",
            entries: ["Vidstreaming", "VidCloud", "StreamTape"],
            entryValues: ["Vidstreaming", "VidCloud", "StreamTape"],
            values: ["Vidstreaming", "VidCloud", "StreamTape"]),
      if (source.name == "HiAnime")
        MultiSelectListPreference(
            key: "hoster_selection1",
            title: "Enable/Disable Hosts",
            summary: "",
            entries: ["HD-1", "HD-2", "StreamTape"],
            entryValues: ["HD-1", "HD-2", "StreamTape"],
            values: ["HD-1", "HD-2", "StreamTape"]),
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
    String server = getPreferenceValue(sourceId, "preferred_server1");
    String type = getPreferenceValue(sourceId, "preferred_type1");
    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;

      if (a.quality.contains(quality) &&
          a.quality.toLowerCase().contains(type.toLowerCase()) &&
          a.quality.toLowerCase().contains(server.toLowerCase())) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.contains(quality) &&
          b.quality.toLowerCase().contains(type.toLowerCase()) &&
          b.quality.toLowerCase().contains(server.toLowerCase())) {
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
    return videos;
  }

  List<String> preferenceHosterSelection(int sourceId) {
    return getPreferenceValue(sourceId, "hoster_selection1");
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

ZoroTheme main(MSource source) {
  return ZoroTheme(source: source);
}

import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Aniwave extends MProvider {
  Aniwave({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  String get baseUrl => getPreferenceValue(source.id, "preferred_domain1");

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client
            .get(Uri.parse("$baseUrl/filter?sort=trending&page=$page")))
        .body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client
            .get(Uri.parse("$baseUrl/filter?sort=recently_updated&page=$page")))
        .body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "$baseUrl/filter?keyword=$query";

    for (var filter in filters) {
      if (filter.type == "OrderFilter") {
        final order = filter.values[filter.state].value;
        url += "${ll(url)}sort=$order";
      } else if (filter.type == "GenreFilter") {
        final genre = (filter.state as List).where((e) => e.state).toList();
        if (genre.isNotEmpty) {
          for (var st in genre) {
            url += "${ll(url)}genre[]=${st.value}";
          }
        }
      } else if (filter.type == "CountryFilter") {
        final country = (filter.state as List).where((e) => e.state).toList();
        if (country.isNotEmpty) {
          for (var st in country) {
            url += "${ll(url)}country[]=${st.value}";
          }
        }
      } else if (filter.type == "SeasonFilter") {
        final season = (filter.state as List).where((e) => e.state).toList();
        if (season.isNotEmpty) {
          for (var st in season) {
            url += "${ll(url)}season[]=${st.value}";
          }
        }
      } else if (filter.type == "YearFilter") {
        final year = (filter.state as List).where((e) => e.state).toList();
        if (year.isNotEmpty) {
          for (var st in year) {
            url += "${ll(url)}year[]=${st.value}";
          }
        }
      } else if (filter.type == "TypeFilter") {
        final type = (filter.state as List).where((e) => e.state).toList();
        if (type.isNotEmpty) {
          for (var st in type) {
            url += "${ll(url)}type[]=${st.value}";
          }
        }
      } else if (filter.type == "StatusFilter") {
        final status = (filter.state as List).where((e) => e.state).toList();
        if (status.isNotEmpty) {
          for (var st in status) {
            url += "${ll(url)}status[]=${st.value}";
          }
        }
      } else if (filter.type == "LanguageFilter") {
        final language = (filter.state as List).where((e) => e.state).toList();
        if (language.isNotEmpty) {
          for (var st in language) {
            url += "${ll(url)}language[]=${st.value}";
          }
        }
      } else if (filter.type == "RatingFilter") {
        final rating = (filter.state as List).where((e) => e.state).toList();
        if (rating.isNotEmpty) {
          for (var st in rating) {
            url += "${ll(url)}rating[]=${st.value}";
          }
        }
      }
    }

    final res = (await client.get(Uri.parse("$url&page=$page"))).body;
    return parseAnimeList(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Releasing": 0, "Completed": 1}
    ];
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    MManga anime = MManga();
    final status = xpath(res, '//div[contains(text(),"Status")]/span/text()');
    if (status.isNotEmpty) {
      anime.status = parseStatus(status.first, statusList);
    }
    final description = xpath(res,
        '//*[contains(@class,"synopsis")]/div[@class="shorting"]/div[@class="content"]/text()');
    if (description.isNotEmpty) {
      anime.description = description.first;
    }
    final author = xpath(res, '//div[contains(text(),"Studio")]/span/text()');
    if (author.isNotEmpty) {
      anime.author = author.first;
    }

    anime.genre = xpath(res, '//div[contains(text(),"Genre")]/span/a/text()');
    final id = parseHtml(res).selectFirst("div[data-id]").attr("data-id");
    final encrypt = vrfEncrypt(id);
    final vrf = "vrf=${Uri.encodeComponent(encrypt)}";

    final resEp =
        (await client.get(Uri.parse("$baseUrl/ajax/episode/list/$id?$vrf")))
            .body;

    final html = json.decode(resEp)["result"];
    List<MChapter>? episodesList = [];

    final epsHtmls = parseHtml(html).select("div.episodes ul > li");

    for (var epH in epsHtmls) {
      final epHtml = epH.outerHtml;
      final title = xpath(epHtml, '//li/@title').isNotEmpty
          ? xpath(epHtml, '//li/@title').first
          : "";
      final ids = xpath(epHtml, '//a/@data-ids').first;
      final sub = xpath(epHtml, '//a/@data-sub').first;
      final dub = xpath(epHtml, '//a/@data-dub').first;
      final softsub = title.toLowerCase().contains("softsub") ? "1" : "";
      final fillerEp = title.toLowerCase().contains("filler") ? "1" : "";
      final epNum = xpath(epHtml, '//a/@data-num').first;
      String scanlator = "";
      if (sub == "1") {
        scanlator += "Sub";
      }
      if (softsub == "1") {
        scanlator += ", Softsub";
      }
      if (dub == "1") {
        scanlator += ", Dub";
      }
      if (fillerEp == "1") {
        scanlator += ", • Filler Episode";
      }
      MChapter episode = MChapter();
      episode.name = "Episode $epNum";
      episode.scanlator = scanlator;
      episode.url = "$ids&epurl=$url/ep-$epNum";
      episodesList.add(episode);
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final ids = substringBefore(url, "&");
    final encrypt = vrfEncrypt(ids);
    final vrf = "vrf=${Uri.encodeComponent(encrypt)}";
    final res =
        (await client.get(Uri.parse("$baseUrl/ajax/server/list/$ids?$vrf")))
            .body;
    final html = json.decode(res)["result"];

    final vidsHtmls = parseHtml(html).select("div.servers > div");

    List<MVideo> videos = [];
    for (var vidH in vidsHtmls) {
      final vidHtml = vidH.outerHtml;
      final type = xpath(vidHtml, '//div/@data-type').first;
      final serversIds = xpath(vidHtml, '//li/@data-link-id');
      for (int i = 0; i < serversIds.length; i++) {
        final serverId = serversIds[i];

        final encrypt = vrfEncrypt(serverId);
        final vrf = "vrf=${Uri.encodeComponent(encrypt)}";
        final res =
            (await client.get(Uri.parse("$baseUrl/ajax/server/$serverId?$vrf")))
                .body;
        final status = json.decode(res)["status"];
        if (status == 200) {
          List<MVideo> a = [];
          final url = vrfDecrypt(json.decode(res)["result"]["url"]);
          final hosterSelection = preferenceHosterSelection(source.id);
          final typeSelection = preferenceTypeSelection(source.id);
          if (typeSelection.contains(type.toLowerCase())) {
            if (url.contains("vidplay") || url.contains("mcloud")) {
              final hosterName =
                  url.contains("vidplay") ? "VidPlay" : "MyCloud";
              if (hosterSelection.contains(hosterName.toLowerCase())) {
                a = await vidsrcExtractor(url, hosterName, type);
              }
            } else if (url.contains("mp4upload") &&
                hosterSelection.contains("mp4upload")) {
              a = await mp4UploadExtractor(url, null, "", type);
            } else if (url.contains("streamtape") &&
                hosterSelection.contains("streamtape")) {
              a = await streamTapeExtractor(url, "StreamTape - $type");
            } else if (url.contains("filemoon") &&
                hosterSelection.contains("filemoon")) {
              a = await filemoonExtractor(url, "", type);
            }
            videos.addAll(a);
          }
        }
      }
    }

    return sortVideos(videos, source.id);
  }

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final urls = xpath(res, '//div[@class="item "]/div/div/div/a/@href');
    final names = xpath(res, '//div[@class="item "]/div/div/div/a/text()');
    final images = xpath(res, '//div[@class="item "]/div/div/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, true);
  }

  List<int> rc4Encrypt(String key, List<int> message) {
    List<int> _key = utf8.encode(key);
    int _i = 0, _j = 0;
    List<int> _box = List.generate(256, (i) => i);

    int x = 0;
    for (int i = 0; i < 256; i++) {
      x = (x + _box[i] + _key[i % _key.length]) % 256;
      var tmp = _box[i];
      _box[i] = _box[x];
      _box[x] = tmp;
    }

    List<int> out = [];
    for (var char in message) {
      _i = (_i + 1) % 256;
      _j = (_j + _box[_i]) % 256;

      var tmp = _box[_i];
      _box[_i] = _box[_j];
      _box[_j] = tmp;

      final c = char ^ (_box[(_box[_i] + _box[_j]) % 256]);
      out.add(c);
    }

    return out;
  }

  String vrfEncrypt(String input) {
    final rc4 = rc4Encrypt("ysJhV6U27FVIjjuk", input.codeUnits);
    final vrf = base64Url.encode(rc4);
    final vrf1 = base64.encode(vrf.codeUnits);
    List<int> vrf2 = vrfShift(vrf1.codeUnits);
    final vrf3 = base64.encode(vrf2);
    return utf8.decode(rot13(vrf3.codeUnits));
  }

  String vrfDecrypt(String input) {
    final decode = base64Url.decode(input);
    final rc4 = rc4Encrypt("hlPeNwkncH0fq9so", decode);
    return Uri.decodeComponent(utf8.decode(rc4));
  }

  List<int> vrfShift(List<int> vrf) {
    var shifts = [-3, 3, -4, 2, -2, 5, 4, 5];
    for (var i = 0; i < vrf.length; i++) {
      var shift = shifts[i % 8];
      vrf[i] = (vrf[i] + shift) & 0xFF;
    }
    return vrf;
  }

  List<int> rot13(List<int> vrf) {
    for (var i = 0; i < vrf.length; i++) {
      var byte = vrf[i];
      if (byte >= 'A'.codeUnitAt(0) && byte <= 'Z'.codeUnitAt(0)) {
        vrf[i] = (byte - 'A'.codeUnitAt(0) + 13) % 26 + 'A'.codeUnitAt(0);
      } else if (byte >= 'a'.codeUnitAt(0) && byte <= 'z'.codeUnitAt(0)) {
        vrf[i] = (byte - 'a'.codeUnitAt(0) + 13) % 26 + 'a'.codeUnitAt(0);
      }
    }
    return vrf;
  }

  Future<List<MVideo>> vidsrcExtractor(
      String url, String name, String type) async {
    List<String> keys = json.decode((await client.get(Uri.parse(
            "https://raw.githubusercontent.com/KillerDogeEmpire/vidplay-keys/keys/keys.json")))
        .body);
    List<MVideo> videoList = [];
    final host = Uri.parse(url).host;
    final apiUrl = await getApiUrl(url, keys);

    final res = await client.get(Uri.parse(apiUrl), headers: {
      "Host": host,
      "Referer": Uri.decodeComponent(url),
      "X-Requested-With": "XMLHttpRequest"
    });
    final result = json.decode(res.body)['result'];

    if (result != 404) {
      String masterUrl =
          ((result['sources'] as List<Map<String, dynamic>>).first)['file'];
      final tracks = (result['tracks'] as List)
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
          ..quality = "$name - $type - $quality"
          ..headers = {"Referer": "https://$host/"}
          ..subtitles = subtitles;
        videoList.add(video);
      }
    }

    return videoList;
  }

  Future<String> getApiUrl(String url, List<String> keyList) async {
    final host = Uri.parse(url).host;
    final paramsToString = Uri.parse(url)
        .queryParameters
        .entries
        .map((e) => "${e.key}=${e.value}")
        .join("&");
    var vidId = substringBefore(substringAfterLast(url, "/"), "?");
    var encodedID = encodeID(vidId, keyList);
    final apiSlug = await callFromFuToken(host, encodedID);
    String apiUrlString = "";
    apiUrlString += "https://$host/$apiSlug";
    if (paramsToString.isNotEmpty) {
      apiUrlString += "?$paramsToString";
    }

    return apiUrlString;
  }

  String encodeID(String vidId, List<String> keyList) {
    var rc4Key1 = keyList[0];
    var rc4Key2 = keyList[1];
    final rc4 = rc4Encrypt(rc4Key1, vidId.codeUnits);
    final rc41 = rc4Encrypt(rc4Key2, rc4);
    return base64.encode(rc41).replaceAll("/", "_").trim();
  }

  Future<String> callFromFuToken(String host, String data) async {
    final fuTokenScript =
        (await client.get(Uri.parse("https://$host/futoken"))).body;

    String js = "";
    js += "(function";
    js += substringBefore(
        substringAfter(substringAfter(fuTokenScript, "window"), "function")
            .replaceAll("jQuery.ajax(", ""),
        "+location.search");
    js += "}(\"$data\"))";
    final jsRes = await evalJs(js);
    if (jsRes == "error") return "";
    return jsRes;
  }

  @override
  List<dynamic> getFilterList() {
    return [
      SelectFilter("OrderFilter", "Sort order", 0, [
        SelectFilterOption("Most relevance", "most_relevance"),
        SelectFilterOption("Recently updated", "recently_updated"),
        SelectFilterOption("Recently added", "recently_added"),
        SelectFilterOption("Release date", "release_date"),
        SelectFilterOption("Trending", "trending"),
        SelectFilterOption("Name A-Z", "title_az"),
        SelectFilterOption("Scores", "scores"),
        SelectFilterOption("MAL scores", "mal_scores"),
        SelectFilterOption("Most watched", "most_watched"),
        SelectFilterOption("Most favourited", "most_favourited"),
        SelectFilterOption("Number of episodes", "number_of_episodes"),
      ]),
      SeparatorFilter(),
      GroupFilter("GenreFilter", "Genre", [
        CheckBoxFilter("Action", "1"),
        CheckBoxFilter("Adventure", "2"),
        CheckBoxFilter("Avant Garde", "2262888"),
        CheckBoxFilter("Boys Love", "2262603"),
        CheckBoxFilter("Comedy", "4"),
        CheckBoxFilter("Demons", "4424081"),
        CheckBoxFilter("Drama", "7"),
        CheckBoxFilter("Ecchi", "8"),
        CheckBoxFilter("Fantasy", "9"),
        CheckBoxFilter("Girls Love", "2263743"),
        CheckBoxFilter("Gourmet", "2263289"),
        CheckBoxFilter("Harem", "11"),
        CheckBoxFilter("Horror", "14"),
        CheckBoxFilter("Isekai", "3457284"),
        CheckBoxFilter("Iyashikei", "4398552"),
        CheckBoxFilter("Josei", "15"),
        CheckBoxFilter("Kids", "16"),
        CheckBoxFilter("Magic", "4424082"),
        CheckBoxFilter("Mahou Shoujo", "3457321"),
        CheckBoxFilter("Martial Arts", "18"),
        CheckBoxFilter("Mecha", "19"),
        CheckBoxFilter("Military", "20"),
        CheckBoxFilter("Music", "21"),
        CheckBoxFilter("Mystery", "22"),
        CheckBoxFilter("Parody", "23"),
        CheckBoxFilter("Psychological", "25"),
        CheckBoxFilter("Reverse Harem", "4398403"),
        CheckBoxFilter("Romance", "26"),
        CheckBoxFilter("School", "28"),
        CheckBoxFilter("Sci-Fi", "29"),
        CheckBoxFilter("Seinen", "30"),
        CheckBoxFilter("Shoujo", "31"),
        CheckBoxFilter("Shounen", "33"),
        CheckBoxFilter("Slice of Life", "35"),
        CheckBoxFilter("Space", "36"),
        CheckBoxFilter("Sports", "37"),
        CheckBoxFilter("Super Power", "38"),
        CheckBoxFilter("Supernatural", "39"),
        CheckBoxFilter("Suspense", "2262590"),
        CheckBoxFilter("Thriller", "40"),
        CheckBoxFilter("Vampire", "41")
      ]),
      GroupFilter("CountryFilter", "Country", [
        CheckBoxFilter("China", "120823"),
        CheckBoxFilter("Japan", "120822")
      ]),
      GroupFilter("SeasonFilter", "Season", [
        CheckBoxFilter("Fall", "fall"),
        CheckBoxFilter("Summer", "summer"),
        CheckBoxFilter("Spring", "spring"),
        CheckBoxFilter("Winter", "winter"),
        CheckBoxFilter("Unknown", "unknown")
      ]),
      GroupFilter("YearFilter", "Year", [
        CheckBoxFilter("2023", "2023"),
        CheckBoxFilter("2022", "2022"),
        CheckBoxFilter("2021", "2021"),
        CheckBoxFilter("2020", "2020"),
        CheckBoxFilter("2019", "2019"),
        CheckBoxFilter("2018", "2018"),
        CheckBoxFilter("2017", "2017"),
        CheckBoxFilter("2016", "2016"),
        CheckBoxFilter("2015", "2015"),
        CheckBoxFilter("2014", "2014"),
        CheckBoxFilter("2013", "2013"),
        CheckBoxFilter("2012", "2012"),
        CheckBoxFilter("2011", "2011"),
        CheckBoxFilter("2010", "2010"),
        CheckBoxFilter("2009", "2009"),
        CheckBoxFilter("2008", "2008"),
        CheckBoxFilter("2007", "2007"),
        CheckBoxFilter("2006", "2006"),
        CheckBoxFilter("2005", "2005"),
        CheckBoxFilter("2004", "2004"),
        CheckBoxFilter("2003", "2003"),
        CheckBoxFilter("2000s", "2000s"),
        CheckBoxFilter("1990s", "1990s"),
        CheckBoxFilter("1980s", "1980s"),
        CheckBoxFilter("1970s", "1970s"),
        CheckBoxFilter("1960s", "1960s"),
        CheckBoxFilter("1950s", "1950s"),
        CheckBoxFilter("1940s", "1940s"),
        CheckBoxFilter("1930s", "1930s"),
        CheckBoxFilter("1920s", "1920s"),
        CheckBoxFilter("1910s", "1910s")
      ]),
      GroupFilter("TypeFilter", "Type", [
        CheckBoxFilter("Movie", "movie"),
        CheckBoxFilter("TV", "tv"),
        CheckBoxFilter("OVA", "ova"),
        CheckBoxFilter("ONA", "ona"),
        CheckBoxFilter("Special", "special"),
        CheckBoxFilter("Music", "music")
      ]),
      GroupFilter("StatusFilter", "Status", [
        CheckBoxFilter("Not Yet Aired", "info"),
        CheckBoxFilter("Releasing", "releasing"),
        CheckBoxFilter("Completed", "completed")
      ]),
      GroupFilter("LanguageFilter", "Language", [
        CheckBoxFilter("Sub and Dub", "subdub"),
        CheckBoxFilter("Sub", "sub"),
        CheckBoxFilter("Dub", "dub")
      ]),
      GroupFilter("RatingFilter", "Rating", [
        CheckBoxFilter("G - All Ages", "g"),
        CheckBoxFilter("PG - Children", "pg"),
        CheckBoxFilter("PG 13 - Teens 13 and Older", "pg_13"),
        CheckBoxFilter("R - 17+, Violence & Profanity", "r"),
        CheckBoxFilter("R+ - Profanity & Mild Nudity", "r+"),
        CheckBoxFilter("Rx - Hentai", "rx")
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_domain1",
          title: "Preferred domain",
          summary: "",
          valueIndex: 0,
          entries: [
            "aniwave.to",
            "aniwave.ws",
            "aniwave.li",
            "aniwave.vc"
          ],
          entryValues: [
            "https://aniwave.to",
            "https://aniwave.ws",
            "https://aniwave.li",
            "https://aniwave.vc"
          ]),
      ListPreference(
          key: "preferred_quality",
          title: "Preferred Quality",
          summary: "",
          valueIndex: 0,
          entries: ["1080p", "720p", "480p", "360p"],
          entryValues: ["1080", "720", "480", "360"]),
      ListPreference(
          key: "preferred_language",
          title: "Preferred Type",
          summary: "",
          valueIndex: 0,
          entries: ["Sub", "Softsub", "Dub"],
          entryValues: ["Sub", "Softsub", "Dub"]),
      ListPreference(
          key: "preferred_server",
          title: "Preferred server",
          summary: "",
          valueIndex: 0,
          entries: [
            "VidPlay",
            "MyCloud",
            "Filemoon",
            "StreamTape",
            "Mp4Upload"
          ],
          entryValues: [
            "vidplay",
            "mycloud",
            "filemoon",
            "streamtape",
            "mp4upload"
          ]),
      MultiSelectListPreference(
          key: "hoster_selection",
          title: "Enable/Disable Hosts",
          summary: "",
          entries: [
            "VidPlay",
            "MyCloud",
            "Filemoon",
            "StreamTape",
            "Mp4Upload"
          ],
          entryValues: [
            "vidplay",
            "mycloud",
            "filemoon",
            "streamtape",
            "mp4upload"
          ],
          values: [
            "vidplay",
            "mycloud",
            "filemoon",
            "streamtape",
            "mp4upload"
          ]),
      MultiSelectListPreference(
          key: "type_selection",
          title: "Enable/Disable Type",
          summary: "",
          entries: ["Sub", "Softsub", "Dub"],
          entryValues: ["sub", "softsub", "dub"],
          values: ["sub", "softsub", "dub"]),
    ];
  }

  List<String> preferenceHosterSelection(int sourceId) {
    return getPreferenceValue(sourceId, "hoster_selection");
  }

  List<String> preferenceTypeSelection(int sourceId) {
    return getPreferenceValue(sourceId, "type_selection");
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String quality = getPreferenceValue(sourceId, "preferred_quality");
    String server = getPreferenceValue(sourceId, "preferred_server");
    String lang = getPreferenceValue(sourceId, "preferred_language");
    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;

      if (a.quality.contains(quality) &&
          a.quality.toLowerCase().contains(lang.toLowerCase()) &&
          a.quality.toLowerCase().contains(server.toLowerCase())) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.contains(quality) &&
          b.quality.toLowerCase().contains(lang.toLowerCase()) &&
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

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

Aniwave main(MSource source) {
  return Aniwave(source: source);
}

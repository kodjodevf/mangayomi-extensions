import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class DopeFlix extends MProvider {
  DopeFlix({required this.source});

  MSource source;

  final Client client = Client();

  @override
  String get baseUrl => getPreferenceValue(source.id, "preferred_domain");

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(
          Uri.parse(
            "$baseUrl/${getPreferenceValue(source.id, "preferred_popular_page")}?page=$page",
          ),
        )).body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse("$baseUrl/home"))).body;
    List<MManga> animeList = [];
    final path =
        '//section[contains(text(),"${getPreferenceValue(source.id, "preferred_latest_page")}")]/div/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]';
    final urls = xpath(res, '$path/a/@href');
    final names = xpath(res, '$path/a/@title');
    final images = xpath(res, '$path/img/@data-src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    return MPages(animeList, false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "$baseUrl";

    if (query.isNotEmpty) {
      url += "/search/${query.replaceAll(" ", "-")}?page=$page";
    } else {
      url += "/filter/?page=$page";
      for (var filter in filters) {
        if (filter.type == "TypeFilter") {
          final type = filter.values[filter.state].value;
          url += "${ll(url)}type=$type";
        } else if (filter.type == "QualityFilter") {
          final quality = filter.values[filter.state].value;
          url += "${ll(url)}quality=$quality";
        } else if (filter.type == "ReleaseYearFilter") {
          final year = filter.values[filter.state].value;
          url += "${ll(url)}release_year=$year";
        } else if (filter.type == "GenresFilter") {
          final genre = (filter.state as List).where((e) => e.state).toList();
          if (genre.isNotEmpty) {
            url += "${ll(url)}genre=";
            for (var st in genre) {
              url += "${st.value}-";
            }
          }
        } else if (filter.type == "CountriesFilter") {
          final country = (filter.state as List).where((e) => e.state).toList();
          if (country.isNotEmpty) {
            url += "${ll(url)}country=";
            for (var st in country) {
              url += "${st.value}-";
            }
          }
        }
      }
    }

    final res = (await client.get(Uri.parse(url))).body;
    return parseAnimeList(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    MManga anime = MManga();
    final description = xpath(res, '//div[@class="description"]/text()');
    if (description.isNotEmpty) {
      anime.description = description.first.replaceAll("Overview:", "");
    }
    final author = xpath(res, '//div[contains(text(),"Production")]/a/text()');
    if (author.isNotEmpty) {
      anime.author = author.first;
    }
    anime.genre = xpath(res, '//div[contains(text(),"Genre")]/a/text()');
    List<MChapter> episodesList = [];
    final id = xpath(res, '//div[@class="detail_page-watch"]/@data-id').first;
    final dataType =
        xpath(res, '//div[@class="detail_page-watch"]/@data-type').first;
    if (dataType == "1") {
      MChapter episode = MChapter();
      episode.name = "Movie";
      episode.url = "$baseUrl/ajax/movie/episodes/$id";
      episodesList.add(episode);
    } else {
      final resS =
          (await client.get(Uri.parse("$baseUrl/ajax/v2/tv/seasons/$id"))).body;

      final seasonIds = xpath(
        resS,
        '//a[@class="dropdown-item ss-item"]/@data-id',
      );
      final seasonNames = xpath(
        resS,
        '//a[@class="dropdown-item ss-item"]/text()',
      );
      for (int i = 0; i < seasonIds.length; i++) {
        final seasonId = seasonIds[i];
        final seasonName = seasonNames[i];

        final html =
            (await client.get(
              Uri.parse("$baseUrl/ajax/v2/season/episodes/$seasonId"),
            )).body;

        final epsHtmls = parseHtml(html).select("div.eps-item");

        for (var epH in epsHtmls) {
          final epHtml = epH.outerHtml;
          final episodeId =
              xpath(
                epHtml,
                '//div[contains(@class,"eps-item")]/@data-id',
              ).first;
          final epNum =
              xpath(epHtml, '//div[@class="episode-number"]/text()').first;
          final epName = xpath(epHtml, '//h3[@class="film-name"]/text()').first;
          MChapter episode = MChapter();
          episode.name = "$seasonName $epNum $epName";
          episode.url = "$baseUrl/ajax/v2/episode/servers/$episodeId";
          episodesList.add(episode);
        }
      }
    }
    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse("$baseUrl/$url"))).body;

    final vidsHtmls = parseHtml(res).select("ul.fss-list a.btn-play");

    List<MVideo> videos = [];
    for (var vidH in vidsHtmls) {
      final vidHtml = vidH.outerHtml;
      final id = xpath(vidHtml, '//a/@data-id').first;
      final name = xpath(vidHtml, '//span/text()').first;
      final resSource =
          (await client.get(Uri.parse("$baseUrl/ajax/sources/$id"))).body;

      final vidUrl = substringBefore(
        substringAfter(resSource, "\"link\":\""),
        "\"",
      );
      List<MVideo> a = [];
      String masterUrl = "";
      String type = "";
      if (name.contains("DoodStream")) {
        a = await doodExtractor(vidUrl, "DoodStream");
      } else if (["Vidcloud", "UpCloud"].contains(name)) {
        final id = substringBefore(substringAfter(vidUrl, "/embed-4/"), "?");
        final serverUrl = substringBefore(vidUrl, "/embed");

        final resServer =
            (await client.get(
              Uri.parse("$serverUrl/ajax/embed-4/getSources?id=$id"),
              headers: {"X-Requested-With": "XMLHttpRequest"},
            )).body;
        final encrypted = getMapValue(resServer, "encrypted");

        String videoResJson = "";
        if (encrypted == "true") {
          final ciphered = getMapValue(resServer, "sources");

          List<List<int>> indexPairs = await generateIndexPairs();

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
          masterUrl =
              ((json.decode(videoResJson) as List<Map<String, dynamic>>)
                  .first)['file'];

          type =
              ((json.decode(videoResJson) as List<Map<String, dynamic>>)
                  .first)['type'];
        } else {
          masterUrl =
              ((json.decode(resServer)["sources"] as List<Map<String, dynamic>>)
                  .first)['file'];

          type =
              ((json.decode(resServer)["sources"] as List<Map<String, dynamic>>)
                  .first)['type'];
        }

        final tracks =
            (json.decode(resServer)['tracks'] as List)
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

        subtitles = sortSubs(subtitles, source.id);
        if (type == "hls") {
          final masterPlaylistRes =
              (await client.get(Uri.parse(masterUrl))).body;

          for (var it in substringAfter(
            masterPlaylistRes,
            "#EXT-X-STREAM-INF:",
          ).split("#EXT-X-STREAM-INF:")) {
            final quality =
                "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

            String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

            if (!videoUrl.startsWith("http")) {
              videoUrl =
                  "${(masterUrl as String).split("/").sublist(0, (masterUrl as String).split("/").length - 1).join("/")}/$videoUrl";
            }

            MVideo video = MVideo();
            video
              ..url = videoUrl
              ..originalUrl = videoUrl
              ..quality = "$name - $quality"
              ..subtitles = subtitles;
            a.add(video);
          }
        } else {
          MVideo video = MVideo();
          video
            ..url = masterUrl
            ..originalUrl = masterUrl
            ..quality = "$name - Default"
            ..subtitles = subtitles;
          a.add(video);
        }
      }
      videos.addAll(a);
    }

    return sortVideos(videos, source.id);
  }

  Future<List<List<int>>> generateIndexPairs() async {
    final res =
        (await client.get(
          Uri.parse("https://rabbitstream.net/js/player/prod/e4-player.min.js"),
        )).body;

    String script = substringBefore(substringAfter(res, "const "), "()");
    script = script.substring(0, script.lastIndexOf(','));
    final list =
        script
            .split(",")
            .map((String e) {
              String value = substringAfter(e, "=");
              if (value.contains("0x")) {
                return int.parse(substringAfter(value, "0x"), radix: 16);
              } else {
                return int.parse(value);
              }
            })
            .toList()
            .skip(1)
            .toList();
    return chunked(
      list,
      2,
    ).map((List<int> list) => list.reversed.toList()).toList();
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

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final path =
        '//div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]';
    final urls = xpath(res, '$path/a/@href');
    final names = xpath(res, '$path/a/@title');
    final images = xpath(res, '$path/img/@data-src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final pages = xpath(
      res,
      '//ul[contains(@class,"pagination")]/li/a[@title="Next"]/@title',
    );
    return MPages(animeList, pages.isNotEmpty);
  }

  @override
  List<dynamic> getFilterList() {
    return [
      SelectFilter("TypeFilter", "Type", 0, [
        SelectFilterOption("All", "all"),
        SelectFilterOption("Movies", "movies"),
        SelectFilterOption("TV Shows", "tv"),
      ]),
      SelectFilter("QualityFilter", "Quality", 0, [
        SelectFilterOption("All", "all"),
        SelectFilterOption("HD", "HD"),
        SelectFilterOption("SD", "SD"),
        SelectFilterOption("CAM", "CAM"),
      ]),
      SelectFilter("ReleaseYearFilter", "Released at", 0, [
        SelectFilterOption("All", "all"),
        SelectFilterOption("2024", "2024"),
        SelectFilterOption("2023", "2023"),
        SelectFilterOption("2022", "2022"),
        SelectFilterOption("2021", "2021"),
        SelectFilterOption("2020", "2020"),
        SelectFilterOption("2019", "2019"),
        SelectFilterOption("2018", "2018"),
        SelectFilterOption("Older", "older-2018"),
      ]),
      SeparatorFilter(),
      GroupFilter("GenresFilter", "Genre", [
        CheckBoxFilter("Action", "10"),
        CheckBoxFilter("Action & Adventure", "24"),
        CheckBoxFilter("Adventure", "18"),
        CheckBoxFilter("Animation", "3"),
        CheckBoxFilter("Biography", "37"),
        CheckBoxFilter("Comedy", "7"),
        CheckBoxFilter("Crime", "2"),
        CheckBoxFilter("Documentary", "11"),
        CheckBoxFilter("Drama", "4"),
        CheckBoxFilter("Family", "9"),
        CheckBoxFilter("Fantasy", "13"),
        CheckBoxFilter("History", "19"),
        CheckBoxFilter("Horror", "14"),
        CheckBoxFilter("Kids", "27"),
        CheckBoxFilter("Music", "15"),
        CheckBoxFilter("Mystery", "1"),
        CheckBoxFilter("News", "34"),
        CheckBoxFilter("Reality", "22"),
        CheckBoxFilter("Romance", "12"),
        CheckBoxFilter("Sci-Fi & Fantasy", "31"),
        CheckBoxFilter("Science Fiction", "5"),
        CheckBoxFilter("Soap", "35"),
        CheckBoxFilter("Talk", "29"),
        CheckBoxFilter("Thriller", "16"),
        CheckBoxFilter("TV Movie", "8"),
        CheckBoxFilter("War", "17"),
        CheckBoxFilter("War & Politics", "28"),
        CheckBoxFilter("Western", "6"),
      ]),
      GroupFilter("CountriesFilter", "Countries", [
        CheckBoxFilter("Argentina", "11"),
        CheckBoxFilter("Australia", "151"),
        CheckBoxFilter("Austria", "4"),
        CheckBoxFilter("Belgium", "44"),
        CheckBoxFilter("Brazil", "190"),
        CheckBoxFilter("Canada", "147"),
        CheckBoxFilter("China", "101"),
        CheckBoxFilter("Czech Republic", "231"),
        CheckBoxFilter("Denmark", "222"),
        CheckBoxFilter("Finland", "158"),
        CheckBoxFilter("France", "3"),
        CheckBoxFilter("Germany", "96"),
        CheckBoxFilter("Hong Kong", "93"),
        CheckBoxFilter("Hungary", "72"),
        CheckBoxFilter("India", "105"),
        CheckBoxFilter("Ireland", "196"),
        CheckBoxFilter("Israel", "24"),
        CheckBoxFilter("Italy", "205"),
        CheckBoxFilter("Japan", "173"),
        CheckBoxFilter("Luxembourg", "91"),
        CheckBoxFilter("Mexico", "40"),
        CheckBoxFilter("Netherlands", "172"),
        CheckBoxFilter("New Zealand", "122"),
        CheckBoxFilter("Norway", "219"),
        CheckBoxFilter("Poland", "23"),
        CheckBoxFilter("Romania", "170"),
        CheckBoxFilter("Russia", "109"),
        CheckBoxFilter("South Africa", "200"),
        CheckBoxFilter("South Korea", "135"),
        CheckBoxFilter("Spain", "62"),
        CheckBoxFilter("Sweden", "114"),
        CheckBoxFilter("Switzerland", "41"),
        CheckBoxFilter("Taiwan", "119"),
        CheckBoxFilter("Thailand", "57"),
        CheckBoxFilter("United Kingdom", "180"),
        CheckBoxFilter("United States of America", "129"),
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      if (source.name == "DopeBox")
        ListPreference(
          key: "preferred_domain",
          title: "Preferred domain",
          summary: "",
          valueIndex: 0,
          entries: ["dopebox.to", "dopebox.se"],
          entryValues: ["https://dopebox.to", "https://dopebox.se"],
        ),
      if (source.name == "SFlix")
        ListPreference(
          key: "preferred_domain",
          title: "Preferred domain",
          summary: "",
          valueIndex: 0,
          entries: ["sflix.to", "sflix.se"],
          entryValues: ["https://sflix.to", "https://sflix.se"],
        ),
      ListPreference(
        key: "preferred_quality",
        title: "Preferred Quality",
        summary: "",
        valueIndex: 0,
        entries: ["1080p", "720p", "480p", "360p"],
        entryValues: ["1080p", "720p", "480p", "360p"],
      ),
      ListPreference(
        key: "preferred_subLang",
        title: "Preferred sub language",
        summary: "",
        valueIndex: 1,
        entries: [
          "Arabic",
          "English",
          "French",
          "German",
          "Hungarian",
          "Italian",
          "Japanese",
          "Portuguese",
          "Romanian",
          "Russian",
          "Spanish",
        ],
        entryValues: [
          "Arabic",
          "English",
          "French",
          "German",
          "Hungarian",
          "Italian",
          "Japanese",
          "Portuguese",
          "Romanian",
          "Russian",
          "Spanish",
        ],
      ),
      ListPreference(
        key: "preferred_latest_page",
        title: "Preferred latest page",
        summary: "",
        valueIndex: 0,
        entries: ["Movies", "TV Shows"],
        entryValues: ["Latest Movies", "Latest TV Shows"],
      ),
      ListPreference(
        key: "preferred_popular_page",
        title: "Preferred popular page",
        summary: "",
        valueIndex: 0,
        entries: ["Movies", "TV Shows"],
        entryValues: ["movie", "tv-show"],
      ),
    ];
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String quality = getPreferenceValue(sourceId, "preferred_quality");

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

    return videos;
  }

  List<MTrack> sortSubs(List<MTrack> subs, int sourceId) {
    String lang = getPreferenceValue(sourceId, "preferred_subLang");

    subs.sort((MTrack a, MTrack b) {
      int langMatchA = 0;
      if (a.label.toLowerCase().contains(lang.toLowerCase())) {
        langMatchA = 1;
      }
      int langMatchB = 0;
      if (b.label.toLowerCase().contains(lang.toLowerCase())) {
        langMatchB = 1;
      }
      return langMatchB - langMatchA;
    });
    return subs;
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

DopeFlix main(MSource source) {
  return DopeFlix(source: source);
}

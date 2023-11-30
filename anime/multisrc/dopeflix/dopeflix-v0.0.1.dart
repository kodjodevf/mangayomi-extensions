import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class DopeFlix extends MProvider {
  DopeFlix();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/movie?page=$page"};
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/home"};
    final res = await http('GET', json.encode(data));
    List<MManga> animeList = [];
    final path =
        '//section[contains(text(),"Latest Movies")]/div/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]';
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
  Future<MPages> search(
      MSource source, String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "${source.baseUrl}";

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
    final data = {"url": url};
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    url = Uri.parse(url).path;
    final data = {"url": "${source.baseUrl}$url"};
    final res = await http('GET', json.encode(data));
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
      episode.url = "${source.baseUrl}/ajax/movie/episodes/$id";
      episodesList.add(episode);
    } else {
      final dataS = {"url": "${source.baseUrl}/ajax/v2/tv/seasons/$id"};
      final resS = await http('GET', json.encode(dataS));
      final seasonId =
          xpath(resS, '//a[@class="dropdown-item ss-item"]/@data-id').first;
      final seasonName =
          xpath(resS, '//a[@class="dropdown-item ss-item"]/text()').first;
      final dataE = {
        "url": "${source.baseUrl}/ajax/v2/season/episodes/$seasonId"
      };
      final html = await http('GET', json.encode(dataE));
      final epsHtml = querySelectorAll(html,
          selector: "div.eps-item",
          typeElement: 2,
          attributes: "",
          typeRegExp: 0);
      for (var epHtml in epsHtml) {
        final episodeId =
            xpath(epHtml, '//div[contains(@class,"eps-item")]/@data-id').first;
        final epNum =
            xpath(epHtml, '//div[@class="episode-number"]/text()').first;
        final epName = xpath(epHtml, '//h3[@class="film-name"]/text()').first;
        MChapter episode = MChapter();
        episode.name = "$seasonName $epNum $epName";
        episode.url = "${source.baseUrl}/ajax/v2/episode/servers/$episodeId";
        episodesList.add(episode);
      }
    }
    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    url = Uri.parse(url).path;
    final res =
        await http('GET', json.encode({"url": "${source.baseUrl}/$url"}));
    final vidsHtml = querySelectorAll(res,
        selector: "ul.fss-list a.btn-play",
        typeElement: 2,
        attributes: "",
        typeRegExp: 0);
    List<MVideo> videos = [];
    for (var vidHtml in vidsHtml) {
      final id = xpath(vidHtml, '//a/@data-id').first;
      final name = xpath(vidHtml, '//span/text()').first;
      final resSource = await http(
          'GET', json.encode({"url": "${source.baseUrl}/ajax/sources/$id"}));
      final vidUrl =
          substringBefore(substringAfter(resSource, "\"link\":\""), "\"");
      List<MVideo> a = [];
      if (name.contains("DoodStream")) {
        a = await doodExtractor(vidUrl, "DoodStream");
      } else if (["Vidcloud", "UpCloud"].contains(name)) {
        final id = substringBefore(substringAfter(vidUrl, "/embed-4/"), "?");
        final serverUrl = substringBefore(vidUrl, "/embed");
        final datasServer = {
          "url": "$serverUrl/ajax/embed-4/getSources?id=$id",
          "headers": {"X-Requested-With": "XMLHttpRequest"}
        };

        final resServer = await http('GET', json.encode(datasServer));
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
          final masterPlaylistRes =
              await http('GET', json.encode({"url": masterUrl}));
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

    return videos;
  }

  Future<List<List<int>>> generateIndexPairs() async {
    final res = await http(
        'GET',
        json.encode({
          "url": "https://rabbitstream.net/js/player/prod/e4-player.min.js"
        }));
    String script = substringBefore(substringAfter(res, "const "), "()");
    script = script.substring(0, script.lastIndexOf(','));
    final list = script
        .split(",")
        .map((e) {
          String value = substringAfter((e as String), "=");
          if (value.contains("0x")) {
            return int.parse(substringAfter(value, "0x"), radix: 16);
          } else {
            return int.parse(value);
          }
        })
        .toList()
        .skip(1)
        .toList();
    return chunked(list, 2)
        .map((list) => (list as List<int>).reversed.toList())
        .toList();
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
        res, '//ul[contains(@class,"pagination")]/li/a[@title="Next"]/@title');
    return MPages(animeList, pages.isNotEmpty);
  }

  @override
  List<dynamic> getFilterList() {
    return [
      SelectFilter("TypeFilter", "Type", 0, [
        SelectFilterOption("All", "all"),
        SelectFilterOption("Movies", "movies"),
        SelectFilterOption("TV Shows", "tv")
      ]),
      SelectFilter("QualityFilter", "Quality", 0, [
        SelectFilterOption("All", "all"),
        SelectFilterOption("HD", "HD"),
        SelectFilterOption("SD", "SD"),
        SelectFilterOption("CAM", "CAM")
      ]),
      SelectFilter("ReleaseYearFilter", "Released at", 0, [
        SelectFilterOption("All", "all"),
        SelectFilterOption("2023", "2023"),
        SelectFilterOption("2022", "2022"),
        SelectFilterOption("2021", "2021"),
        SelectFilterOption("2020", "2020"),
        SelectFilterOption("2019", "2019"),
        SelectFilterOption("2018", "2018"),
        SelectFilterOption("Older", "older-2018")
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
        CheckBoxFilter("Western", "6")
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
        CheckBoxFilter("United States of America", "129")
      ]),
    ];
  }

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

DopeFlix main() {
  return DopeFlix();
}

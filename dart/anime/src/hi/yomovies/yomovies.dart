import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class YoMovies extends MProvider {
  YoMovies({required this.source});

  MSource source;

  final Client client = Client();

  @override
  String get baseUrl => getPreferenceValue(source.id, "overrideBaseUrl");

  @override
  bool get supportsLatest => false;

  @override
  Future<MPages> getPopular(int page) async {
    String pageNu = page == 1 ? "" : "page/$page/";

    final res =
        (await client.get(Uri.parse("$baseUrl/most-favorites/$pageNu"))).body;
    final document = parseHtml(res);
    return animeFromElement(
      document.select("div.movies-list > div.ml-item"),
      document.selectFirst("ul.pagination > li.active + li")?.getHref != null,
    );
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    return MPages([], false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    String pageNu = page == 1 ? "" : "/page/$page";
    if (query.isNotEmpty) {
      url = "$baseUrl$pageNu/?s=$query";
    } else {
      for (var filter in filters) {
        if (filter.type.isNotEmpty) {
          final first = filter.values[filter.state].value;
          if (first.isNotEmpty) {
            url = first;
          }
        }
      }
      url = "$baseUrl$url$pageNu";
    }
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    return animeFromElement(
      document.select("div.movies-list > div.ml-item"),
      document.selectFirst("ul.pagination > li.active + li")?.getHref != null,
    );
  }

  @override
  Future<MManga> getDetail(String url) async {
    url = getUrlWithoutDomain(url);

    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    MManga anime = MManga();
    var infoElement = document.selectFirst("div.mvi-content");
    anime.description = infoElement.selectFirst("p.f-desc")?.text ?? "";

    anime.genre = xpath(
      res,
      '//div[@class="mvici-left" and contains(text(),"Genre:")]/p/a/text()',
    );

    List<MChapter> episodeList = [];
    final seasonListElements = document.select("div#seasons > div.tvseason");
    if (seasonListElements.isEmpty) {
      MChapter ep = MChapter();
      ep.name = "Movie";
      ep.url = url;
      episodeList.add(ep);
    } else {
      for (var season in seasonListElements) {
        var seasonText = season.selectFirst("div.les-title").text.trim();
        for (var episode in season.select("div.les-content > a")) {
          var epNumber = substringAfter(episode.text.trim(), "pisode ");
          MChapter ep = MChapter();
          ep.name = "$seasonText Ep. $epNumber";
          ep.url = episode.getHref;

          episodeList.add(ep);
        }
      }
    }

    anime.chapters = episodeList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final document = parseHtml(res);
    final serverElements = document.select("div.movieplay > iframe");
    List<MVideo> videos = [];
    for (var serverElement in serverElements) {
      var url = serverElement.getSrc;
      List<MVideo> a = [];
      if (url.contains("minoplres")) {
        a = await minoplresExtractor(url);
      }
      videos.addAll(a);
    }
    return sortVideos(videos, source.id);
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
        key: "overrideBaseUrl",
        title: "Override BaseUrl",
        summary: "",
        value: "https://yomovies.boo",
        dialogTitle: "Override BaseUrl",
        dialogMessage: "",
        text: "https://yomovies.boo",
      ),
      ListPreference(
        key: "preferred_quality",
        title: "Preferred quality",
        summary: "",
        valueIndex: 0,
        entries: ["1080p", "720p", "480p", "360p"],
        entryValues: ["1080", "720", "480", "360"],
      ),
    ];
  }

  Future<List<MVideo>> minoplresExtractor(String url) async {
    List<MVideo> videos = [];

    final res =
        (await client.get(Uri.parse(url), headers: {"Referer": url})).body;
    final script = xpath(res, '//script[contains(text(),"sources:")]/text()');
    if (script.isEmpty) return [];
    final masterUrl = substringBefore(
      substringAfter(script.first, "file:\""),
      '"',
    );
    final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;
    for (var it in substringAfter(
      masterPlaylistRes,
      "#EXT-X-STREAM-INF:",
    ).split("#EXT-X-STREAM-INF:")) {
      final quality =
          "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

      String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

      MVideo video = MVideo();
      video
        ..url = videoUrl
        ..originalUrl = videoUrl
        ..quality = "Minoplres -  $quality";
      videos.add(video);
    }
    return videos;
  }

  MPages animeFromElement(List<MElement> elements, bool hasNextPage) {
    List<MManga> animeList = [];
    for (var element in elements) {
      MManga anime = MManga();
      anime.name = element.selectFirst("div.qtip-title").text;
      anime.imageUrl =
          element.selectFirst("img[data-original]")?.attr("data-original") ??
          "";
      anime.link = element.selectFirst("a[href]").getHref;
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage);
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

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter(
        "Note: Only one selection at a time works, and it ignores text search",
      ),
      SeparatorFilter(),
      SelectFilter("BollywoodFilter", "Bollywood", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("Bollywood", "/genre/bollywood"),
        SelectFilterOption("Trending", "/genre/top-rated"),
        SelectFilterOption(
          "Bollywood (2024)",
          "/account/?ptype=post&tax_category%5B%5D=bollywood&tax_release-year=2024&wpas=1",
        ),
        SelectFilterOption(
          "Bollywood (2023)",
          "/account/?ptype=post&tax_category%5B%5D=bollywood&tax_release-year=2023&wpas=1",
        ),
        SelectFilterOption(
          "Bollywood (2022)",
          "/account/?ptype=post&tax_category%5B%5D=bollywood&tax_release-year=2022&wpas=1",
        ),
        SelectFilterOption(
          "Bollywood (2021)",
          "/account/?ptype=post&tax_category%5B%5D=bollywood&tax_release-year=2021&wpas=1",
        ),
      ]),
      SelectFilter("DualAudioFilter", "Dual Audio", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("Dual Audio", "/genre/dual-audio"),
        SelectFilterOption(
          "Hollywood Dubbed",
          "/account/?ptype=post&tax_category%5B%5D=dual-audio&wpas=1",
        ),
        SelectFilterOption(
          "South Dubbed",
          "/account/?ptype=post&tax_category%5B%5D=dual-audio&tax_category%5B%5D=south-special&wpas=1",
        ),
      ]),
      SelectFilter("HollywoodFilter", "Hollywood", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("Hollywood", "/genre/hollywood"),
        SelectFilterOption(
          "Hollywood (2023)",
          "/account/?ptype=post&tax_category%5B%5D=hollywood&tax_release-year=2023&wpas=1",
        ),
        SelectFilterOption(
          "Hollywood (2022)",
          "/account/?ptype=post&tax_category%5B%5D=hollywood&tax_release-year=2022&wpas=1",
        ),
        SelectFilterOption(
          "Hollywood (2021)",
          "/account/?ptype=post&tax_category%5B%5D=hollywood&tax_release-year=2021&wpas=1",
        ),
      ]),
      SelectFilter("EnglishSeriesFilter", "Hindi Series", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("English Series", "/series"),
      ]),
      SelectFilter("HindiSeriesFilter", "English Series", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("Hindi Series", "/genre/web-series"),
        SelectFilterOption("Netflix", "/director/netflix"),
        SelectFilterOption("Amazon", "/director/amazon-prime"),
        SelectFilterOption("Altbalaji", "/director/altbalaji"),
        SelectFilterOption("Zee5", "/director/zee5"),
        SelectFilterOption("Voot", "/director/voot-originals"),
        SelectFilterOption("Mx Player", "/director/mx-player"),
        SelectFilterOption("Hotstar", "/director/hotstar"),
        SelectFilterOption("Viu", "/director/viu-originals"),
        SelectFilterOption("Sony Liv", "/director/sonyliv-original"),
      ]),
      SelectFilter("GenreFilter", "Genre", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("Action", "/genre/action"),
        SelectFilterOption("Adventure", "/genre/adventure"),
        SelectFilterOption("Animation", "/genre/animation"),
        SelectFilterOption("Biography", "/genre/biography"),
        SelectFilterOption("Comedy", "/genre/comedy"),
        SelectFilterOption("Crime", "/genre/crime"),
        SelectFilterOption("Drama", "/genre/drama"),
        SelectFilterOption("Music", "/genre/music"),
        SelectFilterOption("Mystery", "/genre/mystery"),
        SelectFilterOption("Family", "/genre/family"),
        SelectFilterOption("Fantasy", "/genre/fantasy"),
        SelectFilterOption("Horror", "/genre/horror"),
        SelectFilterOption("History", "/genre/history"),
        SelectFilterOption("Romance", "/genre/romantic"),
        SelectFilterOption("Science Fiction", "/genre/science-fiction"),
        SelectFilterOption("Thriller", "/genre/thriller"),
        SelectFilterOption("War", "/genre/war"),
      ]),
      SelectFilter("ExtraMoviesFilter", "ExtraMovies", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("ExtraMovies", "/genre/south-special"),
        SelectFilterOption("Bengali", "/genre/bengali"),
        SelectFilterOption("Marathi", "/genre/marathi"),
        SelectFilterOption("Gujarati", "/genre/gujarati"),
        SelectFilterOption("Punjabi", "/genre/punjabi"),
        SelectFilterOption("Tamil", "/genre/tamil"),
        SelectFilterOption("Telugu", "/genre/telugu"),
        SelectFilterOption("Malayalam", "/genre/malayalam"),
        SelectFilterOption("Kannada", "/genre/kannada"),
        SelectFilterOption("Pakistani", "/genre/pakistani"),
      ]),
      SelectFilter("EroticFilter", "Erotic", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("Erotic", "/genre/erotic-movies"),
      ]),
      SelectFilter("HotSeriesFilter", "Hot Series", 0, [
        SelectFilterOption("<select>", ""),
        SelectFilterOption("Hot Series", "/genre/tv-shows"),
        SelectFilterOption("Uncut", "/?s=uncut"),
        SelectFilterOption("Fliz Movies", "/director/fliz-movies"),
        SelectFilterOption("Nuefliks", "/director/nuefliks-exclusive"),
        SelectFilterOption("Hotshots", "/director/hotshots"),
        SelectFilterOption("Ullu Originals", "/?s=ullu"),
        SelectFilterOption("Kooku", "/director/kooku-originals"),
        SelectFilterOption("Gupchup", "/director/gupchup-exclusive"),
        SelectFilterOption("Feneomovies", "/director/feneomovies"),
        SelectFilterOption("Cinemadosti", "/director/cinemadosti"),
        SelectFilterOption("Primeflix", "/director/primeflix"),
        SelectFilterOption("Gemplex", "/director/gemplex"),
        SelectFilterOption("Rabbit", "/director/rabbit-original"),
        SelectFilterOption("HotMasti", "/director/hotmasti-originals"),
        SelectFilterOption("BoomMovies", "/director/boommovies-original"),
        SelectFilterOption("CliffMovies", "/director/cliff-movies"),
        SelectFilterOption("MastiPrime", "/director/masti-prime-originals"),
        SelectFilterOption("Ek Night Show", "/director/ek-night-show"),
        SelectFilterOption("Flixsksmovies", "/director/flixsksmovies"),
        SelectFilterOption("Lootlo", "/director/lootlo-original"),
        SelectFilterOption("Hootzy", "/director/hootzy-channel"),
        SelectFilterOption("Balloons", "/director/balloons-originals"),
        SelectFilterOption(
          "Big Movie Zoo",
          "/director/big-movie-zoo-originals",
        ),
        SelectFilterOption("Bambooflix", "/director/bambooflix"),
        SelectFilterOption("Piliflix", "/director/piliflix-originals"),
        SelectFilterOption("11upmovies", "/director/11upmovies-originals"),
        SelectFilterOption("Eightshots", "/director/eightshots-originals"),
        SelectFilterOption(
          "I-Entertainment",
          "/director/i-entertainment-exclusive",
        ),
        SelectFilterOption("Hotprime", "/director/hotprime-originals"),
        SelectFilterOption("BananaPrime", "/director/banana-prime"),
        SelectFilterOption("HotHitFilms", "/director/hothitfilms"),
        SelectFilterOption("Chikooflix", "/director/chikooflix-originals"),
        SelectFilterOption("Glamheart", "/?s=glamheart"),
        SelectFilterOption("Worldprime", "/director/worldprime-originals"),
      ]),
    ];
  }
}

YoMovies main(MSource source) {
  return YoMovies(source: source);
}

import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AnimeWorldIndia extends MProvider {
  AnimeWorldIndia({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(
          Uri.parse(
            "${source.baseUrl}/advanced-search/page/$page/?s_lang=${source.lang}&s_orderby=viewed",
          ),
        )).body;

    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(
          Uri.parse(
            "${source.baseUrl}/advanced-search/page/$page/?s_lang=${source.lang}&s_orderby=update",
          ),
        )).body;

    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url =
        "${source.baseUrl}/advanced-search/page/$page/?s_keyword=$query&s_lang=${source.lang}";
    for (var filter in filters) {
      if (filter.type == "TypeFilter") {
        final type = filter.values[filter.state].value;
        url += "${ll(url)}s_type=$type";
      } else if (filter.type == "StatusFilter") {
        final status = filter.values[filter.state].value;
        url += "${ll(url)}s_status=$status";
      } else if (filter.type == "StyleFilter") {
        final style = filter.values[filter.state].value;
        url += "${ll(url)}s_sub_type=$style";
      } else if (filter.type == "YearFilter") {
        final year = filter.values[filter.state].value;
        url += "${ll(url)}s_year=$year";
      } else if (filter.type == "SortFilter") {
        final sort = filter.values[filter.state].value;
        url += "${ll(url)}s_orderby=$sort";
      } else if (filter.type == "GenresFilter") {
        final genre = (filter.state as List).where((e) => e.state).toList();
        url += "${ll(url)}s_genre=";
        if (genre.isNotEmpty) {
          for (var st in genre) {
            String value = st.value;
            url += value.toLowerCase().replaceAll(" ", "-");
            if (genre.length > 1) {
              url += "%2C";
            }
          }
          if (genre.length > 1) {
            url = substringBeforeLast(url, '%2C');
          }
        }
      }
    }

    final res = (await client.get(Uri.parse(url))).body;
    return parseAnimeList(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    MManga anime = MManga();
    final document = parseHtml(res);
    final isMovie =
        document.xpath('//li/a[contains(text(),"Movie")]/text()').isNotEmpty;
    if (isMovie) {
      anime.status = MStatus.completed;
    } else {
      final eps = xpath(
        res,
        '//ul/li/a[contains(@href,"${source.baseUrl}/watch")]/text()',
      );
      if (eps.isNotEmpty) {
        final epParts = eps.first
            .substring(3)
            .replaceAll(" ", "")
            .replaceAll("\n", "")
            .split('/');
        if (epParts.length == 2) {
          if (epParts[0].compareTo(epParts[1]) == 0) {
            anime.status = MStatus.completed;
          } else {
            anime.status = MStatus.ongoing;
          }
        }
      }
    }
    anime.description = document.selectFirst("div[data-synopsis]")?.text ?? "";
    anime.author = document
        .xpath('//li[contains(text(),"Producers:")]/span/a/text()')
        .join(', ');
    anime.genre = document.xpath(
      '//span[@class="leading-6"]/a[contains(@class,"border-opacity-30")]/text()',
    );
    final seasonsJson =
        json.decode(
              substringBeforeLast(
                substringBefore(
                  substringAfter(res, "var season_list = "),
                  "var season_label =",
                ),
                ";",
              ),
            )
            as List<Map<String, dynamic>>;
    bool isSingleSeason = seasonsJson.length == 1;
    List<MChapter>? episodesList = [];
    for (var i = 0; i < seasonsJson.length; i++) {
      final seasonJson = seasonsJson[i];
      final seasonName = isSingleSeason ? "" : "Season ${i + 1}";
      final episodesJson =
          (seasonJson["episodes"]["all"] as List<Map<String, dynamic>>).reversed
              .toList();
      for (var j = 0; j < episodesJson.length; j++) {
        final episodeJson = episodesJson[j];
        final episodeTitle = episodeJson["metadata"]["title"] ?? "";
        String episodeName = "";
        if (isMovie) {
          episodeName = "Movie";
        } else {
          if (seasonName.isNotEmpty) {
            episodeName = "$seasonName - ";
          }
          episodeName += "Episode ${j + 1} ";
          if (episodeTitle.isNotEmpty) {
            episodeName += "- $episodeTitle";
          }
        }
        MChapter episode = MChapter();
        episode.name = episodeName;

        episode.dateUpload =
            "${int.parse(episodeJson["metadata"]["released"] ?? "0") * 1000}";
        episode.url = "/wp-json/kiranime/v1/episode?id=${episodeJson["id"]}";
        episodesList.add(episode);
      }
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}$url"))).body;
    var resJson = substringBefore(
      substringAfterLast(res, "\"players\":"),
      ",\"noplayer\":",
    );
    var streams =
        (json.decode(resJson) as List<Map<String, dynamic>>)
            .where(
              (e) =>
                  (e["type"] == "stream" ? true : false) &&
                  (e["url"] as String).isNotEmpty,
            )
            .toList()
            .where(
              (e) =>
                  language(source.lang).isEmpty ||
                          language(source.lang) == e["language"]
                      ? true
                      : false,
            )
            .toList();
    List<MVideo> videos = [];
    for (var stream in streams) {
      String videoUrl = stream["url"];
      final language = stream["language"];
      final video = await mystreamExtractor(videoUrl, language);
      videos.addAll(video);
    }

    return sortVideos(videos, source.id);
  }

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final document = parseHtml(res);

    for (var element in document.select("div.col-span-1")) {
      MManga anime = MManga();
      anime.name =
          element.selectFirst("div.font-medium.line-clamp-2.mb-3").text;
      anime.link = element.selectFirst("a").getHref;
      anime.imageUrl =
          "${source.baseUrl}${getUrlWithoutDomain(element.selectFirst("img").getSrc)}";
      animeList.add(anime);
    }
    final hasNextPage =
        xpath(
          res,
          '//li/span[@class="page-numbers current"]/parent::li//following-sibling::li/a/@href',
        ).isNotEmpty;
    return MPages(animeList, hasNextPage);
  }

  String language(String lang) {
    final languages = {
      "all": "",
      "bn": "bengali",
      "en": "english",
      "hi": "hindi",
      "ja": "japanese",
      "ml": "malayalam",
      "mr": "marathi",
      "ta": "tamil",
      "te": "telugu",
    };
    return languages[lang] ?? "";
  }

  Future<List<MVideo>> mystreamExtractor(String url, String language) async {
    List<MVideo> videos = [];
    final res = (await client.get(Uri.parse(url))).body;
    final streamCode = substringBefore(
      substringAfter(substringAfter(res, "sniff("), ", \""),
      '"',
    );

    final streamUrl =
        "${substringBefore(url, "/watch")}/m3u8/$streamCode/master.txt?s=1&cache=1";
    final masterPlaylistRes = (await client.get(Uri.parse(streamUrl))).body;

    List<MTrack> audios = [];
    for (var it in substringAfter(
      masterPlaylistRes,
      "#EXT-X-MEDIA:TYPE=AUDIO",
    ).split("#EXT-X-MEDIA:TYPE=AUDIO")) {
      final line = substringBefore(
        substringAfter(it, "#EXT-X-MEDIA:TYPE=AUDIO"),
        "\n",
      );
      final audioUrl = substringBefore(substringAfter(line, "URI=\""), "\"");
      MTrack audio = MTrack();
      audio
        ..label = substringBefore(substringAfter(line, "NAME=\""), "\"")
        ..file = audioUrl;
      audios.add(audio);
    }

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
        ..quality = "[$language] MyStream - $quality"
        ..audios = audios;
      videos.add(video);
    }
    return videos;
  }

  @override
  List<dynamic> getFilterList() {
    return [
      SelectFilter("TypeFilter", "Type", 0, [
        SelectFilterOption("Any", "all"),
        SelectFilterOption("TV", "tv"),
        SelectFilterOption("Movie", "movies"),
      ]),
      SelectFilter("StatusFilter", "Status", 0, [
        SelectFilterOption("Any", "all"),
        SelectFilterOption("Currently Airing", "airing"),
        SelectFilterOption("Finished Airing", "completed"),
      ]),
      SelectFilter("StyleFilter", "Style", 0, [
        SelectFilterOption("Any", "all"),
        SelectFilterOption("Anime", "anime"),
        SelectFilterOption("Cartoon", "cartoon"),
      ]),
      SelectFilter("YearFilter", "Year", 0, [
        SelectFilterOption("Any", "all"),
        SelectFilterOption("2024", "2024"),
        SelectFilterOption("2023", "2023"),
        SelectFilterOption("2022", "2022"),
        SelectFilterOption("2021", "2021"),
        SelectFilterOption("2020", "2020"),
        SelectFilterOption("2019", "2019"),
        SelectFilterOption("2018", "2018"),
        SelectFilterOption("2017", "2017"),
        SelectFilterOption("2016", "2016"),
        SelectFilterOption("2015", "2015"),
        SelectFilterOption("2014", "2014"),
        SelectFilterOption("2013", "2013"),
        SelectFilterOption("2012", "2012"),
        SelectFilterOption("2011", "2011"),
        SelectFilterOption("2010", "2010"),
        SelectFilterOption("2009", "2009"),
        SelectFilterOption("2008", "2008"),
        SelectFilterOption("2007", "2007"),
        SelectFilterOption("2006", "2006"),
        SelectFilterOption("2005", "2005"),
        SelectFilterOption("2004", "2004"),
        SelectFilterOption("2003", "2003"),
        SelectFilterOption("2002", "2002"),
        SelectFilterOption("2001", "2001"),
        SelectFilterOption("2000", "2000"),
        SelectFilterOption("1999", "1999"),
        SelectFilterOption("1998", "1998"),
        SelectFilterOption("1997", "1997"),
        SelectFilterOption("1996", "1996"),
        SelectFilterOption("1995", "1995"),
        SelectFilterOption("1994", "1994"),
        SelectFilterOption("1993", "1993"),
        SelectFilterOption("1992", "1992"),
        SelectFilterOption("1991", "1991"),
        SelectFilterOption("1990", "1990"),
      ]),
      SelectFilter("SortFilter", "Sort", 0, [
        SelectFilterOption("Default", "default"),
        SelectFilterOption("Ascending", "title_a_z"),
        SelectFilterOption("Descending", "title_z_a"),
        SelectFilterOption("Updated", "update"),
        SelectFilterOption("Published", "date"),
        SelectFilterOption("Most Viewed", "viewed"),
        SelectFilterOption("Favourite", "favorite"),
      ]),
      GroupFilter("GenresFilter", "Genres", [
        CheckBoxFilter("Action", "Action"),
        CheckBoxFilter("Adult Cast", "Adult Cast"),
        CheckBoxFilter("Adventure", "Adventure"),
        CheckBoxFilter("Animation", "Animation"),
        CheckBoxFilter("Comedy", "Comedy"),
        CheckBoxFilter("Detective", "Detective"),
        CheckBoxFilter("Drama", "Drama"),
        CheckBoxFilter("Ecchi", "Ecchi"),
        CheckBoxFilter("Family", "Family"),
        CheckBoxFilter("Fantasy", "Fantasy"),
        CheckBoxFilter("Isekai", "Isekai"),
        CheckBoxFilter("Kids", "Kids"),
        CheckBoxFilter("Martial Arts", "Martial Arts"),
        CheckBoxFilter("Mecha", "Mecha"),
        CheckBoxFilter("Military", "Military"),
        CheckBoxFilter("Mystery", "Mystery"),
        CheckBoxFilter("Otaku Culture", "Otaku Culture"),
        CheckBoxFilter("Reality", "Reality"),
        CheckBoxFilter("Romance", "Romance"),
        CheckBoxFilter("School", "School"),
        CheckBoxFilter("Sci-Fi", "Sci-Fi"),
        CheckBoxFilter("Seinen", "Seinen"),
        CheckBoxFilter("Shounen", "Shounen"),
        CheckBoxFilter("Slice of Life", "Slice of Life"),
        CheckBoxFilter("Sports", "Sports"),
        CheckBoxFilter("Super Power", "Super Power"),
        CheckBoxFilter("SuperHero", "SuperHero"),
        CheckBoxFilter("Supernatural", "Supernatural"),
        CheckBoxFilter("TV Movie", "TV Movie"),
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
        valueIndex: 0,
        entries: ["1080p", "720p", "480p", "360p", "240p"],
        entryValues: ["1080", "720", "480", "360", "240"],
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

  String ll(String url) {
    if (url.contains("?")) {
      return "&";
    }
    return "?";
  }
}

AnimeWorldIndia main(MSource source) {
  return AnimeWorldIndia(source: source);
}

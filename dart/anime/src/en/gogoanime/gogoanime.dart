import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class GogoAnime extends MProvider {
  GogoAnime({required this.source});

  MSource source;

  final Client client = Client();

  @override
  String get baseUrl =>
      getPreferenceValue(source.id, "override_baseurl_v${source.id}");

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(Uri.parse("$baseUrl/popular.html?page=$page"))).body;

    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="img"]/a/@href');
    final names = xpath(res, '//*[@class="img"]/a/@title');
    final images = xpath(res, '//*[@class="img"]/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    String url = baseUrl;
    if (baseUrl.toLowerCase().contains("gogo")) {
      url = url + "/?page=$page";
    } else {
      url = url + "/home.html?page=$page";
    }
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    final elements = document.select("div.img a");
    List<MManga> animeList = [];

    for (var element in elements) {
      var anime = MManga();
      anime.name = element.attr("title");
      anime.imageUrl = element.selectFirst("img")?.attr("src") ?? "";
      final slug = substringBefore(element.attr("href"), "-episode-");
      anime.link = "/category/$slug";
      animeList.add(anime);
    }

    return MPages(animeList, true);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String filterStr = "";
    String url = "";

    String genre = "";
    String recent = "";
    String season = "";

    for (var filter in filters) {
      if (filter.type == "SortFilter") {
        final sort = filter.values[filter.state].value;
        filterStr += "&sort=$sort";
      } else if (filter.type == "GenreFilter") {
        final genre = (filter.state as List).where((e) => e.state).toList();
        if (genre.isNotEmpty) {
          for (var st in genre) {
            filterStr += "&genre[]=${st.value}";
          }
        }
      } else if (filter.type == "CountryFilter") {
        final country = (filter.state as List).where((e) => e.state).toList();
        if (country.isNotEmpty) {
          for (var st in country) {
            filterStr += "&country[]=${st.value}";
          }
        }
      } else if (filter.type == "SeasonFilter") {
        final season = (filter.state as List).where((e) => e.state).toList();
        if (season.isNotEmpty) {
          for (var st in season) {
            filterStr += "&season[]=${st.value}";
          }
        }
      } else if (filter.type == "YearFilter") {
        final year = (filter.state as List).where((e) => e.state).toList();
        if (year.isNotEmpty) {
          for (var st in year) {
            filterStr += "&year[]=${st.value}";
          }
        }
      } else if (filter.type == "TypeFilter") {
        final type = (filter.state as List).where((e) => e.state).toList();
        if (type.isNotEmpty) {
          for (var st in type) {
            filterStr += "&type[]=${st.value}";
          }
        }
      } else if (filter.type == "StatusFilter") {
        final status = (filter.state as List).where((e) => e.state).toList();
        if (status.isNotEmpty) {
          for (var st in status) {
            filterStr += "&status[]=${st.value}";
          }
        }
      } else if (filter.type == "LanguageFilter") {
        final language = (filter.state as List).where((e) => e.state).toList();
        if (language.isNotEmpty) {
          for (var st in language) {
            filterStr += "&language[]=${st.value}";
          }
        }
      }
      if (filter.type == "GenreIFilter") {
        genre = filter.values[filter.state].value;
      } else if (filter.type == "RecentFilter") {
        recent = filter.values[filter.state].value;
      } else if (filter.type == "SeasonIFilter") {
        season = filter.values[filter.state].value;
      }
    }
    if (genre.isNotEmpty) {
      url = "$baseUrl/genre/$genre?page=$page";
    } else if (recent.isNotEmpty) {
      url =
          "https://ajax.gogo-load.com/ajax/page-recent-release.html?page=$page&type=$recent";
    } else if (season.isNotEmpty) {
      url = "$baseUrl/$season?page=$page";
    } else {
      url = "$baseUrl/filter.html?keyword=$query$filterStr&page=$page";
    }

    final res = (await client.get(Uri.parse(url))).body;

    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="img"]/a/@href');
    final names = xpath(res, '//*[@class="img"]/a/@title');
    final images = xpath(res, '//*[@class="img"]/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, true);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1},
    ];

    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    MManga anime = MManga();
    final status = xpath(
      res,
      '//*[@class="anime_info_body_bg"]/p[@class="type"][5]/text()',
    ).first.replaceAll("Status: ", "");
    anime.description =
        parseHtml(
          res,
        ).selectFirst("div.anime_info_body_bg > div.description")?.text ??
        "";
    anime.status = parseStatus(status, statusList);
    anime.genre = xpath(
      res,
      '//*[@class="anime_info_body_bg"]/p[@class="type"][3]/text()',
    ).first.replaceAll("Genre: ", "").split(",");

    final id = xpath(res, '//*[@id="movie_id"]/@value').first;
    final urlEp =
        "https://ajax.gogocdn.net/ajax/load-list-episode?ep_start=0&ep_end=4000&id=$id";

    final resEp = (await client.get(Uri.parse(urlEp))).body;

    final epUrls = xpath(resEp, '//*[@id="episode_related"]/li/a/@href');
    final names = xpath(
      resEp,
      '//*[@id="episode_related"]/li/a/div[@class="name"]/text()',
    );
    List<String> episodes = [];

    for (var a in names) {
      episodes.add("Episode ${substringAfterLast(a, ' ')}");
    }
    List<MChapter>? episodesList = [];
    for (var i = 0; i < episodes.length; i++) {
      MChapter episode = MChapter();
      episode.name = episodes[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse("$baseUrl$url"))).body;
    final serverUrls = xpath(
      res,
      '//*[@class="anime_muti_link"]/ul/li/a/@data-video',
    );
    final serverNames = xpath(
      res,
      '//*[@class="anime_muti_link"]/ul/li/@class',
    );
    List<MVideo> videos = [];
    final hosterSelection = preferenceHosterSelection(source.id);
    for (var i = 0; i < serverNames.length; i++) {
      final name = serverNames[i];
      final url = serverUrls[i];
      List<MVideo> a = [];
      if (hosterSelection.contains(name)) {
        if (name.contains("anime")) {
          a = await gogoCdnExtractor(url);
        } else if (name.contains("vidcdn")) {
          a = await gogoCdnExtractor(url);
        } else if (name.contains("doodstream")) {
          a = await doodExtractor(url);
        } else if (name.contains("mp4upload")) {
          a = await mp4UploadExtractor(url, null, "", "");
        } else if (name.contains("filelions")) {
          a = await streamWishExtractor(url, "FileLions");
        } else if (name.contains("streamwish")) {
          a = await streamWishExtractor(url, "StreamWish");
        }
        videos.addAll(a);
      }
    }

    return sortVideos(videos, source.id);
  }

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("Advanced search"),
      GroupFilter("GenreFilter", "Genre", [
        {
          "type": "CheckBox",
          "filter": {"name": "Action", "value": "action"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Adult Cast", "value": "adult-cast"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Adventure", "value": "adventure"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Anthropomorphic", "value": "anthropomorphic"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Avant Garde", "value": "avant-garde"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Boys Love", "value": "shounen-ai"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Cars", "value": "cars"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "CGDCT", "value": "cgdct"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Childcare", "value": "childcare"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Comedy", "value": "comedy"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Comic", "value": "comic"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Crime", "value": "crime"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Crossdressing", "value": "crossdressing"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Delinquents", "value": "delinquents"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Dementia", "value": "dementia"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Demons", "value": "demons"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Detective", "value": "detective"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Drama", "value": "drama"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Dub", "value": "dub"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Ecchi", "value": "ecchi"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Erotica", "value": "erotica"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Family", "value": "family"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Fantasy", "value": "fantasy"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Gag Humor", "value": "gag-humor"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Game", "value": "game"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Gender Bender", "value": "gender-bender"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Gore", "value": "gore"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Gourmet", "value": "gourmet"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Harem", "value": "harem"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Hentai", "value": "hentai"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "High Stakes Game", "value": "high-stakes-game"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Historical", "value": "historical"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Horror", "value": "horror"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Isekai", "value": "isekai"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Iyashikei", "value": "iyashikei"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Josei", "value": "josei"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Kids", "value": "kids"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Magic", "value": "magic"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Magical Sex Shift", "value": "magical-sex-shift"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Mahou Shoujo", "value": "mahou-shoujo"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Martial Arts", "value": "martial-arts"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Mecha", "value": "mecha"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Medical", "value": "medical"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Military", "value": "military"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Music", "value": "music"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Mystery", "value": "mystery"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Mythology", "value": "mythology"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Organized Crime", "value": "organized-crime"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Parody", "value": "parody"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Performing Arts", "value": "performing-arts"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Pets", "value": "pets"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Police", "value": "police"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Psychological", "value": "psychological"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Racing", "value": "racing"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Reincarnation", "value": "reincarnation"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Romance", "value": "romance"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Romantic Subtext", "value": "romantic-subtext"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Samurai", "value": "samurai"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "School", "value": "school"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sci-Fi", "value": "sci-fi"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Seinen", "value": "seinen"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Shoujo", "value": "shoujo"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Shoujo Ai", "value": "shoujo-ai"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Shounen", "value": "shounen"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Showbiz", "value": "showbiz"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Slice of Life", "value": "slice-of-life"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Space", "value": "space"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Sports", "value": "sports"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Strategy Game", "value": "strategy-game"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Super Power", "value": "super-power"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Supernatural", "value": "supernatural"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Survival", "value": "survival"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Suspense", "value": "suspense"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Team Sports", "value": "team-sports"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Thriller", "value": "thriller"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Time Travel", "value": "time-travel"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Vampire", "value": "vampire"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Visual Arts", "value": "visual-arts"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Work Life", "value": "work-life"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Workplace", "value": "workplace"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Yaoi", "value": "yaoi"},
        },
        {
          "type": "CheckBox",
          "filter": {"name": "Yuri", "value": "yuri"},
        },
      ]),
      GroupFilter("CountryFilter", "Country", [
        CheckBoxFilter("China", "5"),
        CheckBoxFilter("Japan", "2"),
      ]),
      GroupFilter("SeasonFilter", "Season", [
        CheckBoxFilter("Fall", "fall"),
        CheckBoxFilter("Summer", "summer"),
        CheckBoxFilter("Spring", "spring"),
        CheckBoxFilter("Winter", "winter"),
      ]),
      GroupFilter("YearFilter", "Year", [
        CheckBoxFilter("2024", "2024"),
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
        CheckBoxFilter("2002", "2002"),
        CheckBoxFilter("2001", "2001"),
        CheckBoxFilter("2000", "2000"),
        CheckBoxFilter("1999", "1999"),
      ]),
      GroupFilter("LanguageFilter", "Language", [
        CheckBoxFilter("Sub & Dub", "subdub"),
        CheckBoxFilter("Sub", "sub"),
        CheckBoxFilter("Dub", "dub"),
      ]),
      GroupFilter("TypeFilter", "Type", [
        CheckBoxFilter("Movie", "3"),
        CheckBoxFilter("TV", "1"),
        CheckBoxFilter("OVA", "26"),
        CheckBoxFilter("ONA", "30"),
        CheckBoxFilter("Special", "2"),
        CheckBoxFilter("Music", "32"),
      ]),
      GroupFilter("StatusFilter", "Status", [
        CheckBoxFilter("Not Yet Aired", "Upcoming"),
        CheckBoxFilter("Ongoing", "Ongoing"),
        CheckBoxFilter("Completed", "Completed"),
      ]),
      SelectFilter("SortFilter", "Sort by", 0, [
        SelectFilterOption("Name A-Z", "title_az"),
        SelectFilterOption("Recently updated", "recently_updated"),
        SelectFilterOption("Recently added", "recently_added"),
        SelectFilterOption("Release date", "release_date"),
      ]),
      SeparatorFilter(),
      HeaderFilter("Select sub-page"),
      HeaderFilter("Note: Ignores search & other filters"),
      SelectFilter("GenreIFilter", "Genre", 0, [
        {
          "type": "SelectOption",
          "filter": {"name": "", "value": ""},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Action", "value": "action"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Adult Cast", "value": "adult-cast"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Adventure", "value": "adventure"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Anthropomorphic", "value": "anthropomorphic"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Avant Garde", "value": "avant-garde"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Boys Love", "value": "shounen-ai"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Cars", "value": "cars"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "CGDCT", "value": "cgdct"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Childcare", "value": "childcare"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Comedy", "value": "comedy"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Comic", "value": "comic"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Crime", "value": "crime"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Crossdressing", "value": "crossdressing"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Delinquents", "value": "delinquents"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Dementia", "value": "dementia"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Demons", "value": "demons"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Detective", "value": "detective"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Drama", "value": "drama"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Dub", "value": "dub"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Ecchi", "value": "ecchi"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Erotica", "value": "erotica"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Family", "value": "family"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Fantasy", "value": "fantasy"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Gag Humor", "value": "gag-humor"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Game", "value": "game"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Gender Bender", "value": "gender-bender"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Gore", "value": "gore"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Gourmet", "value": "gourmet"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Harem", "value": "harem"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Hentai", "value": "hentai"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "High Stakes Game", "value": "high-stakes-game"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Historical", "value": "historical"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Horror", "value": "horror"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Isekai", "value": "isekai"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Iyashikei", "value": "iyashikei"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Josei", "value": "josei"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Kids", "value": "kids"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Magic", "value": "magic"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Magical Sex Shift", "value": "magical-sex-shift"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Mahou Shoujo", "value": "mahou-shoujo"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Martial Arts", "value": "martial-arts"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Mecha", "value": "mecha"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Medical", "value": "medical"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Military", "value": "military"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Music", "value": "music"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Mystery", "value": "mystery"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Mythology", "value": "mythology"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Organized Crime", "value": "organized-crime"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Parody", "value": "parody"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Performing Arts", "value": "performing-arts"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Pets", "value": "pets"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Police", "value": "police"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Psychological", "value": "psychological"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Racing", "value": "racing"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Reincarnation", "value": "reincarnation"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Romance", "value": "romance"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Romantic Subtext", "value": "romantic-subtext"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Samurai", "value": "samurai"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "School", "value": "school"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Sci-Fi", "value": "sci-fi"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Seinen", "value": "seinen"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Shoujo", "value": "shoujo"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Shoujo Ai", "value": "shoujo-ai"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Shounen", "value": "shounen"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Showbiz", "value": "showbiz"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Slice of Life", "value": "slice-of-life"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Space", "value": "space"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Sports", "value": "sports"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Strategy Game", "value": "strategy-game"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Super Power", "value": "super-power"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Supernatural", "value": "supernatural"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Survival", "value": "survival"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Suspense", "value": "suspense"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Team Sports", "value": "team-sports"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Thriller", "value": "thriller"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Time Travel", "value": "time-travel"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Vampire", "value": "vampire"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Visual Arts", "value": "visual-arts"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Work Life", "value": "work-life"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Workplace", "value": "workplace"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Yaoi", "value": "yaoi"},
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Yuri", "value": "yuri"},
        },
      ]),
      SelectFilter("RecentFilter", "Recent", 0, [
        SelectFilterOption("", ""),
        SelectFilterOption("Recent Release", "1"),
        SelectFilterOption("Recent Dub", "2"),
        SelectFilterOption("Recent Chinese", "3"),
      ]),
      SelectFilter("SeasonIFilter", "Season", 0, [
        SelectFilterOption("", ""),
        SelectFilterOption("Latest season", "new-season.html"),
        SelectFilterOption("Summer 2024", "sub-category/summer-2024-anime"),
        SelectFilterOption("Spring 2024", "sub-category/spring-2024-anime"),
        SelectFilterOption("Winter 2024", "sub-category/winter-2024-anime"),
        SelectFilterOption("Summer 2023", "sub-category/summer-2023-anime"),
        SelectFilterOption("Spring 2023", "sub-category/spring-2023-anime"),
        SelectFilterOption("Winter 2023", "sub-category/winter-2023-anime"),
        SelectFilterOption("Fall 2022", "sub-category/fall-2022-anime"),
        SelectFilterOption("Summer 2022", "sub-category/summer-2022-anime"),
        SelectFilterOption("Spring 2022", "sub-category/spring-2022-anime"),
        SelectFilterOption("Winter 2022", "sub-category/winter-2022-anime"),
        SelectFilterOption("Fall 2021", "sub-category/fall-2021-anime"),
        SelectFilterOption("Summer 2021", "sub-category/summer-2021-anime"),
        SelectFilterOption("Spring 2021", "sub-category/spring-2021-anime"),
        SelectFilterOption("Winter 2021", "sub-category/winter-2021-anime"),
        SelectFilterOption("Fall 2020", "sub-category/fall-2020-anime"),
        SelectFilterOption("Summer 2020", "sub-category/summer-2020-anime"),
        SelectFilterOption("Spring 2020", "sub-category/spring-2020-anime"),
        SelectFilterOption("Winter 2020", "sub-category/winter-2020-anime"),
        SelectFilterOption("Fall 2019", "sub-category/fall-2019-anime"),
        SelectFilterOption("Summer 2019", "sub-category/summer-2019-anime"),
        SelectFilterOption("Spring 2019", "sub-category/spring-2019-anime"),
        SelectFilterOption("Winter 2019", "sub-category/winter-2019-anime"),
        SelectFilterOption("Fall 2018", "sub-category/fall-2018-anime"),
        SelectFilterOption("Summer 2018", "sub-category/summer-2018-anime"),
        SelectFilterOption("Spring 2018", "sub-category/spring-2018-anime"),
        SelectFilterOption("Winter 2018", "sub-category/winter-2018-anime"),
        SelectFilterOption("Fall 2017", "sub-category/fall-2017-anime"),
        SelectFilterOption("Summer 2017", "sub-category/summer-2017-anime"),
        SelectFilterOption("Spring 2017", "sub-category/spring-2017-anime"),
        SelectFilterOption("Winter 2017", "sub-category/winter-2017-anime"),
        SelectFilterOption("Fall 2016", "sub-category/fall-2016-anime"),
        SelectFilterOption("Summer 2016", "sub-category/summer-2016-anime"),
        SelectFilterOption("Spring 2016", "sub-category/spring-2016-anime"),
        SelectFilterOption("Winter 2016", "sub-category/winter-2016-anime"),
        SelectFilterOption("Fall 2015", "sub-category/fall-2015-anime"),
        SelectFilterOption("Summer 2015", "sub-category/summer-2015-anime"),
        SelectFilterOption("Spring 2015", "sub-category/spring-2015-anime"),
        SelectFilterOption("Winter 2015", "sub-category/winter-2015-anime"),
        SelectFilterOption("Fall 2014", "sub-category/fall-2014-anime"),
        SelectFilterOption("Summer 2014", "sub-category/summer-2014-anime"),
        SelectFilterOption("Spring 2014", "sub-category/spring-2014-anime"),
        SelectFilterOption("Winter 2014", "sub-category/winter-2014-anime"),
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
        key: "override_baseurl_v${source.id}",
        title: "Override BaseUrl",
        summary:
            "For temporary uses. Updating the extension will erase this setting.",
        value: "https://anitaku.to",
        dialogTitle: "Override BaseUrl",
        dialogMessage: "Default: https://anitaku.to",
        text: "https://anitaku.to",
      ),
      ListPreference(
        key: "preferred_quality",
        title: "Preferred quality",
        summary: "",
        valueIndex: 0,
        entries: ["1080p", "720p", "480p", "360p"],
        entryValues: ["1080", "720", "480", "360"],
      ),
      ListPreference(
        key: "preferred_server",
        title: "Preferred server",
        summary: "",
        valueIndex: 0,
        entries: [
          "Gogostream",
          "Vidstreaming",
          "Doodstream",
          "StreamWish",
          "Mp4upload",
          "FileLions",
        ],
        entryValues: [
          "Gogostream",
          "Vidstreaming",
          "Doodstream",
          "StreamWish",
          "Mp4upload",
          "FileLions",
        ],
      ),
      MultiSelectListPreference(
        key: "hoster_selection",
        title: "Enable/Disable Hosts",
        summary: "",
        entries: [
          "Gogostream",
          "Vidstreaming",
          "Doodstream",
          "StreamWish",
          "Mp4upload",
          "FileLions",
        ],
        entryValues: [
          "vidcdn",
          "anime",
          "doodstream",
          "streamwish",
          "mp4upload",
          "filelions",
        ],
        values: [
          "vidcdn",
          "anime",
          "doodstream",
          "streamwish",
          "mp4upload",
          "filelions",
        ],
      ),
    ];
  }

  List<String> preferenceHosterSelection(int sourceId) {
    return getPreferenceValue(sourceId, "hoster_selection");
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String quality = getPreferenceValue(sourceId, "preferred_quality");
    String server = getPreferenceValue(sourceId, "preferred_server");

    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;
      if (a.quality.contains(quality) && a.quality.contains(server)) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.contains(quality) && b.quality.contains(server)) {
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
}

GogoAnime main(MSource source) {
  return GogoAnime(source: source);
}

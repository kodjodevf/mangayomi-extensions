import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AnimeSaturn extends MProvider {
  AnimeSaturn({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res =
        (await client.get(
          Uri.parse("${source.baseUrl}/animeincorso?page=$page"),
        )).body;

    List<MManga> animeList = [];

    final urls = xpath(
      res,
      '//*[@class="sebox"]/div[@class="msebox"]/div[@class="headsebox"]/div[@class="tisebox"]/h2/a/@href',
    );

    final names = xpath(
      res,
      '//*[@class="sebox"]/div[@class="msebox"]/div[@class="headsebox"]/div[@class="tisebox"]/h2/a/text()',
    );

    final images = xpath(
      res,
      '//*[@class="sebox"]/div[@class="msebox"]/div[@class="bigsebox"]/div/img[@class="attachment-post-thumbnail size-post-thumbnail wp-post-image"]/@src',
    );

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = formatTitle(names[i]);
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    return MPages(animeList, true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(
          Uri.parse("${source.baseUrl}/newest?page=$page"),
        )).body;

    List<MManga> animeList = [];

    final urls = xpath(res, '//*[@class="card mb-4 shadow-sm"]/a/@href');

    final names = xpath(res, '//*[@class="card mb-4 shadow-sm"]/a/@title');

    final images = xpath(
      res,
      '//*[@class="card mb-4 shadow-sm"]/a/img[@class="new-anime"]/@src',
    );

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = formatTitle(names[i]);
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    return MPages(animeList, true);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";

    if (query.isNotEmpty) {
      url = "${source.baseUrl}/animelist?search=$query";
    } else {
      url = "${source.baseUrl}/filter?";
      int variantgenre = 0;
      int variantstate = 0;
      int variantyear = 0;
      for (var filter in filters) {
        if (filter.type == "GenreFilter") {
          final genre = (filter.state as List).where((e) => e.state).toList();
          if (genre.isNotEmpty) {
            for (var st in genre) {
              url += "&categories%5B${variantgenre}%5D=${st.value}";
              variantgenre++;
            }
          }
        } else if (filter.type == "YearList") {
          final years = (filter.state as List).where((e) => e.state).toList();
          if (years.isNotEmpty) {
            for (var st in years) {
              url += "&years%5B${variantyear}%5D=${st.value}";
              variantyear++;
            }
          }
        } else if (filter.type == "StateList") {
          final states = (filter.state as List).where((e) => e.state).toList();
          if (states.isNotEmpty) {
            for (var st in states) {
              url += "&states%5B${variantstate}%5D=${st.value}";
              variantstate++;
            }
          }
        } else if (filter.type == "LangList") {
          final lang = filter.values[filter.state].value;
          if (lang.isNotEmpty) {
            url += "&language%5B0%5D=$lang";
          }
        }
      }
      url += "&page=$page";
    }

    final res = (await client.get(Uri.parse(url))).body;

    List<MManga> animeList = [];
    List<String> urls = [];
    List<String> names = [];
    List<String> images = [];
    if (query.isNotEmpty) {
      urls = xpath(
        res,
        '//*[@class="list-group"]/li[@class="list-group-item bg-dark-as-box-shadow"]/div[@class="item-archivio"]/div[@class="info-archivio"]/h3/a[@class="badge badge-archivio badge-light"]/@href',
      );

      names = xpath(
        res,
        '//*[@class="list-group"]/li[@class="list-group-item bg-dark-as-box-shadow"]/div[@class="item-archivio"]/div[@class="info-archivio"]/h3/a[@class="badge badge-archivio badge-light"]/text()',
      );

      images = xpath(
        res,
        '//*[@class="list-group"]/li[@class="list-group-item bg-dark-as-box-shadow"]/div[@class="item-archivio"]/a/img/@src',
      );
    } else {
      urls = xpath(res, '//*[@class="card mb-4 shadow-sm"]/a/@href');

      names = xpath(res, '//*[@class="card mb-4 shadow-sm"]/a/text()');

      images = xpath(
        res,
        '//*[@class="card mb-4 shadow-sm"]/a/img[@class="new-anime"]/@src',
      );
    }

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = formatTitle(names[i]);
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    return MPages(animeList, query.isEmpty);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"In corso": 0, "Finito": 1},
    ];

    final res = (await client.get(Uri.parse(url))).body;
    MManga anime = MManga();
    final detailsList = xpath(
      res,
      '//div[@class="container shadow rounded bg-dark-as-box mb-3 p-3 w-100 text-white"]/text()',
    );
    if (detailsList.isNotEmpty) {
      final details = detailsList.first;

      anime.status = parseStatus(
        details.substring(
          details.indexOf("Stato:") + 6,
          details.indexOf("Data di uscita:"),
        ),
        statusList,
      );
      anime.author = details.substring(7, details.indexOf("Stato:"));
    }

    final description = xpath(res, '//*[@id="shown-trama"]/text()');
    final descriptionFull = xpath(res, '//*[@id="full-trama"]/text()');
    if (description.isNotEmpty) {
      anime.description = description.first;
    } else {
      anime.description = "";
    }
    if (descriptionFull.isNotEmpty) {
      if (descriptionFull.first.length > anime.description.length) {
        anime.description = descriptionFull.first;
      }
    }

    anime.genre = xpath(
      res,
      '//*[@class="container shadow rounded bg-dark-as-box mb-3 p-3 w-100"]/a/text()',
    );

    final epUrls = xpath(
      res,
      '//*[@class="btn-group episodes-button episodi-link-button"]/a/@href',
    );

    final titles = xpath(
      res,
      '//*[@class="btn-group episodes-button episodi-link-button"]/a/text()',
    );

    List<MChapter>? episodesList = [];
    for (var i = 0; i < epUrls.length; i++) {
      MChapter episode = MChapter();
      episode.name = titles[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse(url))).body;

    final urlVid = xpath(res, '//a[contains(@href,"/watch")]/@href').first;
    final resVid = (await client.get(Uri.parse(urlVid))).body;
    String masterUrl = "";
    if (resVid.contains("jwplayer(")) {
      masterUrl = substringBefore(substringAfter(resVid, "file: \""), "\"");
    } else {
      masterUrl = parseHtml(resVid).selectFirst("source").attr("src");
    }

    List<MVideo> videos = [];
    if (masterUrl.endsWith("playlist.m3u8")) {
      final masterPlaylistRes = (await client.get(Uri.parse(masterUrl))).body;
      for (var it in substringAfter(
        masterPlaylistRes,
        "#EXT-X-STREAM-INF:",
      ).split("#EXT-X-STREAM-INF:")) {
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
          ..quality = quality;
        videos.add(video);
      }
    } else {
      MVideo video = MVideo();
      video
        ..url = masterUrl
        ..originalUrl = masterUrl
        ..quality = "Qualità predefinita";
      videos.add(video);
    }
    return sortVideos(videos, source.id);
  }

  String formatTitle(String titlestring) {
    return titlestring
        .replaceAll("(ITA) ITA", "Dub ITA")
        .replaceAll("(ITA)", "Dub ITA")
        .replaceAll("Sub ITA", "");
  }

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("Ricerca per titolo ignora i filtri e viceversa"),
      GroupFilter("GenreFilter", "Generi", [
        CheckBoxFilter("Arti Marziali", "Arti Marziali"),
        CheckBoxFilter("Avventura", "Avventura"),
        CheckBoxFilter("Azione", "Azione"),
        CheckBoxFilter("Bambini", "Bambini"),
        CheckBoxFilter("Commedia", "Commedia"),
        CheckBoxFilter("Demenziale", "Demenziale"),
        CheckBoxFilter("Demoni", "Demoni"),
        CheckBoxFilter("Drammatico", "Drammatico"),
        CheckBoxFilter("Ecchi", "Ecchi"),
        CheckBoxFilter("Fantasy", "Fantasy"),
        CheckBoxFilter("Gioco", "Gioco"),
        CheckBoxFilter("Harem", "Harem"),
        CheckBoxFilter("Hentai", "Hentai"),
        CheckBoxFilter("Horror", "Horror"),
        CheckBoxFilter("Josei", "Josei"),
        CheckBoxFilter("Magia", "Magia"),
        CheckBoxFilter("Mecha", "Mecha"),
        CheckBoxFilter("Militari", "Militari"),
        CheckBoxFilter("Mistero", "Mistero"),
        CheckBoxFilter("Musicale", "Musicale"),
        CheckBoxFilter("Parodia", "Parodia"),
        CheckBoxFilter("Polizia", "Polizia"),
        CheckBoxFilter("Psicologico", "Psicologico"),
        CheckBoxFilter("Romantico", "Romantico"),
        CheckBoxFilter("Samurai", "Samurai"),
        CheckBoxFilter("Sci-Fi", "Sci-Fi"),
        CheckBoxFilter("Scolastico", "Scolastico"),
        CheckBoxFilter("Seinen", "Seinen"),
        CheckBoxFilter("Sentimentale", "Sentimentale"),
        CheckBoxFilter("Shoujo Ai", "Shoujo Ai"),
        CheckBoxFilter("Shoujo", "Shoujo"),
        CheckBoxFilter("Shounen Ai", "Shounen Ai"),
        CheckBoxFilter("Shounen", "Shounen"),
        CheckBoxFilter("Slice of Life", "Slice of Life"),
        CheckBoxFilter("Soprannaturale", "Soprannaturale"),
        CheckBoxFilter("Spazio", "Spazio"),
        CheckBoxFilter("Sport", "Sport"),
        CheckBoxFilter("Storico", "Storico"),
        CheckBoxFilter("Superpoteri", "Superpoteri"),
        CheckBoxFilter("Thriller", "Thriller"),
        CheckBoxFilter("Vampiri", "Vampiri"),
        CheckBoxFilter("Veicoli", "Veicoli"),
        CheckBoxFilter("Yaoi", "Yaoi"),
        CheckBoxFilter("Yuri", "Yuri"),
      ]),
      GroupFilter("YearList", "Anno di Uscita", [
        for (var i = 1969; i < 2022; i++)
          CheckBoxFilter(i.toString(), i.toString()),
      ]),
      GroupFilter("StateList", "Stato", [
        CheckBoxFilter("In corso", "0"),
        CheckBoxFilter("Finito", "1"),
        CheckBoxFilter("Non rilasciato", "2"),
        CheckBoxFilter("Droppato", "3"),
      ]),
      SelectFilter("LangList", "Lingua", 0, [
        SelectFilterOption("", ""),
        SelectFilterOption("Subbato", "0"),
        SelectFilterOption("Doppiato", "1"),
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
        key: "preferred_quality",
        title: "Qualità preferita",
        summary: "",
        valueIndex: 0,
        entries: ["1080p", "720p", "480p", "360p", "240p", "144p"],
        entryValues: ["1080", "720", "480", "360", "240", "144"],
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
}

AnimeSaturn main(MSource source) {
  return AnimeSaturn(source: source);
}

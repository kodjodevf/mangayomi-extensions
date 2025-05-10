import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AnimeSama extends MProvider {
  AnimeSama({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final doc = (await client.get(Uri.parse("${source.baseUrl}/#$page"))).body;
    final regex = RegExp(
      r"""^\s*carteClassique\(\s*.*?\s*,\s*"(.*?)".*\)""",
      multiLine: true,
    );
    var matches = regex.allMatches(doc).toList();
    List<List<RegExpMatch>> chunks = chunked(matches, 5);
    List<MManga> seasons = [];
    if (page > 0 && page <= chunks.length) {
      for (RegExpMatch match in chunks[page - 1]) {
        seasons.addAll(
          await fetchAnimeSeasons(
            "${source.baseUrl}/catalogue/${match.group(1)}",
          ),
        );
      }
    }
    return MPages(seasons, page < chunks.length);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse(source.baseUrl))).body;
    var document = parseHtml(res);
    final latest =
        document
            .select("h2")
            .where(
              (MElement e) => e.outerHtml.toLowerCase().contains(
                "derniers épisodes ajoutés",
              ),
            )
            .toList();
    final seasonElements =
        (latest.first.parent.nextElementSibling as MElement)
            .select("div")
            .toList();
    List<MManga> seasons = [];
    for (var seasonElement in seasonElements) {
      seasons.addAll(
        await fetchAnimeSeasons(
          (seasonElement as MElement).getElementsByTagName("a").first.getHref,
        ),
      );
    }
    return MPages(seasons, false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    final res =
        (await client.get(
          Uri.parse("${source.baseUrl}/catalogue/listing_all.php"),
        )).body;
    var databaseElements = parseHtml(res).select(".cardListAnime");
    List<MElement> elements = [];
    elements =
        databaseElements
            .where(
              (MElement element) => element
                  .select("h1, p")
                  .any(
                    (MElement e) => e.text.toLowerCase().contains(
                      query.toLowerCase().trim(),
                    ),
                  ),
            )
            .toList();
    for (var filter in filters) {
      if (filter.type == "TypeFilter") {
        final types = (filter.state as List).where((e) => e.state).toList();
        elements =
            elements
                .where(
                  (MElement element) =>
                      types.isEmpty ||
                      types.any((p) => element.className.contains(p.value)),
                )
                .toList();
      } else if (filter.type == "LanguageFilter") {
        final language = (filter.state as List).where((e) => e.state).toList();
        elements =
            elements
                .where(
                  (MElement element) =>
                      language.isEmpty ||
                      language.any((p) => element.className.contains(p.value)),
                )
                .toList();
      } else if (filter.type == "GenreFilter") {
        final included =
            (filter.state as List)
                .where((e) => e.state == 1 ? true : false)
                .toList();
        final excluded =
            (filter.state as List)
                .where((e) => e.state == 2 ? true : false)
                .toList();
        if (included.isNotEmpty) {
          elements =
              elements
                  .where(
                    (MElement element) => included.every(
                      (p) => element.className.contains(p.value),
                    ),
                  )
                  .toList();
        }
        if (excluded.isNotEmpty) {
          elements =
              elements
                  .where(
                    (MElement element) => excluded.every(
                      (p) => element.className.contains(p.value),
                    ),
                  )
                  .toList();
        }
      }
    }
    List<List<MElement>> chunks = chunked(elements, 5);
    if (chunks.isEmpty) return MPages([], false);
    List<MManga> seasons = [];
    for (var seasonElement in chunks[page - 1]) {
      seasons.addAll(
        await fetchAnimeSeasons(
          seasonElement.getElementsByTagName("a").first.getHref,
        ),
      );
    }

    return MPages(seasons, page < chunks.length);
  }

  @override
  Future<MManga> getDetail(String url) async {
    var animeUrl =
        "${source.baseUrl}${substringBeforeLast(getUrlWithoutDomain(url), "/")}";
    var movie = int.tryParse(
      url.split("#").length >= 2 ? url.split("#")[1] : "",
    );
    List<Map<String, dynamic>> playersList = [];
    for (var lang in ["vostfr", "vf"]) {
      final players = await fetchPlayers("$animeUrl/$lang");
      if (players.isNotEmpty) {
        playersList.add({"players": players, "lang": lang});
      }
    }
    int maxLength = 0;
    for (var sublist in playersList) {
      for (var innerList in sublist["players"]) {
        if (innerList.length > maxLength) {
          maxLength = innerList.length;
        }
      }
    }
    List<MChapter>? episodesList = [];
    for (var episodeNumber = 0; episodeNumber < maxLength; episodeNumber++) {
      List<String> langs = [];
      bool isVf = false;
      int iVostfr = 0;
      int iVf = 0;
      List<Map<String, dynamic>> players = [];
      for (var playerList in playersList) {
        for (var player in playerList["players"]) {
          if (player.length > episodeNumber) {
            isVf = playerList["lang"] == "vf";
            if ((isVf && iVf < 2) || (!isVf && iVostfr < 2)) {
              var lang = playerList["lang"];
              if (!langs.contains(lang)) {
                langs.add(lang);
              }
              players.add({"lang": lang, "player": player[episodeNumber]});
              isVf ? iVf++ : iVostfr++;
            }
          }
        }
      }

      MChapter episode = MChapter();
      episode.name = movie == null ? 'Episode ${episodeNumber + 1}' : 'Film';
      episode.scanlator = langs.toSet().toList().join(', ').toUpperCase();
      episode.url = json.encode(players);
      episodesList.add(episode);
    }

    MManga anime = MManga();
    anime.chapters =
        movie == null ? episodesList.reversed.toList() : [episodesList[movie]];
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final players = json.decode(url);
    List<MVideo> videos = [];
    for (var player in players) {
      String lang = (player["lang"] as String).toUpperCase();
      String playerUrl = player["player"];
      List<MVideo> a = [];
      if (playerUrl.contains("sendvid")) {
        a = await sendVidExtractorr(playerUrl, "$lang ");
      } else if (playerUrl.contains("vidmoly")) {
        a = await vidmolyExtractor(playerUrl, lang);
      }
      videos.addAll(a);
    }

    return sortVideos(videos, source.id);
  }

  Future<List<MVideo>> vidmolyExtractor(String url, String lang) async {
    final headers = {'Referer': 'https://vidmoly.to'};
    List<MVideo> videos = [];
    final playListUrlResponse = (await client.get(Uri.parse(url))).body;
    final playlistUrl =
        RegExp(r'file:"(\S+?)"').firstMatch(playListUrlResponse)?.group(1) ??
        "";
    if (playlistUrl.isEmpty) return [];
    final masterPlaylistRes = await client.get(
      Uri.parse(playlistUrl),
      headers: headers,
    );

    if (masterPlaylistRes.statusCode == 200) {
      for (var it in substringAfter(
        masterPlaylistRes.body,
        "#EXT-X-STREAM-INF:",
      ).split("#EXT-X-STREAM-INF:")) {
        final quality =
            "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

        String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

        MVideo video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = "$lang Vidmoly $quality"
          ..headers = headers;
        videos.add(video);
      }
    }

    return videos;
  }

  Future<List<MVideo>> sendVidExtractorr(String url, String prefix) async {
    final res = (await client.get(Uri.parse(url))).body;
    final document = parseHtml(res);
    final masterUrl = document.selectFirst("source#video_source")?.attr("src");
    if (masterUrl == null) return [];
    final masterHeaders = {
      "Accept": "*/*",
      "Host": Uri.parse(masterUrl).host,
      "Origin": "https://${Uri.parse(url).host}",
      "Referer": "https://${Uri.parse(url).host}/",
    };
    List<MVideo> videos = [];
    if (masterUrl.contains(".m3u8")) {
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
        final videoHeaders = {
          "Accept": "*/*",
          "Host": Uri.parse(videoUrl).host,
          "Origin": "https://${Uri.parse(url).host}",
          "Referer": "https://${Uri.parse(url).host}/",
        };
        var video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = prefix + "Sendvid:$quality"
          ..headers = videoHeaders;
        videos.add(video);
      }
    } else {
      var video = MVideo();
      video
        ..url = masterUrl
        ..originalUrl = masterUrl
        ..quality = prefix + "Sendvid:default"
        ..headers = masterHeaders;
      videos.add(video);
    }

    return videos;
  }

  @override
  List<dynamic> getFilterList() {
    return [
      GroupFilter("TypeFilter", "Type", [
        CheckBoxFilter("Anime", "Anime"),
        CheckBoxFilter("Film", "Film"),
        CheckBoxFilter("Autres", "Autres"),
      ]),
      GroupFilter("LanguageFilter", "Langue", [
        CheckBoxFilter("VF", "VF"),
        CheckBoxFilter("VOSTFR", "VOSTFR"),
      ]),
      GroupFilter("GenreFilter", "Genre", [
        TriStateFilter("Action", "Action"),
        TriStateFilter("Aventure", "Aventure"),
        TriStateFilter("Combats", "Combats"),
        TriStateFilter("Comédie", "Comédie"),
        TriStateFilter("Drame", "Drame"),
        TriStateFilter("Ecchi", "Ecchi"),
        TriStateFilter("École", "School-Life"),
        TriStateFilter("Fantaisie", "Fantasy"),
        TriStateFilter("Horreur", "Horreur"),
        TriStateFilter("Isekai", "Isekai"),
        TriStateFilter("Josei", "Josei"),
        TriStateFilter("Mystère", "Mystère"),
        TriStateFilter("Psychologique", "Psychologique"),
        TriStateFilter("Quotidien", "Slice-of-Life"),
        TriStateFilter("Romance", "Romance"),
        TriStateFilter("Seinen", "Seinen"),
        TriStateFilter("Shônen", "Shônen"),
        TriStateFilter("Shôjo", "Shôjo"),
        TriStateFilter("Sports", "Sports"),
        TriStateFilter("Surnaturel", "Surnaturel"),
        TriStateFilter("Tournois", "Tournois"),
        TriStateFilter("Yaoi", "Yaoi"),
        TriStateFilter("Yuri", "Yuri"),
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
        key: "preferred_quality",
        title: "Qualité préférée",
        summary: "",
        valueIndex: 0,
        entries: ["1080p", "720p", "480p", "360p"],
        entryValues: ["1080", "720", "480", "360"],
      ),
      ListPreference(
        key: "voices_preference",
        title: "Préférence des voix",
        summary: "",
        valueIndex: 0,
        entries: ["Préférer VOSTFR", "Préférer VF"],
        entryValues: ["vostfr", "vf"],
      ),
    ];
  }

  Future<List<MManga>> fetchAnimeSeasons(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    var document = parseHtml(res);
    String animeName = document.getElementById("titreOeuvre")?.text ?? "";

    var seasonRegex = RegExp(r'panneauAnime\("(.*?)",\s*"(.*?)"\);');
    var scripts = document
        .select("h2 + p + div > script, h2 + div > script")
        .map((MElement element) => element.text)
        .toList()
        .join("");
    List<MManga> animeList = [];
    List<RegExpMatch> seasonRegexReg = seasonRegex.allMatches(scripts).toList();
    for (var animeIndex = 0; animeIndex < seasonRegexReg.length; animeIndex++) {
      final seasonName = seasonRegexReg[animeIndex].group(1);
      final seasonStem = seasonRegexReg[animeIndex].group(2);
      if (seasonName != "nom" && seasonStem != "url") {
        if (seasonStem.toLowerCase().contains("film")) {
          var moviesUrl = "$url/$seasonStem";
          var movies = await fetchPlayers(moviesUrl);
          if (movies.isNotEmpty) {
            var movieNameRegex = RegExp(
              "^\\s*newSPF\\(\"(.*)\"\\);",
              multiLine: true,
            );
            var moviesDoc = (await client.get(Uri.parse(moviesUrl))).body;
            List<RegExpMatch> matches =
                movieNameRegex.allMatches(moviesDoc).toList();

            for (var i = 0; i < movies.length; i++) {
              var title = "";
              if (animeIndex == 0 && movies.length == 1) {
                title = animeName;
              } else if (matches.length > i) {
                title = "$animeName ${(matches[i]).group(1)}";
              } else if (movies.length == 1) {
                title = "$animeName Film";
              } else {
                title = "$animeName Film ${i + 1}";
              }
              MManga anime = MManga();
              anime.imageUrl = document.getElementById("coverOeuvre")?.getSrc;
              anime.genre = (document.xpathFirst(
                        '//h2[contains(text(),"Genres")]/following-sibling::a/text()',
                      ) ??
                      "")
                  .split(",");
              anime.description =
                  document.xpathFirst(
                    '//h2[contains(text(),"Synopsis")]/following-sibling::p/text()',
                  ) ??
                  "";

              anime.name = title;
              anime.link = "$moviesUrl#$i";
              anime.status = MStatus.completed;
              animeList.add(anime);
            }
          }
        } else {
          MManga anime = MManga();
          anime.imageUrl = document.getElementById("coverOeuvre")?.getSrc;
          anime.genre = (document.xpathFirst(
                    '//h2[contains(text(),"Genres")]/following-sibling::a/text()',
                  ) ??
                  "")
              .split(",");
          anime.description =
              document.xpathFirst(
                '//h2[contains(text(),"Synopsis")]/following-sibling::p/text()',
              ) ??
              "";
          anime.name =
              '$animeName ${substringBefore(seasonName, ',').replaceAll('"', "")}';
          anime.link = "$url/$seasonStem";
          animeList.add(anime);
        }
      }
    }
    return animeList;
  }

  Future<List<List<String>>> fetchPlayers(String url) async {
    var docUrl = "$url/episodes.js";
    List<List<String>> players = [];
    var response = (await client.get(Uri.parse(docUrl))).body;

    if (response == "error") {
      return [];
    }

    var sanitizedDoc = sanitizeEpisodesJs(response);
    for (var i = 1; i <= 8; i++) {
      final numPlayers = getPlayers("eps$i", sanitizedDoc);

      if (numPlayers != null) players.add(numPlayers);
    }

    final asPlayers = getPlayers("epsAS", sanitizedDoc);
    if (asPlayers != null) players.add(asPlayers);

    if (players.isEmpty) return [];
    List<List<String>> finalPlayers = [];
    for (var i = 0; i <= players[0].length; i++) {
      for (var playerList in players) {
        if (playerList.length > i) {
          finalPlayers.add(playerList);
        }
      }
    }
    return finalPlayers.toSet().toList();
  }

  List<String>? getPlayers(String playerName, String doc) {
    var playerRegex = RegExp('$playerName\\s*=\\s*(\\[.*?\\])', dotAll: true);
    var match = playerRegex.firstMatch(doc);
    if (match == null) return null;
    final regex = RegExp(r"""https?://[^\s\',\[\]]+""");
    final matches = regex.allMatches(match.group(1));
    List<String> urls = [];
    for (var match in matches.toList()) {
      urls.add((match as RegExpMatch).group(0).toString());
    }
    return urls;
  }

  String sanitizeEpisodesJs(String doc) {
    return doc.replaceAll(
      RegExp(r'(?<=\[|\,)\s*\"\s*(https?://[^\s\"]+)\s*\"\s*(?=\,|\])'),
      '',
    );
  }

  List<List<dynamic>> chunked(List<dynamic> list, int size) {
    List<List<dynamic>> chunks = [];
    for (int i = 0; i < list.length; i += size) {
      int end = list.length;
      if (i + size < list.length) {
        end = i + size;
      }
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String quality = getPreferenceValue(sourceId, "preferred_quality");
    String voice = getPreferenceValue(sourceId, "voices_preference");

    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;
      if (a.quality.contains(quality) &&
          a.quality.toLowerCase().contains(voice)) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.contains(quality) &&
          b.quality.toLowerCase().contains(voice)) {
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

AnimeSama main(MSource source) {
  return AnimeSama(source: source);
}

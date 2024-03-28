import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AniFlix extends MProvider {
  AniFlix({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final headers = getHeader(source.baseUrl);
    final res = (await client.get(
            Uri.parse("${source.baseUrl}/api/show/new/${page - 1}"),
            headers: headers))
        .body;

    return parseAnimeList(res, true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final headers = getHeader(source.baseUrl);
    final res = (await client.get(
            Uri.parse("${source.baseUrl}/api/show/airing/${page - 1}"),
            headers: headers))
        .body;
    final datas = json.decode(res);
    List<MManga> animeList = [];
    List<String> ids = [];
    for (var data in datas) {
      final anim = data["season"]["show"];
      if (!ids.contains(anim["id"])) {
        ids.add(anim["id"]);
        MManga anime = MManga();
        anime.name = anim["name"];
        anime.imageUrl =
            "${source.baseUrl}/storage/" + (anim["cover_portrait"] ?? "");
        anime.link =
            getUrlWithoutDomain("${source.baseUrl}/api/show/${anim['url']}");
        anime.description = anim["description"];
        if (anim["airing"] == 0) {
          anime.status = MStatus.completed;
        } else if (anim["airing"] == 1) {
          anime.status = MStatus.ongoing;
        }
        animeList.add(anime);
      }
    }
    return MPages(animeList, true);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res = await client.post(
        Uri.parse("${source.baseUrl}/api/show/search"),
        headers: {'Referer': source.baseUrl},
        body: {"search": query});
    return parseAnimeList(res.body, false);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}$url"))).body;
    MManga anime = MManga();
    final jsonRes = json.decode(res);
    anime.name = jsonRes["name"];
    if (jsonRes["cover_portrait"] != null) {
      anime.imageUrl = "${source.baseUrl}/storage/" + jsonRes["cover_portrait"];
    }
    anime.description = jsonRes["description"];
    anime.genre = (jsonRes["genres"] as List<Map<String, dynamic>>)
        .map((e) => e["name"])
        .toList();
    var seasons = jsonRes["seasons"];
    final animeUrl = jsonRes["url"];
    List<MChapter>? episodesList = [];
    for (var season in seasons) {
      List<Map<String, dynamic>> episodes = season["episodes"];
      int page = 1;
      final res = (await client.get(Uri.parse(
              "${source.baseUrl}/api/show/$animeUrl/${season["id"]}/$page")))
          .body;

      bool hasMoreResult =
          (json.decode(res)["episodes"] as List<Map<String, dynamic>>)
              .isNotEmpty;

      while (hasMoreResult) {
        final res = (await client.get(Uri.parse(
                "${source.baseUrl}/api/show/$animeUrl/${season["id"]}/$page")))
            .body;
        final epList =
            json.decode(res)["episodes"] as List<Map<String, dynamic>>;
        page++;
        episodes.addAll(epList);
        hasMoreResult = epList.isNotEmpty;
      }
      for (var episode in episodes) {
        String name = episode["name"] ?? "";
        if (name.toLowerCase().contains("folge") ||
            name.toLowerCase().contains("episode")) {
          name = "";
        } else {
          name = ": $name";
        }
        MChapter ep = MChapter();
        ep.name = "Staffel ${season["number"]} Folge ${episode["number"]}$name";
        ep.url =
            "/api/episode/show/$animeUrl/season/${season["number"]}/episode/${episode["number"]}";
        episodesList.add(ep);
      }
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}$url"),
            headers: getHeader(source.baseUrl)))
        .body;
    final jsonRes = json.decode(res)["streams"];
    List<MVideo> videos = [];
    final hosterSelection = preferenceHosterSelection(source.id);
    for (var stream in jsonRes) {
      List<MVideo> a = [];
      String quality = '${stream["hoster"]["name"]} - ${stream["lang"]}';
      String link = stream["link"];
      if ((link.contains("https://dood") || link.contains("https://d0")) &&
          hosterSelection.contains("doodstream")) {
        a = await doodExtractor(link, quality);
      } else if (link.contains("https://streamtape") &&
          hosterSelection.contains("streamtape")) {
        a = await streamTapeExtractor(link, quality);
      } else if (link.contains("https://voe.sx") &&
          hosterSelection.contains("voe")) {
        a = await voeExtractor(link, quality);
      } else if (link.contains("https://streamlare") &&
          hosterSelection.contains("streamlare")) {
        a = await streamlareExtractor(link, quality, '', '');
      }
      videos.addAll(a);
    }

    return sortVideos(videos, source.id);
  }

  MPages parseAnimeList(String res, bool hasNextPage) {
    final datas = json.decode(res);
    List<MManga> animeList = [];

    for (var data in datas) {
      MManga anime = MManga();
      anime.name = data["name"];
      anime.imageUrl =
          "${source.baseUrl}/storage/" + (data["cover_portrait"] ?? "");
      anime.link =
          getUrlWithoutDomain("${source.baseUrl}/api/show/${data['url']}");
      anime.description = data["description"];
      if (data["airing"] == 0) {
        anime.status = MStatus.completed;
      } else if (data["airing"] == 1) {
        anime.status = MStatus.ongoing;
      }
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage);
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String hoster = getPreferenceValue(sourceId, "preferred_hoster");
    String sub = getPreferenceValue(sourceId, "preferred_sub");
    videos.sort((MVideo a, MVideo b) {
      int hosterMatchA = 0;
      if (a.url.toLowerCase().contains(hoster.toLowerCase()) &&
          a.quality.toLowerCase().contains(sub.toLowerCase())) {
        hosterMatchA = 1;
      }
      int hosterMatchB = 0;
      if (b.url.toLowerCase().contains(hoster.toLowerCase()) &&
          b.quality.toLowerCase().contains(sub.toLowerCase())) {
        hosterMatchB = 1;
      }
      return hosterMatchB - hosterMatchA;
    });
    return videos;
  }

  List<String> preferenceHosterSelection(int sourceId) {
    return getPreferenceValue(sourceId, "hoster_selectionn");
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_hoster",
          title: "Standard-Hoster",
          summary: "",
          valueIndex: 0,
          entries: [
            "Streamtape",
            "Doodstream",
            "Voe",
            "Streamlare"
          ],
          entryValues: [
            "https://streamtape.com",
            "https://dood",
            "https://voe.sx",
            "https://streamlare.com"
          ]),
      ListPreference(
          key: "preferred_sub",
          title: "Standardmäßig Sub oder Dub?",
          summary: "",
          valueIndex: 0,
          entries: ["Sub", "Dub"],
          entryValues: ["Sub", "Dub"]),
      MultiSelectListPreference(
          key: "hoster_selectionn",
          title: "Hoster auswählen",
          summary: "",
          entries: ["Streamtape", "Doodstream", "Voe", "Streamlare"],
          entryValues: ["streamtape", "doodstream", "voe", "streamlare"],
          values: ["streamtape", "doodstream", "voe", "streamlare"]),
    ];
  }
}

Map<String, String> getHeader(String url) {
  return {'Referer': url};
}

AniFlix main(MSource source) {
  return AniFlix(source: source);
}

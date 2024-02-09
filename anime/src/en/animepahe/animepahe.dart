import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';
import 'dart:math';

class AnimePahe extends MProvider {
  AnimePahe(this.source);

  final MSource source;

  final Client client = Client(source);

  @override
  String get baseUrl => getPreferenceValue(source.id, "preferred_domain");

  @override
  Future<MPages> getPopular(int page) async {
    return await getLatestUpdates(page);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(Uri.parse("$baseUrl/api?m=airing&page=$page"))).body;
    final jsonResult = json.decode(res);
    final hasNextPage = jsonResult["current_page"] < jsonResult["last_page"];
    List<MManga> animeList = [];
    for (var item in jsonResult["data"]) {
      MManga anime = MManga();
      anime.name = item["anime_title"];
      anime.imageUrl = item["snapshot"];
      anime.link = "/anime/?anime_id=${item["id"]}&name=${item["anime_title"]}";
      anime.artist = item["fansub"];
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res =
        (await client.get(Uri.parse("$baseUrl/api?m=search&l=8&q=$query")))
            .body;
    final jsonResult = json.decode(res);
    List<MManga> animeList = [];
    for (var item in jsonResult["data"]) {
      MManga anime = MManga();
      anime.name = item["title"];
      anime.imageUrl = item["poster"];
      anime.link = "/anime/?anime_id=${item["id"]}&name=${item["title"]}";
      animeList.add(anime);
    }
    return MPages(animeList, false);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Currently Airing": 0, "Finished Airing": 1}
    ];
    MManga anime = MManga();
    final id = substringBefore(substringAfterLast(url, "?anime_id="), "&name=");
    final name = substringAfterLast(url, "&name=");
    print(name);
    final session = await getSession(name, id);
    print(session);
    final res =
        (await client.get(Uri.parse("$baseUrl/anime/$session?anime_id=$id")))
            .body;
    final document = parseHtml(res);
    final status =
        (document.xpathFirst('//div/p[contains(text(),"Status:")]/text()') ??
                "")
            .replaceAll("Status:\n", "")
            .trim();
    anime.status = parseStatus(status, statusList);

    anime.name = document.selectFirst("div.title-wrapper > h1 > span").text;
    anime.author =
        (document.xpathFirst('//div/p[contains(text(),"Studio:")]/text()') ??
                "")
            .replaceAll("Studio:\n", "")
            .trim();
    anime.imageUrl = document.selectFirst("div.anime-poster a").attr("href");
    anime.genre =
        xpath(res, '//*[contains(@class,"anime-genre")]/ul/li/text()');
    final synonyms =
        (document.xpathFirst('//div/p[contains(text(),"Synonyms:")]/text()') ??
                "")
            .replaceAll("Synonyms:\n", "")
            .trim();
    anime.description = document.selectFirst("div.anime-summary").text;
    if (synonyms.isNotEmpty) {
      anime.description += "\n\n$synonyms";
    }
    final epUrl = "$baseUrl/api?m=release&id=$session&sort=episode_desc&page=1";
    final resEp = (await client.get(Uri.parse(epUrl))).body;
    final episodes = await recursivePages(epUrl, resEp, session);

    anime.chapters = episodes;
    return anime;
  }

  Future<List<MChapter>> recursivePages(
      String url, String res, String session) async {
    final jsonResult = json.decode(res);
    final page = jsonResult["current_page"];
    final hasNextPage = page < jsonResult["last_page"];
    List<MManga> animeList = [];
    for (var item in jsonResult["data"]) {
      MChapter episode = MChapter();
      episode.name = "Episode ${item["episode"]}";
      episode.url = "/play/$session/${item["session"]}";
      episode.dateUpload =
          parseDates([item["created_at"]], "yyyy-MM-dd HH:mm:ss", "en")[0];
      animeList.add(episode);
    }
    if (hasNextPage) {
      final newUrl = "${substringBeforeLast(url, "&page=")}&page=${page + 1}";
      final newRes = (await client.get(Uri.parse(newUrl))).body;
      animeList.addAll(await recursivePages(newUrl, newRes, session));
    }
    return animeList;
  }

  Future<String> getSession(String title, String animeId) async {
    final res =
        (await client.get(Uri.parse("$baseUrl/api?m=search&q=$title"))).body;
    return substringBefore(
        substringAfter(
            substringAfter(res, "\"id\":$animeId"), "\"session\":\""),
        "\"");
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}$url")));

    final document = parseHtml(res.body);
    final buttons = document.select("div#resolutionMenu > button");
    List<MVideo> videos = [];
    for (var i = 0; i < buttons.length; i++) {
      final btn = buttons[i];
      final kwikLink = btn.attr("data-src");
      final quality = btn.text;
      final ress = (await client.get(Uri.parse(kwikLink),
          headers: {"Referer": "https://animepahe.com"}));
      final script = substringAfterLast(
          xpath(ress.body, '//script[contains(text(),"eval(function")]/text()')
              .first,
          "eval(function(");
      final videoUrl = substringBefore(
          substringAfter(unpackJsAndCombine("eval(function($script"), "const source=\\'"),
          "\\';");
      MVideo video = MVideo();
      video
        ..url = videoUrl
        ..originalUrl = videoUrl
        ..quality = quality
        ..headers = {"referer": "https://kwik.cx"};
      videos.add(video);
    }
    return sortVideos(videos);
  }

  List<MVideo> sortVideos(List<MVideo> videos) {
    String quality = getPreferenceValue(source.id, "preferred_quality");

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
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_domain",
          title: "Preferred domain",
          summary: "",
          valueIndex: 1,
          entries: [
            "animepahe.com",
            "animepahe.ru",
            "animepahe.org"
          ],
          entryValues: [
            "https://animepahe.com",
            "https://animepahe.ru",
            "https://animepahe.org"
          ]),
      ListPreference(
          key: "preferred_quality",
          title: "Preferred Quality",
          summary: "",
          valueIndex: 0,
          entries: ["1080p", "720p", "360p"],
          entryValues: ["1080", "720", "360"]),
    ];
  }
}

AnimePahe main(MSource source) {
  return AnimePahe(source);
}

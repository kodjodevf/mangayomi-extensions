import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class UHDMovies extends MProvider {
  UHDMovies({required this.source});

  MSource source;

  final Client client = Client();

  @override
  bool get supportsLatest => false;

  @override
  String get baseUrl => getPreferenceValue(source.id, "pref_domain_new");

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse("$baseUrl/page/$page"))).body;
    return animeFromElement(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    return MPages([], false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res =
        (await client.get(
          Uri.parse("$baseUrl/page/$page/?s=${query.replaceAll(" ", "+")}"),
        )).body;
    return animeFromElement(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse("$baseUrl${url}"))).body;
    MManga anime = MManga();
    final description = xpath(res, '//pre/span/text()');
    if (description.isNotEmpty) {
      anime.description = description.first;
    }
    anime.status = MStatus.ongoing;
    final episodesTitles = xpath(
      res,
      '//*[contains(@style, "center") or contains(@class, "maxbutton")]/a[contains(@class, "maxbutton") or contains(@href, "?sid=")]/text()',
    );
    final episodesUrls = xpath(
      res,
      '//*[contains(@style, "center") or contains(@class, "maxbutton")]/a[contains(@class, "maxbutton") or contains(@href, "?sid=")]/@href',
    );
    bool isSeries = false;
    if (episodesTitles.first.contains("Episode") ||
        episodesTitles.first.contains("Zip") ||
        episodesTitles.first.contains("Pack")) {
      isSeries = true;
    }
    List<MChapter>? episodesList = [];
    if (!isSeries) {
      List<String> moviesTitles = [];
      moviesTitles = xpath(
        res,
        '//*[contains(@style, "center") or contains(@class, "maxbutton")]/parent::p//preceding-sibling::p[contains(@style, "center")]/text()',
      );
      List<String> titles = [];
      if (moviesTitles.isEmpty) {
        moviesTitles = xpath(res, '//p[contains(@style, "center")]/text()');
      }
      for (var title in moviesTitles) {
        if (title.isNotEmpty &&
            !title.contains('Download') &&
            !title.contains('Note:') &&
            !title.contains('Copyright')) {
          titles.add(title.split('[').first.trim());
        }
      }
      for (var i = 0; i < titles.length; i++) {
        final title = titles[i];
        final quality = RegExp(r'\d{3,4}p').firstMatch(title)?.group(0) ?? "";
        final url = episodesUrls[i];
        MChapter ep = MChapter();
        ep.name = title;
        ep.url = url;
        ep.scanlator = quality;
        episodesList.add(ep);
      }
    } else {
      List<String> seasonTitles = [];
      final episodeTitles = xpath(
        res,
        '//*[contains(@style, "center") or contains(@class, "maxbutton")]/parent::p//preceding-sibling::p[contains(@style, "center") and not(text()^="Episode")]/text()',
      );
      List<String> titles = [];
      for (var title in episodeTitles) {
        if (title.isNotEmpty) {
          titles.add(title.split('[').first.trim());
        }
      }
      int number = 0;
      for (var i = 0; i < episodesTitles.length; i++) {
        final episode = episodesTitles[i];
        final episodeUrl = episodesUrls[i];
        if (!episode.contains("Zip") || !episode.contains("Pack")) {
          if (episode == "Episode 1" && seasonTitles.contains("Episode 1")) {
            number++;
          } else if (episode == "Episode 1") {
            seasonTitles.add(episode);
          }
          final season =
              RegExp(r'S(\d{2})').firstMatch(titles[number])?.group(1) ?? "";
          final quality =
              RegExp(r'\d{3,4}p').firstMatch(titles[number])?.group(0) ?? "";
          MChapter ep = MChapter();
          ep.name = "Season $season $episode $quality";
          ep.url = episodeUrl;
          ep.scanlator = quality;
          episodesList.add(ep);
        }
      }
    }
    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = await getMediaUrl(url);
    return await extractVideos(res);
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
        key: "pref_domain_new",
        title: "Currently used domain",
        summary: "",
        value: "https://uhdmovies.fans",
        dialogTitle: "Currently used domain",
        dialogMessage: "",
        text: "https://uhdmovies.fans",
      ),
    ];
  }

  Future<List<MVideo>> extractVideos(String url) async {
    List<MVideo> videos = [];
    for (int type = 1; type < 3; type++) {
      url = url.replaceAll("/file/", "/wfile/") + "?type=$type";
      final res = (await client.get(Uri.parse(url))).body;
      final links = xpath(res, '//div[@class="mb-4"]/a/@href');
      for (int i = 0; i < links.length; i++) {
        final link = links[i];
        String decodedLink = link;
        if (!link.contains("workers.dev")) {
          decodedLink = utf8.decode(
            base64Url.decode(substringAfter(link, "download?url=")),
          );
        }
        MVideo video = MVideo();
        video
          ..url = decodedLink
          ..originalUrl = decodedLink
          ..quality = "CF $type Worker ${i + 1}";
        videos.add(video);
      }
    }
    return videos;
  }

  Future<String> getMediaUrl(String url) async {
    String res = "";
    String host = "";
    if (url.contains("?sid=")) {
      final finalUrl = await redirectorBypasser(url);
      host = Uri.parse(finalUrl).host;
      res = (await client.get(Uri.parse(finalUrl))).body;
    } else if (url.contains("r?key=")) {
      res = (await client.get(Uri.parse(url))).body;
      host = Uri.parse(url).host;
    } else {
      return "";
    }
    final path = substringBefore(substringAfter(res, "replace(\""), "\"");
    if (path == "/404") return "";
    return "https://$host$path";
  }

  Future<String> redirectorBypasser(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    String lastDoc = await recursiveDoc(url, res);
    final js = xpath(lastDoc, '//script[contains(text(), "/?go=")]/text()');
    if (js.isEmpty) return "";
    String script = js.first;
    String nextUrl = substringBefore(
      substringAfter(script, "\"href\",\""),
      '"',
    );
    if (!nextUrl.contains("http")) return "";
    String cookieName = substringAfter(nextUrl, "go=");
    String cookieValue = substringBefore(
      substringAfter(script, "'$cookieName', '"),
      "'",
    );
    final response =
        (await client.get(
          Uri.parse(nextUrl),
          headers: {"referer": url, "Cookie": "$cookieName=$cookieValue"},
        )).body;

    final lastRes = parseHtml(
      response,
    ).selectFirst("meta[http-equiv]").attr("content");
    return substringAfter(lastRes, "url=");
  }

  MPages animeFromElement(String res) {
    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="entry-image"]/a/@href');
    final names = xpath(res, '//*[@class="entry-image"]/a/@title');
    final images = xpath(res, '//*[@class="entry-image"]/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i].replaceAll("Download", "");
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@class="next page-numbers"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  Future<String> recursiveDoc(String url, String html) async {
    final urlR = xpath(html, '//form[@id="landing"]/@action');
    if (urlR.isEmpty) return html;
    final name = xpath(html, '//input/@name').first;
    final value = xpath(html, '//input/@value').first;
    final body = {"$name": value};
    final response =
        (await client.post(
          Uri.parse(urlR.first),
          headers: {"referer": url},
          body: body,
        )).body;
    return recursiveDoc(url, response);
  }
}

UHDMovies main(MSource source) {
  return UHDMovies(source: source);
}

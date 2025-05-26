import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Vumeto extends MProvider {
  Vumeto({required this.source});

  MSource source;

  final Client client = Client();

  @override
  bool get supportsLatest => true;

  @override
  Map<String, String> get headers => {
    "Cookie":
        "_ga=GA1.1.2064759276.1741681027; _ga_5HMNDC3ZE4=GS1.1.1741824276.8.1.1741824749.0.0.0",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
    "Referer": "https://vumeto.com/",
  };

  @override
  Future<MPages> getPopular(int page) async {
    final url = 'https://vumeto.com/most-popular';
    final resp = await client.get(Uri.parse(url));

    final document = parseHtml(resp.body);

    return MPages(scrapeAnimeList(document), false);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final url = 'https://vumeto.com/recently-updated';
    final resp = await client.get(Uri.parse(url));

    final document = parseHtml(resp.body);

    return MPages(scrapeAnimeList(document), false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final url = 'https://vumeto.com/search?q=$query';
    final resp = await client.get(Uri.parse(url));

    final document = parseHtml(resp.body);

    return MPages(scrapeAnimeList(document), false);
  }

  String fixUrl(String encodedUrl) {
    return encodedUrl
        .split('url=')
        .last
        .split('&w')
        .first
        .replaceAll('%3A', ':')
        .replaceAll('%2F', '/')
        .replaceAll('%3F', '?')
        .replaceAll('%3D', '=')
        .replaceAll('%26', '&');
  }

  List<MManga> scrapeAnimeList(MDocument document) {
    List<MElement>? animeElements = document.getElementsByClassName(
      'relative group border-0',
    );
    List<MManga> results = [];

    if (animeElements != null) {
      for (var anime in animeElements) {
        String? title = anime.selectFirst('h3')?.text ?? '';
        String? animeUrl = anime.selectFirst('a')?.attr('href') ?? '';
        String? imageUrl = anime.selectFirst('img')?.attr('src') ?? '';

        MManga manga = MManga();
        manga.name = title;
        manga.link =
            "https://vumeto.com/watch/" +
            animeUrl.replaceAll('/info/', '').split('/').first +
            '?ep=1';
        manga.imageUrl = fixUrl(imageUrl.split('url=').last);

        results.add(manga);
      }
    }
    return results;
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"Releasing": 0, "Finished": 1},
    ];

    final uri = Uri.parse(url);
    final resp = await client.get(uri, headers);
    final document = parseHtml(resp.body);

    final description =
        document.selectFirst("meta[name='description']").attr("content") ?? '';

    MStatus status = MStatus.unknown;
    final statusStart = resp.body.indexOf(
      ":",
      resp.body.indexOf("\\\"status\\\""),
    );
    final statusEnd = resp.body.indexOf("\\\",", statusStart);
    if (statusStart != -1 && statusEnd != -1) {
      final rawStatus = resp.body.substring(statusStart + 1, statusEnd);
      status = parseStatus(rawStatus.replaceAll("\\\"", ""), statusList);
    }

    final genresStart = resp.body.indexOf(
      "[",
      resp.body.indexOf("\\\"genres\\\":"),
    );
    final genresEnd = resp.body.indexOf("]", genresStart);
    var genres = [];
    if (genresStart != -1 && genresEnd != -1) {
      final genreLinks = resp.body
          .substring(genresStart + 1, genresEnd)
          .split(",");
      genres = genreLinks.map((String e) => e.replaceAll("\\\"", "")).toList();
    }

    List<MChapter> chapters = [];
    final scripts = document.getElementsByTagName("script");

    String jsonData = "";
    for (var script in scripts!) {
      if (script.text!.contains("episodesData")) {
        final regex = RegExp(
          r'self\.__next_f\.push\(\[1,".*?",null,(.*?)\]\)',
          dotAll: true,
        );
        final match = regex.firstMatch(script.text!);

        if (match != null && match.groupCount >= 1) {
          String cleaned = match.group(1)!.replaceAll(r'\', '');

          jsonData = cleaned.substring(0, cleaned.length - 3);
          break;
        } else {
          print("Regex did not match.");
        }
      }
    }
    Map<String, dynamic> parsedData = json.decode(jsonData);
    List<dynamic> episodesData = parsedData['episodesData'];
    for (var ep in episodesData) {
      MChapter ch = MChapter();
      final number =
          (ep?['episodeNo'] ?? episodesData.indexOf(ep) + 1).toString();

      ch.name = "Episode $number";

      ch.url = url.split('?').first + '?ep=$number';

      if (!chapters.any((c) => c.name == ch.name)) {
        chapters.add(ch);
      }
    }

    MManga result = MManga();
    result.description = description;
    result.status = status;
    result.genre = genres;
    result.chapters = chapters.reversed.toList();

    return result;
  }

  String stripTags(String htmlString) {
    final RegExp exp = RegExp(
      r'<[^>]*>',
      multiLine: true,
      caseSensitive: false,
    );
    return htmlString.replaceAll(exp, '').trim();
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    try {
      final resp = await client.get(Uri.parse(url), headers);

      final document = parseHtml(resp.body);

      final scripts = document.getElementsByTagName("script");
      if (scripts.isEmpty) {
        print("No <script> tags found.");
        return [];
      }

      String jsonData = "";
      for (var script in scripts) {
        if (script.text.contains("episodesData")) {
          final regex = RegExp(
            r'self\.__next_f\.push\(\[1,".*?",null,(.*?)\]\)',
            dotAll: true,
          );
          final match = regex.firstMatch(script.text);
          if (match != null && match.groupCount >= 1) {
            String cleaned = match.group(1)!.replaceAll(r'\', '');
            jsonData = cleaned.substring(0, cleaned.length - 3);
            break;
          }
        }
      }

      if (jsonData.isEmpty) {
        print("Could not find video data in any script tag.");
        return [];
      }

      final Map<String, dynamic> parsedData = json.decode(jsonData);
      final List<dynamic> episodesData = parsedData['episodesData'];

      List<Map<String, dynamic>> extractedData = [];

      if (episodesData.isNotEmpty) {
        final index = int.parse(url.split('ep=').last);
        final episode = episodesData[index - 1];

        for (var sub in episode['sub']) {
          for (var source in sub['sources']) {
            String quality = "AUTO";
            if (stringContains(sub['serverName'], 'Kiwi')) {
              quality = '${source['quality'].toString()}P';
            }
            final String serverName =
                "${sub['serverName']}- SUB - ${quality ?? "AUTO"}";
            final String m3u8Url = source['url'];

            List<Map<String, dynamic>> subtitles = [];
            for (var track in sub['tracks'] ?? []) {
              if (track['kind'] == "captions") {
                final String label =
                    (track['label'] is String)
                        ? track['label'].toString()
                        : 'Unknown';
                subtitles.add({
                  'url': track['file'],
                  'default': track['default'] == true,
                  "label": label,
                });
              }
            }

            if (source['isProxy'] == true || source['isProxy'] == 'true') {
              m3u8Url = 'https://proxy.vumeto.com/fetch?url=' + m3u8Url;
            }

            extractedData.add({
              'serverName': serverName,
              'm3u8Url': m3u8Url,
              'subtitles': subtitles,
            });
          }
        }

        for (var dub in episode['dub']) {
          for (var source in dub['sources']) {
            String quality = 'AUTO';
            if (stringContains(dub['serverName'], 'Kiwi')) {
              quality = '${source['quality'].toString()}P';
            }
            final String serverName =
                "${dub['serverName']}- DUB - ${quality ?? "AUTO"}";
            final String m3u8Url = source['url'];

            List<Map<String, dynamic>> subtitles = [];
            if (source['isProxy'] == true || source['isProxy'] == 'true') {
              m3u8Url = 'https://proxy.vumeto.com/fetch?url=' + m3u8Url;
            }
            extractedData.add({
              'serverName': serverName,
              'm3u8Url': m3u8Url,
              'subtitles': subtitles,
            });
          }
        }
      }
      List<MVideo> data =
          extractedData.map((videoData) {
            MVideo video = MVideo();

            video.url = videoData['m3u8Url'] ?? '';
            video.url = video.url.replaceAll(
              RegExp(r'\b[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.net\b'),
              'stormywind74.xyz',
            );
            video.quality = videoData['serverName'] ?? '';
            video.originalUrl = videoData['m3u8Url'] ?? '';

            List<MTrack>? subtitles =
                (videoData['subtitles'] as List<dynamic>?)?.map((subtitle) {
                  MTrack track = MTrack();
                  return track
                    ..file = subtitle['url'] ?? ''
                    ..label = subtitle['label'];
                }).toList();

            video.subtitles = subtitles;

            return video;
          }).toList();

      return data;
    } catch (e) {
      print("Error in getVideoList: $e");
      return [];
    }
  }

  bool stringContains(String text, String search) {
    return RegExp(search, caseSensitive: false).hasMatch(text);
  }

  @override
  List<dynamic> getFilterList() {
    // TODO: implement
  }

  @override
  List<dynamic> getSourcePreferences() {
    // TODO: implement
  }
}

Vumeto main(MSource source) {
  return Vumeto(source: source);
}

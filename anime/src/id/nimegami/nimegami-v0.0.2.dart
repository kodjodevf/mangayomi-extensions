import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class NimeGami extends MProvider {
  NimeGami();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/page/$page"};
    final res = await http('GET', json.encode(data));
    List<MManga> animeList = [];
    final urls = xpath(res, '//div[@class="wrapper-2-a"]/article/a/@href');
    final names = xpath(res, '//div[@class="wrapper-2-a"]/article/a/@title');
    final images =
        xpath(res, '//div[@class="wrapper-2-a"]/article/a/div/img/@src');

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
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/page/$page"};
    final res = await http('GET', json.encode(data));
    List<MManga> animeList = [];
    final urls = xpath(res, '//div[@class="post-article"]/article/div/a/@href');
    final names =
        xpath(res, '//div[@class="post-article"]/article/div/a/@title');
    final images =
        xpath(res, '//div[@class="post-article"]/article/div/a/img/@src');

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
  Future<MPages> search(MSource source, String query, int page) async {
    final data = {
      "url": "${source.baseUrl}/page/$page/?s=$query&post_type=post"
    };
    final res = await http('GET', json.encode(data));
    List<MManga> animeList = [];
    final urls = xpath(res, '//div[@class="archive-a"]/article/div/a/@href');
    final names = xpath(res, '//div[@class="archive-a"]/article/h2/a/@title');
    final images =
        xpath(res, '//div[@class="archive-a"]/article/div/a/img/@src');

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
  Future<MManga> getDetail(MSource source, String url) async {
    final data = {"url": url};
    final res = await http('GET', json.encode(data));
    MManga anime = MManga();
    final description = xpath(res, '//*[@id="Sinopsis"]/p/text()');
    if (description.isNotEmpty) {
      anime.description = description.first;
    }

    final author = xpath(res, '//tbody/tr[5]/td[2]/text()');
    if (author.isNotEmpty) {
      anime.author = author.first;
    }
    anime.genre = xpath(res, '//tr/td[@class="info_a"]/a/text()');
    final epUrls = xpath(res, '//div[@class="list_eps_stream"]/li/@data')
        .reversed
        .toList();
    final epNums =
        xpath(res, '//div[@class="list_eps_stream"]/li/@id').reversed.toList();
    final names = xpath(res, '//div[@class="list_eps_stream"]/li/text()')
        .reversed
        .toList();
    List<MChapter>? episodesList = [];
    for (var i = 0; i < epUrls.length; i++) {
      MChapter episode = MChapter();
      episode.name = names[i];
      episode.url = json.encode({
        "episodeIndex": int.parse(substringAfterLast(epNums[i], '_')),
        'urls': json.decode(utf8.decode(base64Url.decode(epUrls[i])))
      });
      episodesList.add(episode);
    }
    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    final resJson = json.decode(url);
    final urls = resJson["urls"];
    List<MVideo> videos = [];
    List<MVideo> a = [];
    for (var data in urls) {
      final quality = data["format"];
      for (var url in data["url"]) {
        a = await extractVideos(quality, url);
        videos.addAll(a);
      }
    }
    return videos;
  }

  Future<List<MVideo>> extractVideos(String quality, String url) async {
    List<MVideo> videos = [];
    List<MVideo> a = [];
    if (url.contains("video.nimegami.id")) {
      final realUrl = utf8.decode(
          base64Url.decode(substringBefore(substringAfter(url, "url="), "&")));
      final a = await extractHXFileVideos(realUrl, quality);
      videos.addAll(a);
    } else if (url.contains("berkasdrive") || url.contains("drive.nimegami")) {
      final res = await http('GET', json.encode({"url": url}));
      final source = xpath(res, '//source/@src');
      if (source.isNotEmpty) {
        videos.add(toVideo(source.first, "Berkasdrive - $quality"));
      }
    } else if (url.contains("hxfile.co")) {
      final a = await extractHXFileVideos(url, quality);
      videos.addAll(a);
    }

    return videos;
  }

  Future<List<MVideo>> extractHXFileVideos(String url, String quality) async {
    if (!url.contains("embed-")) {
      url = url.replaceAll(".co/", ".co/embed-") + ".html";
    }
    final res = await http('GET', json.encode({"url": url}));
    final script = xpath(res,
        '//script[contains(text(), "eval") and contains(text(), "p,a,c,k,e,d")]/text()');
    if (script.isNotEmpty) {
      final videoUrl = substringBefore(
          substringAfter(substringAfter(evalJs(script.first), "sources:[", ""),
              "file\":\"", ""),
          '"');
      if (videoUrl.isNotEmpty) {
        return [toVideo(videoUrl, "HXFile - $quality")];
      }
    }

    return [];
  }

  MVideo toVideo(String videoUrl, String quality) {
    MVideo video = MVideo();
    video
      ..url = videoUrl
      ..originalUrl = videoUrl
      ..quality = quality
      ..subtitles = [];

    return video;
  }
}

NimeGami main() {
  return NimeGami();
}

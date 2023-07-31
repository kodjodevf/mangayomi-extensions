import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/liste-des-animes-2/",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(
          res,
          '//*[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/@href',
          '._')
      .split('._');

  anime.names = MBridge.xpath(
          res,
          '//*[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/text()',
          '._')
      .split('._');

  anime.images = [];

  return anime;
}

getAnimeDetail(MangaModel anime) async {
  final url = anime.link;
  final data = {"url": url, "headers": null};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  anime.description = MBridge.xpath(res,
      '//*[@class="entry-content"]/p[contains(text(),"Synopsis")]/text()', '');

  anime.status = 5;

  final urls = MBridge.xpath(
      res,
      '//*[@class="entry-content"]/ul[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/@href',
      '._');
  final names = MBridge.xpath(
      res,
      '//*[@class="entry-content"]/ul[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/text()',
      '._');
  if (urls.isEmpty && names.isEmpty) {
    anime.urls = [anime.link];
    anime.names = ["Film"];
  } else {
    anime.urls = urls.split('._');
    anime.names = names.split('._');
  }

  anime.chaptersDateUploads = [];
  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/page/${anime.page}/",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(
          res,
          '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@href',
          '._')
      .split('._');
  anime.names = MBridge.xpath(
          res,
          '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@title',
          '._')
      .split('._');
  anime.images = [];
  return anime;
}

getVideoList(MangaModel anime) async {
  final datas = {
    "url": anime.link,
    "headers": null,
    "sourceId": anime.sourceId
  };

  final res = await MBridge.http(json.encode(datas), 0);

  if (res.isEmpty) {
    return [];
  }

  final serverUrls = MBridge.xpath(
          res, '//*[@class="entry-content"]/div/div/iframe/@src', '._')
      .split("._");
  List<VideoModel> videos = [];
  for (var i = 0; i < serverUrls.length; i++) {
    final url = MBridge.listParse(serverUrls, 0)[i].toString();
    print(url);
    List<VideoModel> a = [];
    if (url.startsWith("https://filemoon.")) {
    } else if (url.startsWith("https://doodstream.")) {
      a = await MBridge.doodExtractor(url);
    } else if (url.startsWith("https://streamtape.")) {
      a = await MBridge.streamTapeExtractor(url);
    } else if (url.contains("streamsb")) {}
    for (var vi in a) {
      videos.add(vi);
    }
  }

  return videos;
}

searchAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/liste-des-animes-2/",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  final dataMovies = {
    "url": "${anime.baseUrl}/films-mangas/",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final resMovies = await MBridge.http(json.encode(dataMovies), 0);
  List<String> urlsS = [];
  List<String> namesS = [];
  List<String> urls = MBridge.xpath(
          res,
          '//*[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/@href',
          '._')
      .split('._');

  List<String> names = MBridge.xpath(
          res,
          '//*[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/text()',
          '._')
      .split('._');
  List<String> urlsMovies = MBridge.xpath(
          resMovies,
          '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@href',
          '._')
      .split('._');

  List<String> namesMovies = MBridge.xpath(
          resMovies,
          '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@title',
          '._')
      .split('._');
  for (var i = 0; i < names.length; i++) {
    String name = MBridge.listParse(names, 0)[i];
    if (name.toLowerCase().contains(anime.query)) {
      String url = MBridge.listParse(urls, 0)[i];
      urlsS.add(url);
      namesS.add(name);
    }
  }
  for (var i = 0; i < namesMovies.length; i++) {
    String name = MBridge.listParse(namesMovies, 0)[i];
    if (name.toLowerCase().contains(anime.query)) {
      String url = MBridge.listParse(urlsMovies, 0)[i];
      urlsS.add(url);
      namesS.add(name);
    }
  }
  anime.urls = urlsS;

  anime.names = namesS;
  anime.images = [];

  return anime;
}

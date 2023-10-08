import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getVideoList(MangaModel anime) async {
  final datas = {"url": anime.link};

  final res = await MBridge.http('GET', json.encode(datas));

  if (res.isEmpty) {
    return [];
  }

  final serverUrls =
      MBridge.xpath(res, '//*[@class="entry-content"]/div/div/iframe/@src');
  List<VideoModel> videos = [];
  for (var i = 0; i < serverUrls.length; i++) {
    final url = serverUrls[i];
    print(url);
    List<VideoModel> a = [];
    if (url.startsWith("https://filemoon.")) {
      a = await MBridge.filemoonExtractor(url, "");
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

Future<MangaModel> getLatestUpdatesAnime(MangaModel anime) async {
  final data = {"url": "${anime.baseUrl}/page/${anime.page}/"};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(
      res, '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@href');
  anime.names = MBridge.xpath(
      res, '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@title');
  anime.images = [];
  return anime;
}

getAnimeDetail(MangaModel anime) async {
  final url = anime.link;
  final data = {"url": url};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.description = MBridge.xpath(res,
          '//*[@class="entry-content"]/p[contains(text(),"Synopsis")]/text()')
      .first;

  anime.status = 5;

  final urls = MBridge.xpath(res,
      '//*[@class="entry-content"]/ul[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/@href');
  final names = MBridge.xpath(res,
      '//*[@class="entry-content"]/ul[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/text()');
  if (urls.isEmpty && names.isEmpty) {
    anime.urls = [anime.link];
    anime.names = ["Film"];
  } else {
    anime.urls = urls;
    anime.names = names;
  }

  anime.chaptersDateUploads = [];
  return anime;
}

getPopularAnime(MangaModel anime) async {
  return await getLatestUpdatesAnime(anime);
}

searchAnime(MangaModel anime) async {
  final data = {"url": "${anime.baseUrl}/liste-des-animes-2/"};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }

  final dataMovies = {"url": "${anime.baseUrl}/films-mangas/"};
  final resMovies = await MBridge.http('GET', json.encode(dataMovies));
  List<String> urlsS = [];
  List<String> namesS = [];
  final urls = MBridge.xpath(res,
      '//*[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/@href');

  final names = MBridge.xpath(res,
      '//*[@class="lcp_catlist" and contains(@id,"lcp_instance_")]/li/a/text()');
  final urlsMovies = MBridge.xpath(resMovies,
      '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@href');

  final namesMovies = MBridge.xpath(resMovies,
      '//*[@class="recent-posts"]/li/div[@class="post-thumb"]/a/@title');
  for (var i = 0; i < names.length; i++) {
    final name = names[i];
    if (name.toLowerCase().contains(anime.query)) {
      final url = urls[i];
      urlsS.add(url);
      namesS.add(name);
    }
  }
  for (var i = 0; i < namesMovies.length; i++) {
    final name = namesMovies[i];
    if (name.toLowerCase().contains(anime.query)) {
      final url = urlsMovies[i];
      urlsS.add(url);
      namesS.add(name);
    }
  }
  anime.urls = urlsS;

  anime.names = namesS;
  anime.images = [];

  return anime;
}

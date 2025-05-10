import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AnimesUltra extends MProvider {
  AnimesUltra({required this.source});

  MSource source;

  final Client client = Client();

  @override
  String get baseUrl => source.baseUrl;

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(baseUrl))).body;

    List<MManga> animeList = [];
    final urls = xpath(
      res,
      '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/@href',
    );
    final names = xpath(
      res,
      '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@title',
    );
    final images = xpath(
      res,
      '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@data-src',
    );

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, false);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse(baseUrl))).body;

    List<MManga> animeList = [];
    final urls = xpath(
      res,
      '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@href',
    );
    final names = xpath(
      res,
      '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@title',
    );
    final images = xpath(
      res,
      '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/img/@data-src',
    );

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    query = query.trim().replaceAll(" ", "+");
    final res =
        (await client.get(
          Uri.parse(
            "$baseUrl/index.php?do=search&subaction=search&story=$query",
          ),
        )).body;

    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="film-poster"]/a/@href');
    final names = xpath(res, '//*[@class="film-poster"]/a/@title');
    final images = xpath(res, '//*[@class="film-poster"]/img/@data-src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList.reversed.toList(), false);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"En cours": 0, "Terminé": 1},
    ];

    final res = (await client.get(Uri.parse(url))).body;
    var anime = MManga();
    final doc = parseHtml(res);
    anime.description =
        xpath(res, '//*[@class="film-description m-hide"]/text()').first;

    final status =
        xpath(
          res,
          '//*[@class="item item-title" and contains(text(),"Status:")]/span[2]/text()',
        ).first;
    anime.status = parseStatus(status, statusList);
    anime.genre = xpath(
      res,
      '//*[@class="item item-list" and contains(text(),"Genres:")]/a/text()',
    );
    anime.author = doc.xpathFirst(
      '//*[@class="item item-title" and contains(text(),"Studio:")]/span[2]/text()',
    );
    final episodesLength = int.parse(
      substringBefore(
        doc.xpathFirst('//*[@class="film-stats"]/span[7]/text()'),
        "/",
      ).replaceAll("Ep", ""),
    );
    List<MChapter>? episodesList = [];

    for (var i = 0; i < episodesLength; i++) {
      var episode = MChapter();
      episode.name = "Episode ${i + 1}";
      episode.url = url.replaceAll('.html', '/episode-${i + 1}.html');
      episodesList.add(episode);
    }
    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final resHtml = (await client.get(Uri.parse(url))).body;
    final id = url.split('/')[4].split('-')[0];
    final resServer =
        (await client.get(
          Uri.parse("$baseUrl/engine/ajax/full-story.php?newsId=$id"),
        )).body;

    final serverIds = xpath(
      resHtml,
      '//*[@class="ps__-list"]/div/@data-server-id',
    );
    final serverNames = xpath(resHtml, '//*[@class="ps__-list"]/div/a/text()');
    List<String> serverUrls = [];
    for (var id in serverIds) {
      final serversUrls =
          xpath(
            jsonDecode(resServer)["html"],
            '//*[@id="content_player_${id}"]/text()',
          ).first;
      serverUrls.add(serversUrls);
    }
    List<MVideo> videos = [];
    for (var i = 0; i < serverNames.length; i++) {
      final name = serverNames[i];
      final url = serverUrls[i];
      List<MVideo> a = [];
      if (name.contains("Sendvid")) {
        a = await sendVidExtractorr(
          url.replaceAll("https:////", "https://"),
          "",
        );
      } else if (name.contains("Sibnet")) {
        a = await sibnetExtractor(
          "https://video.sibnet.ru/shell.php?videoid=$url",
        );
      } else if (name.contains("Mytv")) {
        a = await myTvExtractor("https://www.myvi.tv/embed/$url");
      } else if (name.contains("Fmoon")) {
        a = await filemoonExtractor(url, "", "");
      }
      videos.addAll(a);
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
}

AnimesUltra main(MSource source) {
  return AnimesUltra(source: source);
}

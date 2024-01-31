import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class AnimesUltra extends MProvider {
  AnimesUltra({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(source.baseUrl))).body;

    List<MManga> animeList = [];
    final urls = xpath(res,
        '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/@href');
    final names = xpath(res,
        '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@title');
    final images = xpath(res,
        '//*[contains(@class,"swiper-slide item-qtip")]/div[@class="item"]/a/img/@data-src');

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
    final res = (await client.get(Uri.parse(source.baseUrl))).body;

    List<MManga> animeList = [];
    final urls = xpath(res,
        '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@href');
    final names = xpath(res,
        '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/a/@title');
    final images = xpath(res,
        '//*[@class="block_area block_area_home"]/div[@class="tab-content"]/div[contains(@class,"block_area-content block_area-list")]/div[@class="film_list-wrap"]/div[@class="flw-item"]/div[@class="film-poster"]/img/@data-src');

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
    final res = (await client.get(Uri.parse(source.baseUrl))).body;

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

    return MPages(animeList, false);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"En cours": 0, "Terminé": 1}
    ];

    final res = (await client.get(Uri.parse(url))).body;
    MManga anime = MManga();
    anime.description =
        xpath(res, '//*[@class="film-description m-hide"]/text()').first;

    final status = xpath(res,
            '//*[@class="item item-title" and contains(text(),"Status:")]/span[2]/text()')
        .first;
    anime.status = parseStatus(status, statusList);
    anime.genre = xpath(res,
        '//*[@class="item item-list" and contains(text(),"Genres:")]/a/text()');
    anime.author = xpath(res,
            '//*[@class="item item-title" and contains(text(),"Studio:")]/span[2]/text()')
        .first;
    final urlEp = url.replaceAll('.html', '/episode-1.html');
    final resEpWebview =
        await getHtmlViaWebview(urlEp, '//*[@class="ss-list"]/a/@href');
    final epUrls =
        xpath(resEpWebview, '//*[@class="ss-list"]/a/@href').reversed.toList();
    final names = xpath(resEpWebview,
            '//*[@class="ss-list"]/a/div[@class="ssli-detail"]/div/text()')
        .reversed
        .toList();

    List<MChapter>? episodesList = [];
    for (var i = 0; i < names.length; i++) {
      MChapter episode = MChapter();
      episode.name = names[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final resWebview = await getHtmlViaWebview(
        url, '//*[@class="ps__-list"]/div/@data-server-id');

    final serverIds =
        xpath(resWebview, '//*[@class="ps__-list"]/div/@data-server-id');
    final serverNames =
        xpath(resWebview, '//*[@class="ps__-list"]/div/a/text()');
    List<String> serverUrls = [];
    for (var id in serverIds) {
      final serversUrls =
          xpath(resWebview, '//*[@id="content_player_${id}"]/text()').first;
      serverUrls.add(serversUrls);
    }
    List<MVideo> videos = [];
    for (var i = 0; i < serverNames.length; i++) {
      final name = serverNames[i];
      final url = serverUrls[i];

      List<MVideo> a = [];
      if (name.contains("Sendvid")) {
        a = await sendVidExtractor(url.replaceAll("https:////", "https://"),
            json.encode({"Referer": "${source.baseUrl}/"}), "");
      } else if (name.contains("Sibnet")) {
        a = await sibnetExtractor(
            "https://video.sibnet.ru/shell.php?videoid=$url");
      } else if (name.contains("Mytv")) {
        a = await myTvExtractor("https://www.myvi.tv/embed/$url");
      }
      videos.addAll(a);
    }

    return videos;
  }
}

AnimesUltra main(MSource source) {
  return AnimesUltra(source: source);
}

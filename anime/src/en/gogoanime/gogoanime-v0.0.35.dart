import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class GogoAnime extends MSourceProvider {
  GogoAnime();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final data = {"url": "${sourceInfo.baseUrl}/popular.html?page=$page"};
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res, '//*[@class="img"]/a/@href');
    final names = MBridge.xpath(res, '//*[@class="img"]/a/@title');
    final images = MBridge.xpath(res, '//*[@class="img"]/a/img/@src');

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
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final data = {
      "url":
          "https://ajax.gogo-load.com/ajax/page-recent-release-ongoing.html?page=$page&type=1"
    };
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(
        res, '//*[@class="added_series_body popular"]/ul/li/a[1]/@href');
    final names = MBridge.xpath(
        res, '//*[//*[@class="added_series_body popular"]/ul/li/a[1]/@title');
    List<String> images = [];
    List<String> imagess = MBridge.xpath(res,
        '//*[//*[@class="added_series_body popular"]/ul/li/a/div[@class="thumbnail-popular"]/@style');
    for (var url in imagess) {
      images.add(url.replaceAll("background: url('", "").replaceAll("');", ""));
    }

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
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final data = {
      "url": "${sourceInfo.baseUrl}/search.html?keyword=$query&page=$page"
    };
    final res = await MBridge.http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = MBridge.xpath(res, '//*[@class="img"]/a/@href');
    final names = MBridge.xpath(res, '//*[@class="img"]/a/@title');
    final images = MBridge.xpath(res, '//*[@class="img"]/a/img/@src');

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
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {
        "Ongoing": 0,
        "Completed": 1,
      }
    ];
    final data = {"url": "${sourceInfo.baseUrl}$url"};
    final res = await MBridge.http('GET', json.encode(data));
    MManga anime = MManga();
    final status = MBridge.xpath(
            res, '//*[@class="anime_info_body_bg"]/p[@class="type"][5]/text()')
        .first
        .replaceAll("Status: ", "");
    anime.description = MBridge.xpath(
            res, '//*[@class="anime_info_body_bg"]/p[@class="type"][2]/text()')
        .first
        .replaceAll("Plot Summary: ", "");
    anime.status = MBridge.parseStatus(status, statusList);
    anime.genre = MBridge.xpath(
            res, '//*[@class="anime_info_body_bg"]/p[@class="type"][3]/text()')
        .first
        .replaceAll("Genre: ", "")
        .split(",");

    final id = MBridge.xpath(res, '//*[@id="movie_id"]/@value').first;
    final urlEp =
        "https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=4000&id=$id";
    final dataEp = {"url": urlEp};
    final resEp = await MBridge.http('GET', json.encode(dataEp));

    final epUrls =
        MBridge.xpath(resEp, '//*[@id="episode_related"]/li/a/@href');
    final names = MBridge.xpath(
        resEp, '//*[@id="episode_related"]/li/a/div[@class="name"]/text()');
    List<String> episodes = [];

    for (var a in names) {
      episodes.add("Episode ${MBridge.substringAfterLast(a, ' ')}");
    }
    List<MChapter>? episodesList = [];
    for (var i = 0; i < episodes.length; i++) {
      MChapter episode = MChapter();
      episode.name = episodes[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    final datas = {"url": "${sourceInfo.baseUrl}$url"};

    final res = await MBridge.http('GET', json.encode(datas));
    final serverUrls =
        MBridge.xpath(res, '//*[@class="anime_muti_link"]/ul/li/a/@data-video');
    final classNames =
        MBridge.xpath(res, '//*[@class="anime_muti_link"]/ul/li/@class');
    List<MVideo> videos = [];
    for (var i = 0; i < classNames.length; i++) {
      final name = classNames[i];
      final url = serverUrls[i];
      List<MVideo> a = [];
      if (name.contains("anime")) {
        a = await MBridge.gogoCdnExtractor(url);
      } else if (name.contains("vidcdn")) {
        a = await MBridge.gogoCdnExtractor(url);
      } else if (name.contains("doodstream")) {
        a = await MBridge.doodExtractor(url);
      } else if (name.contains("mp4upload")) {
        a = await MBridge.mp4UploadExtractor(url, null, "", "");
      } else if (name.contains("streamsb")) {}
      videos.addAll(a);
    }

    return videos;
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    return [];
  }
}

GogoAnime main() {
  return GogoAnime();
}

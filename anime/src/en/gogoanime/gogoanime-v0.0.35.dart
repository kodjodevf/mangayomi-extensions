import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class GogoAnime extends MProvider {
  GogoAnime();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/popular.html?page=$page"};
    final res = await http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="img"]/a/@href');
    final names = xpath(res, '//*[@class="img"]/a/@title');
    final images = xpath(res, '//*[@class="img"]/a/img/@src');

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
    final data = {
      "url":
          "https://ajax.gogo-load.com/ajax/page-recent-release-ongoing.html?page=$page&type=1"
    };
    final res = await http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = xpath(
        res, '//*[@class="added_series_body popular"]/ul/li/a[1]/@href');
    final names = xpath(
        res, '//*[//*[@class="added_series_body popular"]/ul/li/a[1]/@title');
    List<String> images = [];
    List<String> imagess = xpath(res,
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
  Future<MPages> search(MSource source, String query, int page) async {
    final data = {
      "url": "${source.baseUrl}/search.html?keyword=$query&page=$page"
    };
    final res = await http('GET', json.encode(data));

    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="img"]/a/@href');
    final names = xpath(res, '//*[@class="img"]/a/@title');
    final images = xpath(res, '//*[@class="img"]/a/img/@src');

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
    final statusList = [
      {
        "Ongoing": 0,
        "Completed": 1,
      }
    ];
    final data = {"url": "${source.baseUrl}$url"};
    final res = await http('GET', json.encode(data));
    MManga anime = MManga();
    final status = xpath(
            res, '//*[@class="anime_info_body_bg"]/p[@class="type"][5]/text()')
        .first
        .replaceAll("Status: ", "");
    anime.description = xpath(
            res, '//*[@class="anime_info_body_bg"]/p[@class="type"][2]/text()')
        .first
        .replaceAll("Plot Summary: ", "");
    anime.status = parseStatus(status, statusList);
    anime.genre = xpath(
            res, '//*[@class="anime_info_body_bg"]/p[@class="type"][3]/text()')
        .first
        .replaceAll("Genre: ", "")
        .split(",");

    final id = xpath(res, '//*[@id="movie_id"]/@value').first;
    final urlEp =
        "https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=4000&id=$id";
    final dataEp = {"url": urlEp};
    final resEp = await http('GET', json.encode(dataEp));

    final epUrls =
        xpath(resEp, '//*[@id="episode_related"]/li/a/@href');
    final names = xpath(
        resEp, '//*[@id="episode_related"]/li/a/div[@class="name"]/text()');
    List<String> episodes = [];

    for (var a in names) {
      episodes.add("Episode ${substringAfterLast(a, ' ')}");
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
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    final datas = {"url": "${source.baseUrl}$url"};

    final res = await http('GET', json.encode(datas));
    final serverUrls =
        xpath(res, '//*[@class="anime_muti_link"]/ul/li/a/@data-video');
    final classNames =
        xpath(res, '//*[@class="anime_muti_link"]/ul/li/@class');
    List<MVideo> videos = [];
    for (var i = 0; i < classNames.length; i++) {
      final name = classNames[i];
      final url = serverUrls[i];
      List<MVideo> a = [];
      if (name.contains("anime")) {
        a = await gogoCdnExtractor(url);
      } else if (name.contains("vidcdn")) {
        a = await gogoCdnExtractor(url);
      } else if (name.contains("doodstream")) {
        a = await doodExtractor(url);
      } else if (name.contains("mp4upload")) {
        a = await mp4UploadExtractor(url, null, "", "");
      } else if (name.contains("streamsb")) {}
      videos.addAll(a);
    }

    return videos;
  }

  @override
  Future<List<String>> getPageList(MSource source, String url) async {
    return [];
  }
}

GogoAnime main() {
  return GogoAnime();
}

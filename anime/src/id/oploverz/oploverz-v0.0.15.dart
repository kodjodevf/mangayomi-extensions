import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class OploVerz extends MProvider {
  OploVerz();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {
      "url": "${source.baseUrl}/anime-list/page/$page/?order=popular"
    };
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {
      "url": "${source.baseUrl}/anime-list/page/$page/?order=latest"
    };
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(
      MSource source, String query, int page, FilterList filterList) async {
    final data = {
      "url": "${source.baseUrl}/anime-list/page/$page/?title=$query"
    };
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"ongoing": 0, "completed": 1}
    ];
    final data = {"url": url};
    final res = await http('GET', json.encode(data));
    MManga anime = MManga();
    final status = xpath(res, '//*[@class="alternati"]/span[2]/text()');
    print(status);
    if (status.isNotEmpty) {
      anime.status = parseStatus(status.first, statusList);
    }
    anime.description = xpath(res, '//*[@class="desc"]/div/text()').first;

    anime.genre = xpath(res, '//*[@class="genre-info"]/a/text()');
    final epUrls =
        xpath(res, '//div[@class="epsleft")]/span[@class="lchx"]/a/@href');
    final names =
        xpath(res, '//div[@class="epsleft")]/span[@class="lchx"]/a/text()');
    final dates =
        xpath(res, '//div[@class="epsleft")]/span[@class="date"]/text()');
    final dateUploads = parseDates(dates, "dd/MM/yyyy", "id");
    List<MChapter>? episodesList = [];
    for (var i = 0; i < epUrls.length; i++) {
      MChapter episode = MChapter();
      episode.name = names[i];
      episode.dateUpload = dateUploads[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    final res = await http('GET', json.encode({"url": url}));
    final dataPost = xpath(res,
            '//*[@id="server"]/ul/li/div[contains(@id,"player-option")]/@data-post')
        .first;
    final dataNume = xpath(res,
            '//*[@id="server"]/ul/li/div[contains(@id,"player-option")]/@data-nume')
        .first;
    final dataType = xpath(res,
            '//*[@id="server"]/ul/li/div[contains(@id,"player-option")]/@data-type')
        .first;
    final body = {
      "action": "player_ajax",
      "post": dataPost,
      "nume": dataNume,
      "type": dataType
    };

    final ress = await http(
        'POST',
        json.encode({
          "useFormBuilder": true,
          "body": body,
          "url": "${source.baseUrl}/wp-admin/admin-ajax.php"
        }));
    final playerLink =
        xpath(ress, '//iframe[@class="playeriframe"]/@src').first;
    final resPlayer = await http('GET', json.encode({"url": playerLink}));
    var resJson = substringBefore(substringAfter(resPlayer, "= "), "<");
    var streams =
        json.decode(getMapValue(resJson, "streams", encode: true)) as List;
    List<MVideo> videos = [];
    for (var stream in streams) {
      final videoUrl = getMapValue(stream, "play_url");
      final quality = getQuality(getMapValue(stream, "format_id"));

      MVideo video = MVideo();
      video
        ..url = videoUrl
        ..originalUrl = videoUrl
        ..quality = quality
        ..subtitles = [];
      videos.add(video);
    }

    return videos;
  }

  String getQuality(int formatId) {
    if (formatId == 18) {
      return "Google - 360p";
    } else if (formatId == 22) {
      return "Google - 720p";
    }
    return "Unknown Resolution";
  }

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final urls = xpath(res, '//div[@class="relat"]/article/div/div/a/@href');
    final names = xpath(res, '//div[@class="relat"]/article/div/div/a/@title');
    final images =
        xpath(res, '//div[@class="relat"]/article/div/div/a/div/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final pages = xpath(res, '//div[@class="pagination"]/a/@href');
    final pageNumberCurrent = xpath(res,
        '//div[@class="pagination"]/span[@class="page-numbers current"]/text()');

    bool hasNextPage = true;
    if (pageNumberCurrent.isNotEmpty && pages.isNotEmpty) {
      hasNextPage = !(pages.length == int.parse(pageNumberCurrent.first));
    }
    return MPages(animeList, hasNextPage);
  }
}

OploVerz main() {
  return OploVerz();
}

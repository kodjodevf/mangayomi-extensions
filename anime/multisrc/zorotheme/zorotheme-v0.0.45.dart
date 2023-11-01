import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class ZoroTheme extends MProvider {
  ZoroTheme();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/most-popular?page=$page"};
    final res = await http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/recently-updated?page=$page"};
    final res = await http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    final data = {"url": "${source.baseUrl}/search?keyword=$query&page=$page"};
    final res = await http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {
        "Currently Airing": 0,
        "Finished Airing": 1,
      }
    ];
    final data = {"url": "${source.baseUrl}$url"};
    final res = await http('GET', json.encode(data));
    MManga anime = MManga();
    final status = xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Status:")]/span[2]/text()')
        .first;

    anime.status = parseStatus(status, statusList);
    anime.author = xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Studios:")]/span/text()')
        .first
        .replaceAll("Studios:", "");
    anime.description = xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Overview:")]/text()')
        .first
        .replaceAll("Overview:", "");
    final genre = xpath(res,
        '//*[@class="anisc-info"]/div[contains(text(),"Genres:")]/a/text()');

    anime.genre = genre;
    final id = substringAfterLast(url, '-');

    final urlEp =
        "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/list/$id";

    final dataEp = {
      "url": urlEp,
      "headers": {"referer": url}
    };
    final resEp = await http('GET', json.encode(dataEp));

    final html = json.decode(resEp)["html"];

    final epUrls = querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "href",
        typeRegExp: 0);
    final numbers = querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "data-number",
        typeRegExp: 0);

    final titles = querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "title",
        typeRegExp: 0);

    List<String> episodes = [];

    for (var i = 0; i < titles.length; i++) {
      final number = numbers[i];
      final title = titles[i];
      episodes.add("Episode $number: $title");
    }
    List<MChapter>? episodesList = [];
    for (var i = 0; i < episodes.length; i++) {
      MChapter episode = MChapter();
      episode.name = episodes[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    final id = substringAfterLast(url, '?ep=');

    final datas = {
      "url":
          "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/servers?episodeId=$id",
      "headers": {"referer": "${source.baseUrl}/$url"}
    };
    final res = await http('GET', json.encode(datas));
    final html = json.decode(res)["html"];

    final names = querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 0,
        attributes: "",
        typeRegExp: 0);

    final ids = querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 3,
        attributes: "data-id",
        typeRegExp: 0);

    final subDubs = querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 3,
        attributes: "data-type",
        typeRegExp: 0);

    List<MVideo> videos = [];

    for (var i = 0; i < names.length; i++) {
      final name = names[i];
      final id = ids[i];
      final subDub = subDubs[i];
      final datasE = {
        "url":
            "${source.baseUrl}/ajax${ajaxRoute('${source.baseUrl}')}/episode/sources?id=$id",
        "headers": {"referer": "${source.baseUrl}/$url"}
      };

      final resE = await http('GET', json.encode(datasE));
      String epUrl = substringBefore(substringAfter(resE, "\"link\":\""), "\"");
      print(epUrl);
      List<MVideo> a = [];
      if (name.contains("Vidstreaming")) {
        a = await rapidCloudExtractor(epUrl, "Vidstreaming - $subDub");
      } else if (name.contains("Vidcloud")) {
        a = await rapidCloudExtractor(epUrl, "Vidcloud - $subDub");
      } else if (name.contains("StreamTape")) {
        a = await streamTapeExtractor(epUrl, "StreamTape - $subDub");
      }
      videos.addAll(a);
    }

    return videos;
  }

  MPages animeElementM(String res) {
    List<MManga> animeList = [];

    final urls = xpath(
        res, '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@href');

    final names = xpath(res,
        '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@data-jname');

    final images = xpath(
        res, '//*[@class^="flw-item"]/div[@class="film-poster"]/img/@data-src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage =
        xpath(res, '//li[@class="page-item"]/a[@title="Next"]/@href', "");
    return MPages(animeList, !nextPage.isEmpty);
  }

  String ajaxRoute(String baseUrl) {
    if (baseUrl == "https://kaido.to") {
      return "";
    }
    return "/v2";
  }
}

ZoroTheme main() {
  return ZoroTheme();
}

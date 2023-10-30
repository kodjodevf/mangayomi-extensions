import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class ZoroTheme extends MSourceProvider {
  ZoroTheme();

  @override
  Future<MPages> getPopular(MSource sourceInfo, int page) async {
    final data = {"url": "${sourceInfo.baseUrl}/most-popular?page=$page"};
    final res = await MBridge.http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource sourceInfo, int page) async {
    final data = {"url": "${sourceInfo.baseUrl}/recently-updated?page=$page"};
    final res = await MBridge.http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MPages> search(MSource sourceInfo, String query, int page) async {
    final data = {
      "url": "${sourceInfo.baseUrl}/search?keyword=$query&page=$page"
    };
    final res = await MBridge.http('GET', json.encode(data));

    return animeElementM(res);
  }

  @override
  Future<MManga> getDetail(MSource sourceInfo, String url) async {
    final statusList = [
      {
        "Currently Airing": 0,
        "Finished Airing": 1,
      }
    ];
    final data = {"url": "${sourceInfo.baseUrl}$url"};
    final res = await MBridge.http('GET', json.encode(data));
    MManga anime = MManga();
    final status = MBridge.xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Status:")]/span[2]/text()')
        .first;
    anime.status = MBridge.parseStatus(status, statusList);
    anime.author = MBridge.xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Studios:")]/span/text()')
        .first
        .replaceAll("Studios:", "");
    final aired = MBridge.xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Aired:")]/span/text()')
        .first;
    final japanese = MBridge.xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Japanese:")]/span/text()')
        .first;
    final synonyms = MBridge.xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Synonyms:")]/span/text()')
        .first;
    final premiered = MBridge.xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Premiered:")]/span/text()')
        .first;
    final overview = MBridge.xpath(res,
            '//*[@class="anisc-info"]/div[contains(text(),"Overview:")]/text()')
        .first
        .replaceAll("Overview:", "");
    String description =
        "$overview\n\n$japanese\n$synonyms\n$aired\n$premiered";
    anime.description = description;
    final genre = MBridge.xpath(res,
        '//*[@class="anisc-info"]/div[contains(text(),"Genres:")]/a/text()');

    anime.genre = genre;
    final id = MBridge.substringAfterLast(anime.link, '-');
    final urlEp =
        "${anime.baseUrl}/ajax${ajaxRoute('${anime.baseUrl}')}/episode/list/$id";

    final dataEp = {
      "url": urlEp,
      "headers": {"referer": url}
    };
    final resEp = await MBridge.http('GET', json.encode(dataEp));

    final html = json.decode(resEp)["html"];

    final epUrls = MBridge.querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "href",
        typeRegExp: 0);
    final numbers = MBridge.querySelectorAll(html,
        selector: "a.ep-item",
        typeElement: 3,
        attributes: "data-number",
        typeRegExp: 0);

    final titles = MBridge.querySelectorAll(html,
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

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource sourceInfo, String url) async {
    final id = MBridge.substringAfterLast(url, '?ep=');

    final datas = {
      "url":
          "${sourceInfo.baseUrl}/ajax${ajaxRoute('${sourceInfo.baseUrl}')}/episode/servers?episodeId=$id",
      "headers": {"referer": "${sourceInfo.baseUrl}/$url"}
    };
    final res = await MBridge.http('GET', json.encode(datas));
    final html = json.decode(res)["html"];

    final names = MBridge.querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 0,
        attributes: "",
        typeRegExp: 0);

    final ids = MBridge.querySelectorAll(html,
        selector: "div.server-item",
        typeElement: 3,
        attributes: "data-id",
        typeRegExp: 0);

    final subDubs = MBridge.querySelectorAll(html,
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
            "${sourceInfo.baseUrl}/ajax${ajaxRoute('${sourceInfo.baseUrl}')}/episode/sources?id=$id",
        "headers": {"referer": "${sourceInfo.baseUrl}/$url"}
      };

      final resE = await MBridge.http('GET', json.encode(datasE));
      String epUrl = MBridge.substringBefore(
          MBridge.substringAfter(resE, "\"link\":\""), "\"");
      print(epUrl);
      List<MVideo> a = [];
      if (name.contains("Vidstreaming")) {
        a = await MBridge.rapidCloudExtractor(epUrl, "Vidstreaming - $subDub");
      } else if (name.contains("Vidcloud")) {
        a = await MBridge.rapidCloudExtractor(epUrl, "Vidcloud - $subDub");
      } else if (name.contains("StreamTape")) {
        a = await MBridge.streamTapeExtractor(epUrl, "StreamTape - $subDub");
      }
      videos.addAll(a);
    }

    return videos;
  }

  @override
  Future<List<String>> getPageList(MSource sourceInfo, String url) async {
    return [];
  }

  MPages animeElementM(String res) {
    List<MManga> animeList = [];

    final urls = MBridge.xpath(
        res, '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@href');

    final names = MBridge.xpath(res,
        '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@data-jname');

    final images = MBridge.xpath(
        res, '//*[@class^="flw-item"]/div[@class="film-poster"]/img/@data-src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = MBridge.xpath(
        res, '//li[@class="page-item"]/a[@title="Next"]/@href', "");
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

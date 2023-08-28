import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  final data = {
    "url": "https://aniwatch.to/most-popular?page=${anime.page}",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  return animeElementM(res, anime);
}

getLatestUpdatesAnime(MangaModel anime) async {
  final data = {
    "url": "https://aniwatch.to/top-airing?page=${anime.page}",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  return animeElementM(res, anime);
}

getAnimeDetail(MangaModel anime) async {
  final statusList = [
    {
      "Currently Airing": 0,
      "Finished Airing": 1,
    }
  ];
  final url = "https://kaido.to${anime.link}";
  final data = {"url": url, "headers": null};
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  final status = MBridge.xpath(
      res,
      '//*[@class="anisc-info"]/div[contains(text(),"Status:")]/span[2]/text()',
      '');
  anime.status = MBridge.parseStatus(status, statusList);
  anime.author = MBridge.xpath(
          res,
          '//*[@class="anisc-info"]/div[contains(text(),"Studios:")]/span/text()',
          '')
      .replaceAll("Studios:", "");
  final aired = MBridge.xpath(
      res,
      '//*[@class="anisc-info"]/div[contains(text(),"Aired:")]/span/text()',
      ' ');
  final japanese = MBridge.xpath(
      res,
      '//*[@class="anisc-info"]/div[contains(text(),"Japanese:")]/span/text()',
      ' ');
  final synonyms = MBridge.xpath(
      res,
      '//*[@class="anisc-info"]/div[contains(text(),"Synonyms:")]/span/text()',
      ' ');
  final premiered = MBridge.xpath(
      res,
      '//*[@class="anisc-info"]/div[contains(text(),"Premiered:")]/span/text()',
      ' ');
  final overview = MBridge.xpath(
          res,
          '//*[@class="anisc-info"]/div[contains(text(),"Overview:")]/text()',
          ' ')
      .replaceAll("Overview:", "");
  String description = "$overview\n\n$japanese\n$synonyms\n$aired\n$premiered";
  anime.description = description;
  final genre = MBridge.xpath(
          res,
          '//*[@class="anisc-info"]/div[contains(text(),"Genres:")]/a/text()',
          '_..')
      .split("_..");

  anime.genre = genre;

  final id = MBridge.subString(anime.link, '-', 1);
  final urlEp =
      "https://kaido.to/ajax/${ajaxRoute('https://kaido.to')}/episode/list/$id";

  final dataEp = {
    "url": urlEp,
    "headers": {"referer": url}
  };
  final resEp = await MBridge.http(json.encode(dataEp), 0);
  final html = MBridge.getMapValue(resEp, "html", 0);
  final epUrls =
      MBridge.querySelectorAll(html, "a.ep-item", 3, "href", 0, 0, '._')
          .split("._");
  anime.urls = MBridge.listParse(epUrls, 5);

  List<String> numbers =
      MBridge.querySelectorAll(html, "a.ep-item", 3, "data-number", 0, 0, '._')
          .split("._");
  List<String> titles =
      MBridge.querySelectorAll(html, "a.ep-item", 3, "title", 0, 0, '._')
          .split("._");

  List<String> episodes = [];

  for (var i = 0; i < titles.length; i++) {
    final number = MBridge.listParse(numbers, 0)[i];
    final title = MBridge.listParse(titles, 0)[i];
    episodes.add("Episode ${number}: $title");
  }

  anime.names = MBridge.listParse(episodes, 5);
  anime.chaptersDateUploads = [];
  return anime;
}

searchAnime(MangaModel anime) async {
  final data = {
    "url":
        "https://aniwatch.to/search?keyword=${anime.query}&page=${anime.page}",
    "headers": null,
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  return animeElementM(res, anime);
}

getVideoList(MangaModel episode) async {
  final id = MBridge.subString(episode.link, '?ep=', 1);
  final datas = {
    "url":
        "https://kaido.to/ajax${ajaxRoute('https://kaido.to')}/episode/servers?episodeId=$id",
    "headers": {"referer": "https://kaido.to/${episode.link}"},
    "sourceId": episode.sourceId
  };

  final res = await MBridge.http(json.encode(datas), 0);

  if (res.isEmpty) {
    return [];
  }
  final html = MBridge.getMapValue(res, "html", 0);
  final names =
      MBridge.querySelectorAll(html, "div.server-item", 0, "", 0, 0, '._')
          .split("._");

  final ids = MBridge.querySelectorAll(
          html, "div.server-item", 3, "data-id", 0, 0, '._')
      .split("._");
  final subDubs = MBridge.querySelectorAll(
          html, "div.server-item", 3, "data-type", 0, 0, '._')
      .split("._");

  List<VideoModel> videos = [];

  for (var i = 0; i < names.length; i++) {
    final name = MBridge.listParse(names, 0)[i].toString();
    final id = MBridge.listParse(ids, 0)[i].toString();
    final subDub = MBridge.listParse(subDubs, 0)[i].toString();
    final datasE = {
      "url":
          "https://kaido.to/ajax${ajaxRoute('https://kaido.to')}/episode/sources?id=$id",
      "headers": {"referer": "https://kaido.to/${episode.link}"},
      "sourceId": episode.sourceId
    };

    final resE = await MBridge.http(json.encode(datasE), 0);
    String url =
        MBridge.subString(MBridge.subString(resE, "\"link\":\"", 2), "\"", 0);
    print(url);
    List<VideoModel> a = [];
    if (name.contains("Vidstreaming")) {
      a = await MBridge.rapidCloudExtractor(url, "Vidstreaming");
    } else if (name.contains("Vidcloud")) {
      a = await MBridge.rapidCloudExtractor(url, "Vidcloud");
    } else if (name.contains("StreamTape")) {
      a = await MBridge.streamTapeExtractor(url);
    }
    for (var vi in a) {
      videos.add(vi);
    }
  }

  return videos;
}

MangaModel animeElementM(String res, MangaModel anime) async {
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(res,
          '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@href', '._')
      .split('._');

  anime.names = MBridge.xpath(
          res,
          '//*[@class^="flw-item"]/div[@class="film-detail"]/h3/a/@data-jname',
          '._')
      .split('._');

  anime.images = MBridge.xpath(
          res,
          '//*[@class^="flw-item"]/div[@class="film-poster"]/img/@data-src',
          '._')
      .split('._');
  final nextPage =
      MBridge.xpath(res, '//li[@class="page-item"]/a[@title="Next"]/@href', "");
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

String ajaxRoute(String baseUrl) {
  if (baseUrl == "https://kaido.to") {
    return "";
  }
  return "/v2";
}

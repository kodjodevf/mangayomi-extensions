import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  return await getLatestUpdatesAnime(anime);
}

Future<MangaModel> getLatestUpdatesAnime(MangaModel anime) async {
  final data = {
    "url": anime.baseUrl,
    "headers": {"referer": "https://wcostream.org/"},
    "sourceId": anime.sourceId
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }
  final urlss = MBridge.xpath(
          res,
          '//*[@id="content"]/div/div[contains(text(),"Recent Releases")]/div/ul/li/div[@class="img"]/a/img/@alt',
          '._')
      .split('._');
  List<String> urls = [];
  for (var url in MBridge.listParse(urlss, 0)) {
    urls.add(
        "/anime/${MBridge.regExp(url, "[^A-Za-z0-9 ]", "", 0, 0).replaceAll(" ", "-").toLowerCase()}/");
  }
  anime.urls = urls;
  final imagess = MBridge.xpath(
          res,
          '//*[@id="content"]/div/div[contains(text(),"Recent Releases")]/div/ul/li/div[@class="img"]/a/img/@src',
          '._')
      .split('._');
  List<String> images = [];
  for (var image in MBridge.listParse(imagess, 0)) {
    images.add(fixUrl(image));
  }
  anime.images = images;
  final namess = MBridge.xpath(
          res,
          '//*[@id="content"]/div/div[contains(text(),"Recent Releases")]/div/ul/li/div[@class="recent-release-episodes"]/a/text()',
          '._')
      .split('._');
  List<String> names = [];
  for (var name in MBridge.listParse(namess, 0)) {
    names.add(MBridge.subString(name, ' Episode', 0));
  }
  anime.names = names;
  anime.hasNextPage = false;
  return anime;
}

String fixUrl(String url) {
  return MBridge.regExp(url, r"^(?:(?:https?:)?//|www\.)", 'https://', 0, 0);
}

getAnimeDetail(MangaModel anime) async {
  final url = '${anime.baseUrl}${anime.link}';
  print(url);
  final data = {
    "url": url,
    "headers": {"referer": "https://wcostream.org/"}
  };
  final res = await MBridge.http(json.encode(data), 0);
  if (res.isEmpty) {
    return anime;
  }

  anime.status = 5;
  anime.description = MBridge.xpath(
          res,
          '//*[@class="katcont"]/div/p[contains(text(),"Plot Summary:")]/text()',
          '')
      .replaceAll('Plot Summary: ', '');

  anime.genre = MBridge.xpath(
          res, '//*[@id="cat-genre"]/div[@class="wcobtn"]/a/text()', '._')
      .split('._');

  anime.urls = MBridge.xpath(
          res,
          '//*[@id="catlist-listview" and @class^="cat-listview"]/ul/li/a/@href',
          '._')
      .split('._');
  anime.names = MBridge.xpath(
          res,
          '//*[@id="catlist-listview" and @class^="cat-listview"]/ul/li/a/text()',
          '._')
      .split('._');
  anime.chaptersDateUploads = [];
  return anime;
}

searchAnime(MangaModel anime) async {
  final data = {
    "url": "${anime.baseUrl}/search",
    "fields": {'catara': anime.query.replaceAll(" ", "+"), 'konuara': 'series'},
    "headers": {"Referer": "${anime.baseUrl}/"},
    "sourceId": anime.sourceId
  };
  final res = await MBridge.httpMultiparFormData(json.encode(data), 1);
  if (res.isEmpty) {
    return anime;
  }

  anime.urls = MBridge.xpath(
          res,
          '//*[@id="blog"]/div[@class="cerceve"]/div[@class="iccerceve"]/a/@href',
          '._')
      .split('._');

  anime.names = MBridge.xpath(
          res,
          '//*[@id="blog"]/div[@class="cerceve"]/div[@class="iccerceve"]/a/@title',
          '._')
      .split('._');
  anime.images = MBridge.xpath(
          res,
          '//*[@id="blog"]/div[@class="cerceve"]/div[@class="iccerceve"]/a/img/@src',
          '._')
      .split('._');
  anime.hasNextPage = false;
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
  final script = MBridge.xpath(
      res, '//script[contains(text(), "decodeURIComponent")]/text()', "");
  final stringList = MBridge.jsonDecodeToList(
      "[${MBridge.subString(MBridge.subString(script, '[', 2), ']', 0)}]", 0);
  final shiftNumber = MBridge.intParse(
      MBridge.subString(MBridge.subString(script, '- ', 1), ')', 0));

  print(shiftNumber - 1);
  List<String> iframeStuff = [];
  for (var i = 0; i < stringList.length; i++) {
    final decoded = MBridge.bAse64(MBridge.listParse(stringList, 0)[i], 0);
    final intValue =
        MBridge.intParse(MBridge.regExp(decoded, r"""\D""", '', 0, 0));
    iframeStuff
        .add(MBridge.stringParse("${intValue - shiftNumber}".toString(), 1));
  }

  final iframeUrl =
      MBridge.xpath(MBridge.listParse(iframeStuff, 6)[0], '//iframe/@src', "");
  final iframeHeaders = {
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Connection': 'keep-alive',
    'Host': MBridge.listParse(iframeUrl.split('/'), 0)[2],
    'Referer': '${anime.baseUrl}/',
    'Sec-Fetch-Dest': 'iframe',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'cross-site',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.63',
  };
  final datasIframe = {"url": iframeUrl, "headers": iframeHeaders};

  final resIframe = await MBridge.http(json.encode(datasIframe), 0);
  final getVideoLinkScript = MBridge.xpath(
      resIframe, '//script[contains(text(), "getJSON")]/text()', "");

  final getVideoLinkUrl = MBridge.subString(
      MBridge.subString(getVideoLinkScript, "getJSON(\"", 2), "\"", 0);
  final getVideoHeaders = {
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Host': MBridge.listParse(iframeUrl.split('/'), 0)[2],
    'Referer': iframeUrl,
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.63',
    'X-Requested-With': 'XMLHttpRequest',
  };
  final datasVideoLink = {
    "url":
        'https://${MBridge.listParse(iframeUrl.split('/'), 0)[2]}$getVideoLinkUrl',
    "headers": getVideoHeaders
  };

  final resVideoLink = await MBridge.http(json.encode(datasVideoLink), 0);
  final server = MBridge.getMapValue(resVideoLink, "server", 0);
  final enc = MBridge.getMapValue(resVideoLink, "enc", 0);
  final hd = MBridge.getMapValue(resVideoLink, "hd", 0);
  final fhd = MBridge.getMapValue(resVideoLink, "fhd", 0);
  final videoUrl = "$server/getvid?evid=$enc";

  final videoHeaders = {
    'Accept':
        'video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5',
    'Host': MBridge.listParse(videoUrl.split('/'), 0)[2],
    'Referer': MBridge.listParse(iframeUrl.split('/'), 0)[2],
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.63',
  };
  List<VideoModel> videos = [];
  videos.add(MBridge.toVideo(
      videoUrl, "Video 480p", videoUrl, json.encode(videoHeaders)));
  if (hd.isEmpty) {
  } else {
    final hdVideoUrl = "$server/getvid?evid=$hd";
    videos.add(MBridge.toVideo(
        hdVideoUrl, "Video 720p", hdVideoUrl, json.encode(videoHeaders)));
  }
  if (fhd.isEmpty) {
  } else {
    final fhdVideoUrl = "$server/getvid?evid=$fhd";
    videos.add(MBridge.toVideo(
        fhdVideoUrl, "Video 1080p", fhdVideoUrl, json.encode(videoHeaders)));
  }
  return videos;
}

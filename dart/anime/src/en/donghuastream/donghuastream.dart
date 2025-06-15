import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class DonghuaStream extends MProvider {
  DonghuaStream({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  bool get supportsLatest => true;

  @override
  Map<String, String> get headers => {};
  
  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}/anime?page=${page}&sub=&order=popular"))).body;
    List<MManga> animeList = [];
    final urls = xpath(res, '//article[@class="bs"]/div/a/@href');
    final names = xpath(res, '//article[@class="bs"]/div/a/@title');
    final images = xpath(res, '//article[@class="bs"]/div/a/div/img/@data-src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@class="r"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}/anime?page=${page}&sub=&order=update"))).body;
    List<MManga> animeList = [];
    final urls = xpath(res, '//article[@class="bs"]/div/a/@href');
    final names = xpath(res, '//article[@class="bs"]/div/a/@title');
    final images = xpath(res, '//article[@class="bs"]/div/a/div/img/@data-src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@class="r"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res = (await client.get(Uri.parse("${source.baseUrl}/page/${page}/?s=${query}"))).body;
    List<MManga> animeList = [];
    final urls = xpath(res, '//article[@class="bs"]/div/a/@href');
    final names = xpath(res, '//article[@class="bs"]/div/a/@title');
    final images = xpath(res, '//article[@class="bs"]/div/a/div/img/@src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@class="next page-numbers"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MManga> getDetail(String url) async {
     final res = (await client.get(Uri.parse(url))).body;
     MManga anime = MManga();
     var genre = xpath(res,'//div[@class="genxed"]/a/text()');
     genre.remove('MY FAVOURITE');
     anime.genre = genre;
     anime.description = xpath(res,'//div[@class="entry-content"]/p/text()').join("\n");

     final statusList = [{"Status: Ongoing": 0, "Status: Completed": 1}];
     final infoContent = xpath(res,'//div[@class="info-content"]/div[@class="spe"]/span/text()');
     anime.status = parseStatus(infoContent[0], statusList);
     anime.author = infoContent[1].replaceFirst('Network: ','').replaceFirst('Donghua Stream, ','');
     anime.artist = infoContent[2].replaceFirst('Studio: ','');
     final epElements =  parseHtml(res).select('div.eplister > ul > li >a');
    List<MChapter>? episodesList = [];
    
    for (var epElement in epElements) {
      final number = epElement.selectFirst("div.epl-num").text;
      final title = epElement.selectFirst("div.epl-title").text;
      final dateString =  epElement.selectFirst("div.epl-date").text;
      MChapter episode = MChapter();
      episode.name = "Episode $number";
      episode.url = epElement.getHref;
      episode.dateUpload = parseDates([dateString],"MMMM d, yyyy","en",)[0];
      episodesList.add(episode);
    }
     anime.chapters = episodesList;
     return anime;
  }
  
  
  // For anime episode video list
  @override
  Future<List<MVideo>> getVideoList(String url) async {
      final res = (await client.get(Uri.parse(url))).body;
      final servers = parseHtml(res).select('select.mirror > option[data-index]');
      List<MVideo> videos = [];
      for (var i = 0; i < servers.length; i++) {
        String name = '${servers[i].attr("data-index")}: ${servers[i].text}';
        String valueHtml = utf8.decode(base64Url.decode(servers[i].attr('value')));
        String serverUrl = xpath(valueHtml,'//iframe/@src')[0];
        print('$name,$serverUrl');
        if(serverUrl.startsWith('https://geo.dailymotion.com/player')){
          String videoId = RegExp(r'[?&]video=([a-zA-Z0-9]+)').firstMatch(serverUrl).group(1)!;
          return dailymotionUrlFetcher(videoId,name);
        }
      }
      return videos;
  }
  
  Future<List<MVideo>> dailymotionUrlFetcher(String videoID, String name) async {
    String metaDataUrl = 'https://www.dailymotion.com/player/metadata/video/$videoID';
    print(metaDataUrl);
    final res = (await client.get(Uri.parse(metaDataUrl))).body;
    final jsonRes = json.decode(res);
    String masterUrl = jsonRes["qualities"]["auto"][0]["url"];
    return m3u8extractor(masterUrl, name);
  }
  
  Future<List<MVideo>> m3u8extractor(String masterUrl, String name) async {
    List<MVideo> videos = [];
    List<MTrack> subtitles = [];
    final masterPlaylistRes =
          (await client.get(Uri.parse(masterUrl), headers: headers)).body;
          
       // Parse Subtitles
      final subtitleRegExp = RegExp(r'#EXT-X-MEDIA:TYPE=SUBTITLES.*?NAME="(.*?)".*?URI="(.*?)"', dotAll: true);
      for (final match in subtitleRegExp.allMatches(masterPlaylistRes)) {
        MTrack subtitle = MTrack();
        subtitle.label = match.group(1) ?? 'Subtitle';
        subtitle.file = match.group(2) ?? '';
        subtitles.add(subtitle);          
      }

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

        MVideo video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = "$name - $quality"
          ..subtitles = subtitles
          ..headers = headers;
        videos.add(video);
      }
      return videos;
  }
}

DonghuaStream main(MSource source) {
  return DonghuaStream(source:source);
}
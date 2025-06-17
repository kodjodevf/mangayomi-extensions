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
    var servers = parseHtml(res).select('select.mirror > option[data-index]');
    if(servers.length==0){
      final src_data = parseHtml(res).selectFirst('article[id] > script').attr('src').replaceAll ('data:text/javascript;base64,','');
      final src_function = utf8.decode(base64Url.decode(src_data));
      final html_data = RegExp(r'"html":"(.*?)","autoplayIndex"').firstMatch(src_function).group(1);
      servers = parseHtml(html_data.replaceAll(r'\t', '\t').replaceAll(r'\n', '\n').replaceAll(r'\"', '"').replaceAll(r'\/', '/')).select('select.mirror > option[data-index]');
    }
    List<MVideo> videos = [];
    for (var i = 0; i < servers.length; i++) {
      String name = '${servers[i].attr("data-index")}: ${servers[i].text}';
      String valueHtml = utf8.decode(base64Url.decode(servers[i].attr('value')));
      final serverUrlList = xpath(valueHtml,'//iframe/@src');
      if (serverUrlList.length>0){
        String serverUrl = serverUrlList[0];
        if(serverUrl.contains('https://geo.dailymotion.com/player')){
          String videoId = RegExp(r'[?&]video=([a-zA-Z0-9]+)').firstMatch(serverUrl).group(1);
          videos.addAll(await dailymotionVideosFetcher(videoId,name));
        }else if(serverUrl.contains('//play.streamplay.co.in/')){
          String videoId = serverUrl.split('/embed/')[1];
          videos.addAll(await streamplayVideosFetcher(videoId,name));
        }
      }
    }
    return videos;
  }
  
  Future<List<MVideo>> dailymotionVideosFetcher(String videoID, String name) async {
    String metaDataUrl = 'https://www.dailymotion.com/player/metadata/video/$videoID';
    final res = (await client.get(Uri.parse(metaDataUrl))).body;
    final jsonRes = json.decode(res);
    String masterUrl = jsonRes["qualities"]["auto"][0]["url"];
    return m3u8extractor(masterUrl, name);
  }
  
  Future<List<MVideo>> streamplayVideosFetcher(String videoID, String name) async {
    String url = 'https://play.streamplay.co.in/embed/'+videoID;
    final res = (await client.get(Uri.parse(url))).body;
    final match = RegExp(r"eval\(function\(p,a,c,k,e,d\)\{[\s\S]*?\}\((.*?)\)").firstMatch(res);
    if (match == null) {
      return [];
    }
    final argsStr = match.group(1);
    final argsPattern = RegExp(r"'(.*?)',(.*?),(.*?),'(.*?)'\.split");
    final argsMatches = argsPattern.firstMatch(argsStr);
    final arg_p = argsMatches.group(1);
    final arg_a =int.parse(argsMatches.group(2));
    final arg_c =int.parse(argsMatches.group(3));
    final arg_k =argsMatches.group(4).split('|').toList();
    final unpacked_js = unpack(arg_p,arg_a,arg_c,arg_k);
    final kakenMatch  = RegExp(r'window\.kaken\s*=\s*"([^"]+)"').firstMatch(unpacked_js);
    if (kakenMatch == null) {
      return [];
    }
    final kakenValue = kakenMatch.group(1);
    final apiUrl = 'https://play.streamplay.co.in/api/?$kakenValue';
    final apiRes = (await client.get(Uri.parse(apiUrl))).body;
    final jsonRes = json.decode(apiRes);
    String masterUrl = jsonRes['sources'][0]['file'];
    List<MTrack> subtitles = [];
    for (final track in  jsonRes['tracks']){
      MTrack subtitle = MTrack();
      subtitle.label = name + ' - ' + track['label'];
      subtitle.file = track['file'];
      subtitles.add(subtitle);    
    }
    List<MVideo> videos = await m3u8extractor(masterUrl, name);
     if(videos.length>0){
        videos[0].subtitles = subtitles;
      }
    return videos;
  }
  
  String unpack(String p, int a, int c, List<String> k) {
    for (int i = c - 1; i >= 0; i--) {
      String word = (i < k.length) ? k[i] : baseN(i, a);
      String pattern = r'\b' + baseN(i, a) + r'\b';
      p = p.replaceAll(RegExp(pattern), word);
    }
    return p;
  }
  
  String baseN(int num, int base) {
    const digits = '0123456789abcdefghijklmnopqrstuvwxyz';
    if (num == 0) return '0';
    String result = '';
    while (num > 0) {
      result = digits[num % base] + result;
      num ~/= base;
    }
    return result;
  }
  
  Future<List<MVideo>> m3u8extractor(String masterUrl, String name) async {
    List<MVideo> videos = [];
    List<MTrack> subtitles = [];
    final masterPlaylistRes =  (await client.get(Uri.parse(masterUrl), headers: headers)).body;     
    final subtitleRegExp = RegExp(r'#EXT-X-MEDIA:TYPE=SUBTITLES.*?NAME="(.*?)".*?URI="(.*?)"', dotAll: true);
    for (final match in subtitleRegExp.allMatches(masterPlaylistRes)) {
      MTrack subtitle = MTrack();
      subtitle.label = name + ' - ' + match.group(1) ?? 'Subtitle';
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
        ..quality = "$name - $quality";
      videos.add(video);
    }
    if(videos.length>0){
      videos[0].subtitles = subtitles;
    }
    return videos;
  }
}

DonghuaStream main(MSource source) {
  return DonghuaStream(source:source);
}
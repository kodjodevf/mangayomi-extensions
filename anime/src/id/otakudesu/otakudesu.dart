import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class OtakuDesu extends MProvider {
  OtakuDesu();

  final Client client = Client();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}/complete-anime/page/$page")))
        .body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}/ongoing-anime/page/$page")))
        .body;
    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(
      MSource source, String query, int page, FilterList filterList) async {
    final res = (await client
            .get(Uri.parse("${source.baseUrl}/?s=$query&post_type=anime")))
        .body;
    List<MManga> animeList = [];
    final images = xpath(res, '//ul[@class="chivsrc"]/li/img/@src');
    final names = xpath(res, '//ul[@class="chivsrc"]/li/h2/a/text()');
    final urls = xpath(res, '//ul[@class="chivsrc"]/li/h2/a/@href');

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
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"Ongoing": 0, "Completed": 1}
    ];
    final res = (await client.get(Uri.parse(url))).body;
    MManga anime = MManga();
    final status = xpath(
        res, '//*[@class="infozingle"]/p[contains(text(), "Status")]/text()');
    if (status.isNotEmpty) {
      anime.status = parseStatus(status.first.split(':').last, statusList);
    }
    final description = xpath(res, '//*[@class="sinopc"]/text()');
    if (description.isNotEmpty) {
      anime.description = description.first;
    }

    final genre = xpath(
        res, '//*[@class="infozingle"]/p[contains(text(), "Genre")]/text()');
    if (genre.isNotEmpty) {
      anime.genre = genre.first.split(':').last.split(',');
    }

    final epUrls = xpath(res, '//div[@class="episodelist"]/ul/li/span/a/@href');
    final names = xpath(res, '//div[@class="episodelist"]/ul/li/span/a/text()');

    final dates = xpath(
        res, '//div[@class="episodelist"]/ul/li/span[@class="zeebr"]/text()');
    final dateUploads = parseDates(dates, "d MMMM,yyyy", "id");
    List<MChapter>? episodesList = [];
    for (var i = 1; i < epUrls.length; i++) {
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
    List<MVideo> videos = [];
    final res = (await client.get(Uri.parse(url))).body;
    final script =
        xpath(res, '//script[contains(text(), "{action:")]/text()').first;
    final nonceAction =
        substringBefore(substringAfter(script, "{action:\""), '"');
    final action = substringBefore(substringAfter(script, "action:\""), '"');

    final resNonceAction = (await client.post(
            Uri.parse("${source.baseUrl}/wp-admin/admin-ajax.php"),
            headers: null,
            body: {"action": nonceAction}))
        .body;
    final nonce = substringBefore(substringAfter(resNonceAction, ":\""), '"');
    final mirrorstream =
        xpath(res, '//*[@class="mirrorstream"]/ul/li/a/@data-content');
    for (var stream in mirrorstream) {
      List<MVideo> a = [];
      final decodedData = json.decode(utf8.decode(base64Url.decode(stream)));
      final q = decodedData["q"];
      final id = decodedData["id"];
      final i = decodedData["i"];

      final res = (await client.post(
              Uri.parse("${source.baseUrl}/wp-admin/admin-ajax.php"),
              headers: null,
              body: {
            "i": i,
            "id": id,
            "q": q,
            "nonce": nonce,
            "action": action
          }))
          .body;
      final html = utf8.decode(
          base64Url.decode(substringBefore(substringAfter(res, ":\""), '"')));
      String url = xpath(html, '//iframe/@src').first;

      if (url.contains("yourupload")) {
        final id = substringBefore(substringAfter(url, "id="), "&");
        url = "https://yourupload.com/embed/$id";
        a = await yourUploadExtractor(url, null, "YourUpload - $q", null);
      } else if (url.contains("filelions")) {
        a = await streamWishExtractor(url, "FileLions");
      } else if (url.contains("desustream")) {
        final res = (await client.get(Uri.parse(url))).body;
        final script =
            xpath(res, '//script[contains(text(), "sources")]/text()').first;
        final videoUrl = substringBefore(
            substringAfter(substringAfter(script, "sources:[{"), "file':'"),
            "'");
        MVideo video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = "DesuStream - $q"
          ..subtitles = [];
        videos.add(video);
      } else if (url.contains("mp4upload")) {
        final res = (await client.get(Uri.parse(url))).body;
        final script =
            xpath(res, '//script[contains(text(), "player.src")]/text()').first;
        final videoUrl =
            substringBefore(substringAfter(script, "src: \""), '"');
        MVideo video = MVideo();
        video
          ..url = videoUrl
          ..originalUrl = videoUrl
          ..quality = "Mp4upload - $q"
          ..subtitles = [];
        videos.add(video);
      }
      videos.addAll(a);
    }

    return videos;
  }

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final urls =
        xpath(res, '//div[@class="detpost"]/div[@class="thumb"]/a/@href');
    final names = xpath(res,
        '//div[@class="detpost"]/div[@class="thumb"]/a/div[@class="thumbz"]/h2/text()');
    final images = xpath(res,
        '//div[@class="detpost"]/div[@class="thumb"]/a/div[@class="thumbz"]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final pages = xpath(
        res, '//div[@class="pagenavix"]/a[@class="next page-numbers"]/@href');
    return MPages(animeList, pages.isNotEmpty);
  }
}

OtakuDesu main() {
  return OtakuDesu();
}

import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class OkAnime extends MProvider {
  OkAnime({required this.source});

  MSource source;

  final Client client = Client();

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(source.baseUrl))).body;
    List<MManga> animeList = [];
    String path =
        '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]';
    final urls = xpath(res, '$path/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res, '$path/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res, '$path/div[@class="anime-image")]/img/@src');

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
  Future<MPages> getLatestUpdates(int page) async {
    final res =
        (await client.get(
          Uri.parse("${source.baseUrl}/espisode-list?page=$page"),
        )).body;
    List<MManga> animeList = [];
    String path = '//*[contains(@class,"anime-card")]';
    final urls = xpath(res, '$path/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res, '$path/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res, '$path/div[@class="episode-image")]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(
      res,
      '//li[@class="page-item"]/a[@rel="next"]/@href',
    );
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    String url = "${source.baseUrl}/search/?s=$query";
    if (page > 1) {
      url += "&page=$page";
    }

    final res = (await client.get(Uri.parse(url))).body;

    List<MManga> animeList = [];
    String path = '//*[contains(@class,"anime-card")]';
    final urls = xpath(res, '$path/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res, '$path/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res, '$path/div[@class="anime-image")]/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(
      res,
      '//li[@class="page-item"]/a[@rel="next"]/@href',
    );
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final statusList = [
      {"يعرض الان": 0, "مكتمل": 1},
    ];
    final res = (await client.get(Uri.parse(url))).body;
    MManga anime = MManga();
    final status = xpath(
      res,
      '//*[@class="full-list-info" and contains(text(),"حالة الأنمي")]/small/a/text()',
    );
    if (status.isNotEmpty) {
      anime.status = parseStatus(status.first, statusList);
    }
    anime.description = xpath(res, '//*[@class="review-content"]/text()').first;

    anime.genre = xpath(res, '//*[@class="review-author-info"]/a/text()');
    final epUrls =
        xpath(
          res,
          '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/@href',
        ).reversed.toList();
    final names =
        xpath(
          res,
          '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/text()',
        ).reversed.toList();

    List<MChapter>? episodesList = [];
    for (var i = 0; i < epUrls.length; i++) {
      MChapter episode = MChapter();
      episode.name = names[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }

    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    final urls = xpath(res, '//*[@id="streamlinks"]/a/@data-src');
    final qualities = xpath(res, '//*[@id="streamlinks"]/a/span/text()');
    final hosterSelection = preferenceHosterSelection(source.id);
    List<MVideo> videos = [];
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      final quality = getQuality(qualities[i]);
      List<MVideo> a = [];

      if (url.contains("https://doo") && hosterSelection.contains("Dood")) {
        a = await doodExtractor(url, "DoodStream - $quality");
      } else if (url.contains("mp4upload") &&
          hosterSelection.contains("Mp4upload")) {
        a = await mp4UploadExtractor(url, null, "", "");
      } else if (url.contains("ok.ru") && hosterSelection.contains("Okru")) {
        a = await okruExtractor(url);
      } else if (url.contains("voe.sx") && hosterSelection.contains("Voe")) {
        a = await voeExtractor(url, "VoeSX $quality");
      } else if (containsVidBom(url) && hosterSelection.contains("VidBom")) {
        a = await vidBomExtractor(url);
      }
      videos.addAll(a);
    }
    return sortVideos(videos, source.id);
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
        key: "preferred_quality",
        title: "Preferred Quality",
        summary: "",
        valueIndex: 1,
        entries: ["1080p", "720p", "480p", "360p"],
        entryValues: ["1080", "720", "480", "360"],
      ),
      MultiSelectListPreference(
        key: "hoster_selection",
        title: "Enable/Disable Hosts",
        summary: "",
        entries: ["Dood", "Voe", "Mp4upload", "VidBom", "Okru"],
        entryValues: ["Dood", "Voe", "Mp4upload", "VidBom", "Okru"],
        values: ["Dood", "Voe", "Mp4upload", "VidBom", "Okru"],
      ),
    ];
  }

  List<MVideo> sortVideos(List<MVideo> videos, int sourceId) {
    String quality = getPreferenceValue(sourceId, "preferred_quality");

    videos.sort((MVideo a, MVideo b) {
      int qualityMatchA = 0;
      if (a.quality.contains(quality)) {
        qualityMatchA = 1;
      }
      int qualityMatchB = 0;
      if (b.quality.contains(quality)) {
        qualityMatchB = 1;
      }
      if (qualityMatchA != qualityMatchB) {
        return qualityMatchB - qualityMatchA;
      }

      final regex = RegExp(r'(\d+)p');
      final matchA = regex.firstMatch(a.quality);
      final matchB = regex.firstMatch(b.quality);
      final int qualityNumA = int.tryParse(matchA?.group(1) ?? '0') ?? 0;
      final int qualityNumB = int.tryParse(matchB?.group(1) ?? '0') ?? 0;
      return qualityNumB - qualityNumA;
    });

    return videos;
  }

  List<String> preferenceHosterSelection(int sourceId) {
    return getPreferenceValue(sourceId, "hoster_selection");
  }

  String getQuality(String quality) {
    quality = quality.replaceAll(" ", "");
    if (quality == "HD") {
      return "720p";
    } else if (quality == "FHD") {
      return "1080p";
    } else if (quality == "SD") {
      return "480p";
    }
    return "240p";
  }

  bool containsVidBom(String url) {
    url = url;
    final list = ["vidbam", "vadbam", "vidbom", "vidbm"];
    for (var n in list) {
      if (url.contains(n)) {
        return true;
      }
    }
    return false;
  }
}

OkAnime main(MSource source) {
  return OkAnime(source: source);
}

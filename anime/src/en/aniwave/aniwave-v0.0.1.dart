import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Aniwave extends MProvider {
  Aniwave();

  @override
  Future<MPages> getPopular(MSource source, int page) async {
    final data = {"url": "${source.baseUrl}/filter?sort=trending&page=$page"};
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MPages> getLatestUpdates(MSource source, int page) async {
    final data = {
      "url": "${source.baseUrl}/filter?sort=recently_updated&page=$page"
    };
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MPages> search(MSource source, String query, int page) async {
    final data = {"url": "${source.baseUrl}/filter?keyword=$query"};
    final res = await http('GET', json.encode(data));
    return parseAnimeList(res);
  }

  @override
  Future<MManga> getDetail(MSource source, String url) async {
    final statusList = [
      {"Releasing": 0, "Completed": 1}
    ];
    final data = {"url": "${source.baseUrl}${url}"};
    final res = await http('GET', json.encode(data));
    MManga anime = MManga();
    final status = xpath(res, '//div[contains(text(),"Status")]/span/text()');
    if (status.isNotEmpty) {
      anime.status = parseStatus(status.first, statusList);
    }
    final description = xpath(res,
        '//*[contains(@class,"synopsis")]/div[@class="shorting"]/div[@class="content"]/text()');
    if (description.isNotEmpty) {
      anime.description = description.first;
    }
    final author = xpath(res, '//div[contains(text(),"Studio")]/span/text()');
    if (author.isNotEmpty) {
      anime.author = author.first;
    }

    anime.genre = xpath(res, '//div[contains(text(),"Genre")]/span/a/text()');
    final id = querySelectorAll(res,
            selector: "div[data-id]",
            typeElement: 3,
            attributes: "data-id",
            typeRegExp: 0)
        .first;
    final encrypt = vrfEncrypt(id);
    final vrf = "vrf=${Uri.encodeComponent(encrypt)}";
    final dataEp = {"url": "${source.baseUrl}/ajax/episode/list/$id?$vrf"};
    final resEp = await http('GET', json.encode(dataEp));
    final html = json.decode(resEp)["result"];
    List<MChapter>? episodesList = [];
    final epsHtml = querySelectorAll(html,
        selector: "div.episodes ul > li",
        typeElement: 2,
        attributes: "",
        typeRegExp: 0);
    for (var epHtml in epsHtml) {
      final title = xpath(epHtml, '//li/@title').isNotEmpty
          ? xpath(epHtml, '//li/@title').first
          : "";
      final ids = xpath(epHtml, '//a/@data-ids').first;
      final sub = xpath(epHtml, '//a/@data-sub').first;
      final dub = xpath(epHtml, '//a/@data-dub').first;
      final softsub = title.toLowerCase().contains("softsub") ? "1" : "";
      final fillerEp = title.toLowerCase().contains("filler") ? "1" : "";
      final epNum = xpath(epHtml, '//a/@data-num').first;
      String scanlator = "";
      if (sub == "1") {
        scanlator += "Sub";
      }
      if (softsub == "1") {
        scanlator += ", Softsub";
      }
      if (dub == "1") {
        scanlator += ", Dub";
      }
      if (fillerEp == "1") {
        scanlator += ", • Filler Episode";
      }
      MChapter episode = MChapter();
      episode.name = "Episode $epNum";
      episode.scanlator = scanlator;
      episode.url = "$ids&epurl=$url/ep-$epNum";
      episodesList.add(episode);
    }

    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(MSource source, String url) async {
    final ids = substringBefore(url, "&");
    final encrypt = vrfEncrypt(ids);
    final vrf = "vrf=${Uri.encodeComponent(encrypt)}";
    final res = await http('GET',
        json.encode({"url": "${source.baseUrl}/ajax/server/list/$ids?$vrf"}));
    final html = json.decode(res)["result"];
    final vidsHtml = querySelectorAll(html,
        selector: "div.servers > div",
        typeElement: 2,
        attributes: "",
        typeRegExp: 0);
    List<MVideo> videos = [];
    for (var vidHtml in vidsHtml) {
      final type = xpath(vidHtml, '//div/@data-type').first;
      final serversIds = xpath(vidHtml, '//li/@data-link-id');
      for (int i = 0; i < serversIds.length; i++) {
        final serverId = serversIds[i];

        final encrypt = vrfEncrypt(serverId);
        final vrf = "vrf=${Uri.encodeComponent(encrypt)}";
        final res = await http(
            'GET',
            json.encode(
                {"url": "${source.baseUrl}/ajax/server/$serverId?$vrf"}));
        final status = json.decode(res)["status"];
        if (status == 200) {
          List<MVideo> a = [];
          final url = vrfDecrypt(json.decode(res)["result"]["url"]);
          if (url.contains("mp4upload")) {
            a = await mp4UploadExtractor(url, null, "", type);
          } else if (url.contains("streamtape")) {
            a = await streamTapeExtractor(url, "StreamTape - $type");
          } else if (url.contains("filemoon")) {
            a = await filemoonExtractor(url, "", type);
          }
          videos.addAll(a);
        }
      }
    }

    return videos;
  }

  MPages parseAnimeList(String res) {
    List<MManga> animeList = [];
    final urls = xpath(res, '//div[@class="item "]/div/div/div/a/@href');
    final names = xpath(res, '//div[@class="item "]/div/div/div/a/text()');
    final images = xpath(res, '//div[@class="item "]/div/div/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }

    return MPages(animeList, true);
  }

  List<int> rc4Encrypt(String key, List<int> message) {
    List<int> _key = utf8.encode(key);
    int _i = 0, _j = 0;
    List<int> _box = List.generate(256, (i) => i);

    int x = 0;
    for (int i = 0; i < 256; i++) {
      x = (x + _box[i] + _key[i % _key.length]) % 256;
      var tmp = _box[i];
      _box[i] = _box[x];
      _box[x] = tmp;
    }

    List<int> out = [];
    for (var char in message) {
      _i = (_i + 1) % 256;
      _j = (_j + _box[_i]) % 256;

      var tmp = _box[_i];
      _box[_i] = _box[_j];
      _box[_j] = tmp;

      final c = char ^ (_box[(_box[_i] + _box[_j]) % 256]);
      out.add(c);
    }

    return out;
  }

  String vrfEncrypt(String input) {
    final rc4 = rc4Encrypt("ysJhV6U27FVIjjuk", input.codeUnits);
    final vrf = base64Url.encode(rc4);
    final vrf1 = base64.encode(vrf.codeUnits);
    List<int> vrf2 = vrfShift(vrf1.codeUnits);
    final vrf3 = base64.encode(vrf2);
    return utf8.decode(rot13(vrf3.codeUnits));
  }

  String vrfDecrypt(String input) {
    final decode = base64Url.decode(input);
    final rc4 = rc4Encrypt("hlPeNwkncH0fq9so", decode);
    return Uri.decodeComponent(utf8.decode(rc4));
  }

  List<int> vrfShift(List<int> vrf) {
    var shifts = [-3, 3, -4, 2, -2, 5, 4, 5];
    for (var i = 0; i < vrf.length; i++) {
      var shift = shifts[i % 8];
      vrf[i] = (vrf[i] + shift) & 0xFF;
    }
    return vrf;
  }

  List<int> rot13(List<int> vrf) {
    for (var i = 0; i < vrf.length; i++) {
      var byte = vrf[i];
      if (byte >= 'A'.codeUnitAt(0) && byte <= 'Z'.codeUnitAt(0)) {
        vrf[i] = (byte - 'A'.codeUnitAt(0) + 13) % 26 + 'A'.codeUnitAt(0);
      } else if (byte >= 'a'.codeUnitAt(0) && byte <= 'z'.codeUnitAt(0)) {
        vrf[i] = (byte - 'a'.codeUnitAt(0) + 13) % 26 + 'a'.codeUnitAt(0);
      }
    }
    return vrf;
  }
}

Map<String, String> getMirrorPref() {
  return {
    "aniwave.to": "https://aniwave.to",
    "aniwave.bz": "https://aniwave.bz",
    "aniwave.ws": "https://aniwave.ws",
  };
}

Aniwave main() {
  return Aniwave();
}

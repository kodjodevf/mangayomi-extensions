import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class YomiRoll extends MProvider {
  YomiRoll({required this.source});

  MSource source;

  final Client client = Client(source);

  String crUrl = "https://beta-api.crunchyroll.com";
  String crApiUrl = "https://beta-api.crunchyroll.com/content/v2";

  @override
  Future<MPages> getPopular(int page) async {
    final start = page != 1 ? "start=${(page - 1) * 36}&" : "";
    final res = await interceptAccesTokenAndGetResponse(
        "$crApiUrl/discover/browse?${start}n=36&sort_by=popularity&locale=en-US");
    return await animeFromRes(res, start);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final start = page != 1 ? "start=${(page - 1) * 36}&" : "";
    final res = await interceptAccesTokenAndGetResponse(
        "$crApiUrl/discover/browse?${start}n=36&sort_by=newly_added&locale=en-US");
    return await animeFromRes(res, start);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final filters = filterList.filters;
    String url = "";
    final start = page != 1 ? "start=${(page - 1) * 36}&" : "";
    if (query.isNotEmpty) {
      final typeFilter =
          filters.where((e) => e.type == "TypeFilter" ? true : false).toList();
      String type = "top_results";
      if (typeFilter.isNotEmpty) {
        type = typeFilter.first.values[typeFilter.first.state].value;
      }
      url =
          "$crApiUrl/discover/search?${start}n=36&q=${query.toLowerCase().replaceAll(" ", "+")}&type=$type";
    } else {
      url = "$crApiUrl/discover/browse?${start}n=36";
      for (var filter in filters) {
        if (filter.type == "MediaFilter") {
          url += filter.values[filter.state].value;
        } else if (filter.type == "CategoryFilter") {
          url += filter.values[filter.state].value;
        } else if (filter.type == "SortFilter") {
          url += "&sort_by=${filter.values[filter.state].value}";
        } else if (filter.type == "LanguageFilter") {
          final categories =
              (filter.state as List).where((e) => e.state).toList();
          if (categories.isNotEmpty) {
            for (var st in categories) {
              url += st.value;
            }
          }
        }
      }
    }
    String res = await interceptAccesTokenAndGetResponse(url);
    if (query.isNotEmpty) {
      final resJson = json.decode(res)["data"][0];
      res = json.encode({"total": resJson["count"], "data": resJson["items"]});
    } else {}

    return await animeFromRes(res, start);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final media = json.decode(url);
    final id = media["id"];
    final type = media["type"];
    bool isSerie = type == "series";
    String res = "";
    if (isSerie) {
      res = await interceptAccesTokenAndGetResponse(
          "$crApiUrl/cms/series/$id?locale=en-US");
    } else {
      res = await interceptAccesTokenAndGetResponse(
          "$crApiUrl/cms/movie_listings/$id/movies");
    }
    Map<String, dynamic> data =
        (json.decode(res)["data"] as List<Map<String, dynamic>>).first;
    MManga anime = MManga();
    anime.author = data["content_provider"];
    String description = data["description"];
    description += "\n\nLanguage:";
    if (data["is_subbed"]) {
      description += " Sub";
    }
    if (data["is_dubbed"]) {
      description += " Dub";
    }
    description += "\nMaturity Ratings: ";
    description += (data["maturity_ratings"] as List).join(", ");
    description += "\n\nAudio: ";
    description += (data["audio_locales"] as List)
        .map((e) => getLocale(e))
        .toList()
        .toSet()
        .toList()
        .join(", ");
    description += "\n\nSubs: ";
    description += (data["subtitle_locales"] as List)
        .map((e) => getLocale(e))
        .toList()
        .toSet()
        .toList()
        .join(", ");
    anime.description = description;

    String seasonsRes = "";
    if (isSerie) {
      seasonsRes = await interceptAccesTokenAndGetResponse(
          "$crApiUrl/cms/series/$id/seasons");
    } else {
      seasonsRes = await interceptAccesTokenAndGetResponse(
          "$crApiUrl/cms/movie_listings/$id/movies");
    }

    List<Map<String, dynamic>> seasons = json.decode(seasonsRes)["data"];
    List<MChapter>? episodesList = [];
    if (isSerie) {
      seasons.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          (a["season_number"] as int).compareTo((b["season_number"] as int)));

      for (var season in seasons) {
        final episodesRes = await interceptAccesTokenAndGetResponse(
            '$crApiUrl/cms/seasons/${season["id"]}/episodes');
        List<Map<String, dynamic>> episodes = json.decode(episodesRes)["data"];
        episodes.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
          String aS = getMapValue(json.encode(a), "episode_number");
          if (aS.isEmpty) {
            aS = "0";
          }
          String bS = getMapValue(json.encode(b), "episode_number");
          if (bS.isEmpty) {
            bS = "0";
          }
          return int.parse(aS).compareTo(int.parse(bS));
        });
        for (var episode in episodes) {
          MChapter ep = MChapter();
          List<Map<String, dynamic>> urlMap = [];
          List<String> scanlator = [];
          if (getMapValue(json.encode(episode), "versions").isNotEmpty) {
            for (var version in episode["versions"]) {
              urlMap.add({
                "media_id": version["media_guid"],
                "audio": version["audio_locale"]
              });
              scanlator.add(substringBefore(version["audio_locale"], "-"));
            }
          } else {
            final mediaId = substringBefore(
                substringAfter(episode["streams_link"], "videos/"), "/streams");
            scanlator.add(substringBefore(episode["audio_locale"], "-"));
            urlMap.add({"media_id": mediaId, "audio": episode["audio_locale"]});
          }

          ep.url = json.encode(urlMap);
          final epNumber = getMapValue(json.encode(episode), "episode_number");
          String name = "";
          if (epNumber.isNotEmpty) {
            name =
                "Season ${season["season_number"]} Ep $epNumber: ${episode["title"]}";
          } else {
            name = episode["title"];
          }
          ep.name = name;
          ep.dateUpload = parseDates(
                  [episode["episode_air_date"]], "yyyy-MM-dd'T'HH:mm:ss", "en")
              .first;

          ep.scanlator = scanlator.join(", ");
          episodesList.add(ep);
        }
      }
    } else {
      for (var i = 0; i < seasons.length; i++) {
        MChapter ep = MChapter();
        final movie = seasons[i];
        ep.name = "Movie ${i + 1}";
        ep.url = json.encode({"media_id": movie["id"], "audio": ""});
        ep.dateUpload = parseDates([movie["premium_available_date"]],
                "yyyy-MM-dd'T'HH:mm:ss", "en")
            .first;
        episodesList.add(ep);
      }
    }
    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    List<Map<String, dynamic>> jsonList = json.decode(url);
    if (jsonList.isEmpty) throw "Episode List is empty";
    List<MVideo> videos = [];
    List<MTrack> subtitles = [];
    for (var v in jsonList) {
      final mediaId = v["media_id"];
      String audio = v["audio"];

      final res = await interceptAccesTokenAndGetResponse(
          '$crUrl/cms/v2{0}/videos/$mediaId/streams?Policy={1}&Signature={2}&Key-Pair-Id={3}');

      for (var ok
          in (json.decode(res)["subtitles"] as Map<String, dynamic>).entries) {
        try {
          MTrack subtitle = MTrack();
          subtitle
            ..label = getLocale(ok.value["locale"])
            ..file = ok.value["url"];
          subtitles.add(subtitle);
        } catch (_) {}
      }
      if (audio.isEmpty) {
        audio = getMapValue(res, "audio_locale");
        if (audio.isEmpty) {
          audio = "ja-JP";
        }
      }
      audio = getLocale(audio);
      for (var ok in (json.decode(res)["streams"]["adaptive_hls"]
              as Map<String, dynamic>)
          .entries) {
        final url = ok.value["url"];

        String hardsub = getMapValue(json.encode(ok.value), "hardsub_locale");
        if (hardsub.isNotEmpty) {
          hardsub = " - HardSub: $hardsub";
        } else {
          hardsub = " - SoftSub";
        }

        final res = await client.get(Uri.parse(url));
        if (res.statusCode == 200) {
          for (var it in substringAfter(res.body, "#EXT-X-STREAM-INF:")
              .split("#EXT-X-STREAM-INF:")) {
            final quality =
                "${substringBefore(substringBefore(substringAfter(substringAfter(it, "RESOLUTION="), "x"), ","), "\n")}p";

            String videoUrl = substringBefore(substringAfter(it, "\n"), "\n");

            MVideo video = MVideo();
            video
              ..url = videoUrl
              ..originalUrl = videoUrl
              ..quality = "$quality - Aud: $audio $hardsub"
              ..subtitles = sortSubs(subtitles);
            videos.add(video);
          }
        }
      }
    }
    return sortVideos(videos);
  }

  List<MTrack> sortSubs(List<MTrack> subs) {
    String lang = getPreferenceValue(source.id, "preferred_subLang");

    subs.sort((MTrack a, MTrack b) {
      int langMatchA = 0;
      if (a.label.contains(getLocale(lang))) {
        langMatchA = 1;
      }
      int langMatchB = 0;
      if (b.label.contains(getLocale(lang))) {
        langMatchB = 1;
      }
      return langMatchB - langMatchA;
    });
    return subs;
  }

  Future<MPages> animeFromRes(String res, String page) async {
    int position = int.tryParse(page) ?? 0;
    bool hasNextPage = position + 36 < json.decode(res)["total"];
    List<Map<String, dynamic>> dataListJson = json.decode(res)["data"];
    List<MManga> animeList = [];
    for (var data in dataListJson) {
      MManga anime = MManga();
      final type = data["type"];
      final title = data["title"];
      if (type == "series") {
        final res = getMapValue(
            json.encode(data["series_metadata"]), "tenant_categories",
            encode: true);
        if (res.isNotEmpty) {
          anime.genre = json.decode(res);
        }
      } else {
        final res = getMapValue(
            json.encode(data["movie_metadata"]), "tenant_categories",
            encode: true);
        if (res.isNotEmpty) {
          anime.genre = json.decode(res);
          anime.status = MStatus.completed;
        }
      }
      String description = data["description"];
      String metadata = type == "series" ? "series_metadata" : "movie_metadata";
      description += "\n\nLanguage:";
      if (data[metadata]["is_subbed"]) {
        description += " Sub";
      }
      if (data[metadata]["is_dubbed"]) {
        description += " Dub";
      }
      description += "\nMaturity Ratings: ";
      description += (data[metadata]["maturity_ratings"] as List).join(", ");
      description += "\n\nAudio: ";
      description += (data[metadata]["audio_locales"] as List)
          .map((e) => getLocale(e))
          .toList()
          .toSet()
          .toList()
          .join(", ");
      description += "\n\nSubs: ";
      description += (data[metadata]["subtitle_locales"] as List)
          .map((e) => getLocale(e))
          .toList()
          .toSet()
          .toList()
          .join(", ");
      anime.description = description;
      anime.name = title;
      anime.imageUrl = ((data["images"]["poster_tall"][0] as List).last
          as Map<String, dynamic>)["source"];
      anime.link = json.encode({"id": data["id"], "type": type});
      animeList.add(anime);
    }
    return MPages(animeList, hasNextPage);
  }

  Future<String> interceptAccesTokenAndGetResponse(String url) async {
    final accessToken = await getAccessToken(false);
    final res = await checkUrlForNewRequest(url, accessToken);
    Response response =
        await client.get(Uri.parse(res["url"]), headers: res["headers"]);
    if (response.statusCode == 401) {
      Map<String, dynamic> res;
      final newAccessToken = await getAccessToken(false);
      if (accessToken != newAccessToken) {
        res = await checkUrlForNewRequest(url, newAccessToken);
      }
      final refreshedToken = await getAccessToken(true);

      res = await checkUrlForNewRequest(url, refreshedToken);
      Response response =
          await client.get(Uri.parse(res["url"]), headers: res["headers"]);
      return response.body;
    } else {
      return response.body;
    }
  }

  Future<Map<String, dynamic>> getAccessToken(bool force) async {
    String token = getPrefStringValue(source.id, "access_token", "");
    if (!force && token.isNotEmpty) {
      return json.decode(token);
    } else {
      final token = await refreshAccessToken();
      setPrefStringValue(source.id, "access_token", token);
      return json.decode(token);
    }
  }

  Future<Map<String, dynamic>> checkUrlForNewRequest(
      String url, Map<String, dynamic> tokenData) async {
    if (url.contains("/cms/v2")) {
      url = url
          .replaceAll("{0}", tokenData["bucket"])
          .replaceAll("{1}", tokenData["policy"])
          .replaceAll("{2}", tokenData["signature"])
          .replaceAll("{3}", tokenData["key_pair_id"]);
    }
    return ({
      "url": url,
      "headers": {
        "authorization":
            "${tokenData["token_type"]} ${tokenData["access_token"]}"
      }
    });
  }

  Future<String> refreshAccessToken() async {
    setPrefStringValue(source.id, "access_token", "");
    Response response = await client.get(Uri.parse(
        "https://raw.githubusercontent.com/Samfun75/File-host/main/aniyomi/refreshToken.txt"));
    final refreshToken = response.body.replaceAll(RegExp(r'[\n\r]'), '');
    Response tokenResponse = await client.post(
      Uri.parse("$crUrl/auth/v1/token"),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic b2VkYXJteHN0bGgxanZhd2ltbnE6OWxFaHZIWkpEMzJqdVY1ZFc5Vk9TNTdkb3BkSnBnbzE=',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'scope': 'offline_access',
      },
    );
    final tokenJson = json.decode(tokenResponse.body);

    final res = await checkUrlForNewRequest("$crUrl/index/v2", {
      "access_token": tokenJson["access_token"],
      "token_type": tokenJson["token_type"]
    });

    final policyJson = json.decode(
        (await client.get(Uri.parse(res["url"]), headers: res["headers"]))
            .body);

    return json.encode({
      "access_token": tokenJson["access_token"],
      "token_type": tokenJson["token_type"],
      "policy": policyJson['cms']['policy'],
      "signature": policyJson['cms']['signature'],
      "key_pair_id": policyJson['cms']['key_pair_id'],
      "bucket": policyJson['cms']['bucket']
    });
  }

  List<MVideo> sortVideos(List<MVideo> videos) {
    String quality = getPreferenceValue(source.id, "preferred_quality");
    String dub = getPreferenceValue(source.id, "preferred_audioLang");
    String sub = getPreferenceValue(source.id, "preferred_subLang");
    String subType = getPreferenceValue(source.id, "preferred_sub_type1");
    videos.sort((MVideo a, MVideo b) {
      if (subType == "HardSub") {
        int qualityMatchA = 0;
        if (a.quality.contains(quality) &&
            a.quality.contains("Aud: ${getLocale(dub)}") &&
            a.quality.contains("HardSub: $sub")) {
          qualityMatchA = 1;
        }
        int qualityMatchB = 0;
        if (b.quality.contains(quality) &&
            b.quality.contains("Aud: ${getLocale(dub)}") &&
            b.quality.contains("HardSub: $sub")) {
          qualityMatchB = 1;
        }
        if (qualityMatchA != qualityMatchB) {
          return qualityMatchB - qualityMatchA;
        }
      } else {
        int qualityMatchA = 0;
        if (a.quality.contains(quality) &&
            a.quality.contains("Aud: ${getLocale(dub)}") &&
            a.quality.contains(subType)) {
          qualityMatchA = 1;
        }
        int qualityMatchB = 0;
        if (b.quality.contains(quality) &&
            b.quality.contains("Aud: ${getLocale(dub)}") &&
            b.quality.contains(subType)) {
          qualityMatchB = 1;
        }
        if (qualityMatchA != qualityMatchB) {
          return qualityMatchB - qualityMatchA;
        }
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

  String getLocale(String key) {
    return getMapValue(json.encode(locale), key);
  }

  Map<String, String> locale = {
    "ar-ME": "Arabic",
    "ar-SA": "Arabic (Saudi Arabia)",
    "de-DE": "German",
    "en-US": "English",
    "en-IN": "English (India)",
    "es-419": "Spanish (América Latina)",
    "es-ES": "Spanish (España)",
    "es-LA": "Spanish (América Latina)",
    "fr-FR": "French",
    "ja-JP": "Japanese",
    "hi-IN": "Hindi",
    "it-IT": "Italian",
    "ko-KR": "Korean",
    "pt-BR": "Português (Brasil)",
    "pt-PT": "Português (Portugal)",
    "pl-PL": "Polish",
    "ru-RU": "Russian",
    "tr-TR": "Turkish",
    "uk-UK": "Ukrainian",
    "he-IL": "Hebrew",
    "ro-RO": "Romanian",
    "sv-SE": "Swedish",
    "zh-CN": "Chinese (PRC)",
    "zh-HK": "Chinese (Hong Kong)",
    "zh-TW": "Chinese (Taiwan)",
    "ca-ES": "Català",
    "id-ID": "Bahasa Indonesia",
    "ms-MY": "Bahasa Melayu",
    "ta-IN": "Tamil",
    "te-IN": "Telugu",
    "th-TH": "Thai",
    "vi-VN": "Vietnamese"
  };
  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("Search Filter (ignored if browsing)"),
      SelectFilter("TypeFilter", "Type", 0, [
        SelectFilterOption("Top Results", "top_results"),
        SelectFilterOption("Series", "series"),
        SelectFilterOption("Movies", "movie_listing")
      ]),
      SeparatorFilter(),
      SelectFilter("CategoryFilter", "Category", 0, [
        {
          "type": "SelectOption",
          "filter": {"name": "-", "value": ""}
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Action", "value": "&categories=action"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Adventure",
            "value": "&categories=action,adventure"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Comedy",
            "value": "&categories=action,comedy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Drama",
            "value": "&categories=action,drama"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Fantasy",
            "value": "&categories=action,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Historical",
            "value": "&categories=action,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Post-Apocalyptic",
            "value": "&categories=action,post-apocalyptic"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Sci-Fi",
            "value": "&categories=action,sci-fi"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Supernatural",
            "value": "&categories=action,supernatural"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Action, Thriller",
            "value": "&categories=action,thriller"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Adventure", "value": "&categories=adventure"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Adventure, Fantasy",
            "value": "&categories=adventure,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Adventure, Isekai",
            "value": "&categories=adventure,isekai"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Adventure, Romance",
            "value": "&categories=adventure,romance"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Adventure, Sci-Fi",
            "value": "&categories=adventure,sci-fi"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Adventure, Supernatural",
            "value": "&categories=adventure,supernatural"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Comedy", "value": "&categories=comedy"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Drama",
            "value": "&categories=comedy,drama"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Fantasy",
            "value": "&categories=comedy,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Historical",
            "value": "&categories=comedy,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Music",
            "value": "&categories=comedy,music"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Romance",
            "value": "&categories=comedy,romance"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Sci-Fi",
            "value": "&categories=comedy,sci-fi"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Slice of life",
            "value": "&categories=comedy,slice+of+life"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Comedy, Supernatural",
            "value": "&categories=comedy,supernatural"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Drama", "value": "&categories=drama"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Drama, Adventure",
            "value": "&categories=drama,adventure"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Drama, Fantasy",
            "value": "&categories=drama,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Drama, Historical",
            "value": "&categories=drama,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Drama, Mecha", "value": "&categories=drama,mecha"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Drama, Mystery",
            "value": "&categories=drama,mystery"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Drama, Romance",
            "value": "&categories=drama,romance"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Drama, Sci-Fi",
            "value": "&categories=drama,sci-fi"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Drama, Slice of life",
            "value": "&categories=drama,slice+of+life"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Fantasy", "value": "&categories=fantasy"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Fantasy, Historical",
            "value": "&categories=fantasy,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Fantasy, Isekai",
            "value": "&categories=fantasy,isekai"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Fantasy, Mystery",
            "value": "&categories=fantasy,mystery"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Fantasy, Romance",
            "value": "&categories=fantasy,romance"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Fantasy, Supernatural",
            "value": "&categories=fantasy,supernatural"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Music", "value": "&categories=music"}
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Music, Drama", "value": "&categories=music,drama"}
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Music, Idols", "value": "&categories=music,idols"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Music, slice of life",
            "value": "&categories=music,slice+of+life"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Romance", "value": "&categories=romance"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Romance, Harem",
            "value": "&categories=romance,harem"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Romance, Historical",
            "value": "&categories=romance,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Sci-Fi", "value": "&categories=sci-fi"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Sci-Fi, Fantasy",
            "value": "&categories=sci-fi,Fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Sci-Fi, Historical",
            "value": "&categories=sci-fi,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Sci-Fi, Mecha",
            "value": "&categories=sci-fi,mecha"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Seinen", "value": "&categories=seinen"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Seinen, Action",
            "value": "&categories=seinen,action"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Seinen, Drama",
            "value": "&categories=seinen,drama"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Seinen, Fantasy",
            "value": "&categories=seinen,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Seinen, Historical",
            "value": "&categories=seinen,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Seinen, Supernatural",
            "value": "&categories=seinen,supernatural"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Shojo", "value": "&categories=shojo"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shojo, Fantasy",
            "value": "&categories=shojo,Fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shojo, Magical Girls",
            "value": "&categories=shojo,magical-girls"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shojo, Romance",
            "value": "&categories=shojo,romance"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shojo, Slice of life",
            "value": "&categories=shojo,slice+of+life"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Shonen", "value": "&categories=shonen"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Action",
            "value": "&categories=shonen,action"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Adventure",
            "value": "&categories=shonen,adventure"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Comedy",
            "value": "&categories=shonen,comedy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Drama",
            "value": "&categories=shonen,drama"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Fantasy",
            "value": "&categories=shonen,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Mystery",
            "value": "&categories=shonen,mystery"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Post-Apocalyptic",
            "value": "&categories=shonen,post-apocalyptic"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Shonen, Supernatural",
            "value": "&categories=shonen,supernatural"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Slice of life",
            "value": "&categories=slice+of+life"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Slice of life, Fantasy",
            "value": "&categories=slice+of+life,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Slice of life, Romance",
            "value": "&categories=slice+of+life,romance"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Slice of life, Sci-Fi",
            "value": "&categories=slice+of+life,sci-fi"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Sports", "value": "&categories=sports"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Sports, Action",
            "value": "&categories=sports,action"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Sports, Comedy",
            "value": "&categories=sports,comedy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Sports, Drama",
            "value": "&categories=sports,drama"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Supernatural",
            "value": "&categories=supernatural"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Supernatural, Drama",
            "value": "&categories=supernatural,drama"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Supernatural, Historical",
            "value": "&categories=supernatural,historical"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Supernatural, Mystery",
            "value": "&categories=supernatural,mystery"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Supernatural, Slice of life",
            "value": "&categories=supernatural,slice+of+life"
          }
        },
        {
          "type": "SelectOption",
          "filter": {"name": "Thriller", "value": "&categories=thriller"}
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Thriller, Drama",
            "value": "&categories=thriller,drama"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Thriller, Fantasy",
            "value": "&categories=thriller,fantasy"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Thriller, Sci-Fi",
            "value": "&categories=thriller,sci-fi"
          }
        },
        {
          "type": "SelectOption",
          "filter": {
            "name": "Thriller, Supernatural",
            "value": "&categories=thriller,supernatural"
          }
        }
      ]),
      HeaderFilter("Browse Filters (ignored if searching)"),
      SelectFilter("SortFilter", "Sort By", 0, [
        SelectFilterOption("Popular", "popularity"),
        SelectFilterOption("New", "newly_added"),
        SelectFilterOption("Alphabetical", "alphabetical")
      ]),
      SelectFilter("MediaFilter", "Media", 0, [
        SelectFilterOption("All", ""),
        SelectFilterOption("Series", "&type=series"),
        SelectFilterOption("Movies", "&type=movie_listing"),
      ]),
      GroupFilter("LanguageFilter", "Language", [
        CheckBoxFilter("Sub", "&is_subbed=true"),
        CheckBoxFilter("Dub", "&is_dubbed=true")
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
          key: "preferred_quality",
          title: "Preferred Quality",
          summary: "",
          valueIndex: 0,
          entries: ["1080p", "720p", "480p", "360p", "240p", "80p"],
          entryValues: ["1080p", "720p", "480p", "360p", "240p", "80p"]),
      ListPreference(
          key: "preferred_audioLang",
          title: "Preferred Audio Language",
          summary: "",
          valueIndex: 3,
          entries: locale.entries.map((e) => e.value).toList(),
          entryValues: locale.entries.map((e) => e.key).toList()),
      ListPreference(
          key: "preferred_subLang",
          title: "Preferred Sub language",
          summary: "",
          valueIndex: 3,
          entries: locale.entries.map((e) => e.value).toList(),
          entryValues: locale.entries.map((e) => e.key).toList()),
      ListPreference(
          key: "preferred_sub_type1",
          title: "Preferred Sub Type",
          summary: "",
          valueIndex: 0,
          entries: ["Softsub", "Hardsub"],
          entryValues: ["SoftSub", "HardSub"]),
    ];
  }
}

YomiRoll main(MSource source) {
  return YomiRoll(source: source);
}

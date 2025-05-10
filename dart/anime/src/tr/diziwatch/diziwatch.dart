import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class DiziWatch extends MProvider {
  DiziWatch({required this.source});

  MSource source;

  final Client client = Client();

  @override
  bool get supportsLatest => true;

  @override
  Map<String, String> get headers => {};

  Future<MPages> parseMainList(int index) async {
    MDocument dom = parseHtml(
      (await client.get(Uri.parse(source.baseUrl))).body,
    );
    List<MManga> list = [];
    MElement containingElement = dom.select("#list-series-hizala2")[index];
    List<MElement> results = containingElement.select("#list-series-main");
    for (MElement result in results) {
      MElement a = result.selectFirst("a");
      MElement img = a.selectFirst("img");
      MManga anime = new MManga();
      anime.name = img.attr("alt");
      anime.link = a.getHref;
      anime.imageUrl = img.getSrc;
      list.add(anime);
    }

    return MPages(list, false);
  }

  @override
  Future<MPages> getPopular(int page) async {
    return parseMainList(1);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    return parseMainList(2);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    String orderby = "";
    String year = "";
    String imdb = "";
    String genre = "";
    for (var filter in filterList.filters) {
      if (filter.type == "Sort") {
        orderby = filter.values[filter.state].value;
      } else if (filter.type == "Year") {
        year = filter.state;
      } else if (filter.type == "MinIMDBRating") {
        imdb = filter.values[filter.state].value;
      } else if (filter.type == "Genre") {
        genre = filter.values[filter.state].value;
      }
    }
    MDocument dom = parseHtml(
      (await client.get(
        Uri.parse(
          "${source.baseUrl}/anime-arsivi/page/${page}/?orderby=${orderby}&yil=${year}&imdb=${imdb}&isim=${query}&tur=${genre}",
        ),
      )).body,
    );
    List<MElement> results = dom.select("#list-series");
    List<MManga> list = [];
    for (MElement result in results) {
      MElement a = result.select("a")[1];
      MElement img = a.selectFirst("img");
      MManga anime = new MManga();
      anime.name = result.selectFirst("div.cat-title a").text;
      anime.link = a.getHref;
      anime.imageUrl = img.getSrc;
      list.add(anime);
    }

    MElement paginateLinksDiv = dom.selectFirst("div.paginate-links");
    int lastPage = int.parse(
      paginateLinksDiv.selectFirst("a.next").previousElementSibling.text ?? "1",
    );

    return MPages(list, lastPage > page);
  }

  @override
  Future<MManga> getDetail(String url) async {
    MDocument dom = parseHtml((await client.get(Uri.parse(url))).body);

    var anime = new MManga();

    anime.name = dom.selectFirst("h1.title-border").text;
    anime.link = url;
    anime.imageUrl = dom.selectFirst("div.category_image img").getSrc;
    anime.description = dom.selectFirst("div#series-info").text;

    List<String> genres = dom.selectFirst("span.dizi-tur").text.split(", ");
    genres.remove("Anime"); // not needed
    anime.genre = genres;

    List<MElement> results = dom.select("div.bolumust");
    List<MChapter> chapters = [];
    for (MElement result in results) {
      MElement a = result.select("a")[1];
      MChapter chapter = new MChapter();
      chapter.name =
          result.selectFirst(".baslik").text +
          " | " +
          result.selectFirst("#bolum-ismi").text;
      chapter.url = a.getHref;
      chapters.add(chapter);
    }
    anime.chapters = chapters.reversed.toList();

    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    MDocument dom = parseHtml((await client.get(Uri.parse(url))).body);
    String id = dom.selectFirst("#takip_et_izledim_Calis").attr("data-ilanid");
    var json =
        json.decode(
          (await client.get(
            Uri.parse(
              "${source.baseUrl}/wp-admin/admin-ajax.php?action=playlist&pid=${id}",
            ),
          )).body,
        )[0];
    var sources = json["sources"];
    List<MVideo> videos = [];
    for (var source in sources) {
      MVideo video = new MVideo();
      video.url = source["file"];
      video.originalUrl = source["file"];
      video.quality = source["label"];
      video.headers = {"Referer": url};
      videos.add(video);
    }

    String quality = getPreferenceValue(source.id, "preferred_quality");
    videos.sort(
      (MVideo a, MVideo b) =>
          (b.quality.contains(quality) ? 1 : 0) -
          (a.quality.contains(quality) ? 1 : 0),
    );

    return videos;
  }

  @override
  List<dynamic> getFilterList() {
    return [
      HeaderFilter("Filtrele"),
      SelectFilter("Sort", "Sırala", 0, [
        SelectFilterOption("IMDb Puanına Göre", "meta_value"),
        SelectFilterOption("Alfabetik", "name"),
        SelectFilterOption("Eklenme Tarihine Göre", "ID"),
      ]),
      TextFilter("Year", "Yapım Yılı"),
      SelectFilter("Genre", "Tür", 0, [
        SelectFilterOption("Kategori Seçin", ""),
        SelectFilterOption("Aksiyon", "aksiyon"),
        SelectFilterOption("Arabalar", "araba"),
        SelectFilterOption("Askeri", "askeri"),
        SelectFilterOption("Bilim Kurgu", "bilim"),
        SelectFilterOption("Büyü", "buyu"),
        SelectFilterOption("Doğaüstü Güçler", "doga"),
        SelectFilterOption("Dövüş Sanatları", "dovus"),
        SelectFilterOption("Dram", "dram"),
        SelectFilterOption("Ecchi", "ecchi"),
        SelectFilterOption("Fantastik", "fantastik"),
        SelectFilterOption("Gerilim", "gerilim"),
        SelectFilterOption("Gizem", "gizem"),
        SelectFilterOption("Harem", "harem"),
        SelectFilterOption("Isekai", "isekai"),
        SelectFilterOption("Komedi", "komedi"),
        SelectFilterOption("Korku", "korku"),
        SelectFilterOption("Macera", "macera"),
        SelectFilterOption("Mecha", "mecha"),
        SelectFilterOption("Müzik", "muzik"),
        SelectFilterOption("Okul", "okul"),
        SelectFilterOption("Oyun", "oyun"),
        SelectFilterOption("Parodi", "parodi"),
        SelectFilterOption("Polisiye", "polisiye"),
        SelectFilterOption("Psikolojik", "psikolojik"),
        SelectFilterOption("Romantizm", "romantizm"),
        SelectFilterOption("Samuray", "samuray"),
        SelectFilterOption("Seinen", "seinen"),
        SelectFilterOption("Shoujo", "shoujo"),
        SelectFilterOption("Shounen", "shounen"),
        SelectFilterOption("Spor", "spor"),
        SelectFilterOption("Suç", "suc"),
        SelectFilterOption("Süper Güçler", "super"),
        SelectFilterOption("Şeytanlar", "seytan"),
        SelectFilterOption("Şizofreni", "sizofreni"),
        SelectFilterOption("Tarihi", "tarihi"),
        SelectFilterOption("Uzay", "uzay"),
        SelectFilterOption("Vampir", "vampir"),
        SelectFilterOption("Yaşamdan Kesitler", "yasam"),
      ]),
      SelectFilter("MinIMDBRating", "Min. IMBD Puanı", 0, [
        SelectFilterOption(
          "1",
          "0",
        ), // value 1 looks like buggy so use 0 it wont make any difference.
        SelectFilterOption("2", "2"),
        SelectFilterOption("3", "3"),
        SelectFilterOption("4", "4"),
        SelectFilterOption("5", "5"),
        SelectFilterOption("6", "6"),
        SelectFilterOption("7", "7"),
        SelectFilterOption("8", "8"),
        SelectFilterOption("9", "9"),
      ]),
    ];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      ListPreference(
        key: "preferred_quality",
        title: "Tercih edilen kalite",
        summary: "",
        valueIndex: 0,
        entries: ["1080p", "480p"], //  I only saw 1080p and 480p in diziWatch.
        entryValues: ["1080", "480"],
      ),
    ];
  }
}

DiziWatch main(MSource source) {
  return DiziWatch(source: source);
}

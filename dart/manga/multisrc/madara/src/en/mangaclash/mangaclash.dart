import '../../../../../../../model/source.dart';

Source get mangaclashSource => _mangaclashSource;

Source _mangaclashSource = Source(
  name: "MangaClash",
  baseUrl: "https://toonclash.com",
  lang: "en",

  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/en/mangaclash/icon.png",
  dateFormat: "MM/dd/yy",
  dateFormatLocale: "en_us",
);

import '../../../../../../../model/source.dart';

Source get mangasparkSource => _mangasparkSource;
Source _mangasparkSource = Source(
  name: "MangaSpark",
  baseUrl: "https://manga-spark.net",
  lang: "ar",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/dart/manga/multisrc/madara/src/ar/mangaspark/icon.png",
  dateFormat: "d MMMM، yyyy",
  dateFormatLocale: "ar",
);

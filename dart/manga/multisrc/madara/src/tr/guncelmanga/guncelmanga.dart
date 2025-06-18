import '../../../../../../../model/source.dart';

Source get guncelmangaSource => _guncelmangaSource;
Source _guncelmangaSource = Source(
  name: "GuncelManga",
  baseUrl: "https://guncelmanga.net",
  lang: "tr",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/dart/manga/multisrc/madara/src/tr/guncelmanga/icon.png",
  dateFormat: "d MMMM yyyy",
  dateFormatLocale: "tr",
);

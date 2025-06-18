import '../../../../../../../model/source.dart';

Source get chibimangaSource => _chibimangaSource;

Source _chibimangaSource = Source(
  name: "Chibi Manga",
  baseUrl: "https://www.cmreader.info",
  lang: "en",

  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/en/chibimanga/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "en_us",
);

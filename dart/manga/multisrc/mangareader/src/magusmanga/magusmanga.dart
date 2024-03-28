import '../../../../../../model/source.dart';

Source get magusmangaSource => _magusmangaSource;

Source _magusmangaSource = Source(
  name: "Magus Manga",
  baseUrl: "https://magusmanga.com",
  lang: "ar",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/magusmanga/icon.png",
  dateFormat: "MMMMM d, yyyy",
  dateFormatLocale: "ar",
);

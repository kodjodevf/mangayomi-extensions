import '../../../../../../../model/source.dart';

Source get mangakingsSource => _mangakingsSource;
Source _mangakingsSource = Source(
  name: "Manga Kings",
  baseUrl: "https://mangakings.com.tr",
  lang: "tr",
  isNsfw: false,
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/tr/mangakings/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "tr",
);

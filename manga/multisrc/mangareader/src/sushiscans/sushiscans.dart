import '../../../../../model/source.dart';

Source get sushiscansSource => _sushiscansSource;

Source _sushiscansSource = Source(
  name: "Sushi-Scans",
  baseUrl: "https://anime-sama.me",
  lang: "fr",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/manga/multisrc/mangareader/src/sushiscans/icon.png",
  dateFormat: "MMMM d, yyyy",
  dateFormatLocale: "fr",
);

import '../../../../../../model/source.dart';

Source get sushiscanSource => _sushiscanSource;

Source _sushiscanSource = Source(
  name: "Sushi-Scan",
  baseUrl: "https://sushiscan.net",
  lang: "fr",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/sushiscan/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "fr",
);

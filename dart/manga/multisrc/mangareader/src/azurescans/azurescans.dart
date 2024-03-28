import '../../../../../../model/source.dart';

Source get azurescansSource => _azurescansSource;

Source _azurescansSource = Source(
  name: "Azure Scans",
  baseUrl: "https://azuremanga.com",
  lang: "en",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/azurescans/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "en_us",
);

import '../../../../../model/source.dart';

Source get legacyscansSource => _legacyscansSource;

Source _legacyscansSource = Source(
  name: "Legacy Scans",
  baseUrl: "https://legacy-scans.com",
  lang: "fr",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/legacyscans/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "en_us",
);

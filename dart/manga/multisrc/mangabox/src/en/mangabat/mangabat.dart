import '../../../../../../../model/source.dart';

Source get mangabatSource => _mangabatSource;

Source _mangabatSource = Source(
  name: "Mangabat",
  baseUrl: "https://www.mangabats.com",
  lang: "en",
  typeSource: "mangabox",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangabox/src/en/mangabat/icon.png",
  dateFormat: "MMM dd,yy",
  dateFormatLocale: "en",
);

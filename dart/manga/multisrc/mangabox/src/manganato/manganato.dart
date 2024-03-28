import '../../../../../../model/source.dart';

Source get manganatoSource => _manganatoSource;

Source _manganatoSource = Source(
  name: "Manganato",
  baseUrl: "https://manganato.com",
  lang: "en",
  typeSource: "mangabox",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangabox/src/manganato/icon.png",
  dateFormat: "MMM dd,yy",
  dateFormatLocale: "en",
);

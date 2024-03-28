import '../../../../../../model/source.dart';

Source get mangaseeSource => _mangaseeSource;

Source _mangaseeSource = Source(
  name: "MangaSee",
  baseUrl: "https://mangasee123.com",
  lang: "en",
  typeSource: "nepnep",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/nepnep/src/mangasee/icon.png",
  dateFormat: "yyyy-MM-dd HH:mm:ss",
  dateFormatLocale: "en",
);

import '../../../../../../model/source.dart';

Source get mangasscansSource => _mangasscansSource;
Source _mangasscansSource = Source(
    name: "Mangas Scans",
    baseUrl: "https://mangas-scans.com",
    lang: "fr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangasscans/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"fr"
  );

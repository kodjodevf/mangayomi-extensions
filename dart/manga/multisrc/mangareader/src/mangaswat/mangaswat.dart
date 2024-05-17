import '../../../../../../model/source.dart';

Source get mangaswatSource => _mangaswatSource;
Source _mangaswatSource = Source(
    name: "MangaSwat",
    baseUrl: "https://normoyun.com",
    lang: "ar",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangaswat/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"ar"
  );

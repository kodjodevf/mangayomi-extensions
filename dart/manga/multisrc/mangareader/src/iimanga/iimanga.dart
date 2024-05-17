import '../../../../../../model/source.dart';

Source get iimangaSource => _iimangaSource;
Source _iimangaSource = Source(
    name: "ARESManga",
    baseUrl: "https://fl-ares.com",
    lang: "ar",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/iimanga/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"ar"
  );

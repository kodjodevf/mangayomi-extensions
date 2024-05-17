import '../../../../../../model/source.dart';

Source get mangaproSource => _mangaproSource;
Source _mangaproSource = Source(
    name: "Manga Pro",
    baseUrl: "https://mangapro.club",
    lang: "ar",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangapro/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"ar"
  );

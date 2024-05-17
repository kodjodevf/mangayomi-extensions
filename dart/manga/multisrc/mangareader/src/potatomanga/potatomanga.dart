import '../../../../../../model/source.dart';

Source get potatomangaSource => _potatomangaSource;
Source _potatomangaSource = Source(
    name: "PotatoManga",
    baseUrl: "https://ar.potatomanga.xyz",
    lang: "ar",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/potatomanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"ar"
  );

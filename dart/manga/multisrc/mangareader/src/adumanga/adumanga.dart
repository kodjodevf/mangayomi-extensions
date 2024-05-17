import '../../../../../../model/source.dart';

Source get adumangaSource => _adumangaSource;
Source _adumangaSource = Source(
    name: "Adu Manga",
    baseUrl: "https://www.mangacim.com",
    lang: "tr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/adumanga/icon.png",
    dateFormat:"MMMM d, yyy",
    dateFormatLocale:"tr"
  );

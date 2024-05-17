import '../../../../../../model/source.dart';

Source get patimangaSource => _patimangaSource;
Source _patimangaSource = Source(
    name: "Pati Manga",
    baseUrl: "https://www.patimanga.com",
    lang: "tr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/patimanga/icon.png",
    dateFormat:"MMMM d, yyy",
    dateFormatLocale:"tr"
  );

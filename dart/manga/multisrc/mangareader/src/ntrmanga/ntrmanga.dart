import '../../../../../../model/source.dart';

Source get ntrmangaSource => _ntrmangaSource;
Source _ntrmangaSource = Source(
    name: "NTR-Manga",
    baseUrl: "https://www.ntr-manga.com",
    lang: "th",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/ntrmanga/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"th"
  );

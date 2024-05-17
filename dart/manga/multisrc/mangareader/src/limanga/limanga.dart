import '../../../../../../model/source.dart';

Source get limangaSource => _limangaSource;
Source _limangaSource = Source(
    name: "Li Manga",
    baseUrl: "https://limanga.net",
    lang: "pt-br",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/limanga/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"pt-br"
  );

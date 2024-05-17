import '../../../../../../model/source.dart';

Source get athenamangaSource => _athenamangaSource;
Source _athenamangaSource = Source(
    name: "Athena Manga",
    baseUrl: "https://athenamanga.com",
    lang: "tr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/athenamanga/icon.png",
    dateFormat:"MMMM d, yyy",
    dateFormatLocale:"tr"
  );

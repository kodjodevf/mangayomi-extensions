import '../../../../../../model/source.dart';

Source get ryujinmangaSource => _ryujinmangaSource;
Source _ryujinmangaSource = Source(
    name: "RyujinManga",
    baseUrl: "https://ryujinmanga.com",
    lang: "es",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/ryujinmanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es"
  );

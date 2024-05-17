import '../../../../../../model/source.dart';

Source get sheamangaSource => _sheamangaSource;
Source _sheamangaSource = Source(
    name: "Shea Manga",
    baseUrl: "https://sheakomik.com",
    lang: "id",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/sheamanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"id"
  );

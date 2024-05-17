import '../../../../../../model/source.dart';

Source get mangamateSource => _mangamateSource;
Source _mangamateSource = Source(
    name: "漫画メイト",
    baseUrl: "https://manga-mate.org",
    lang: "ja",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangamate/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"ja"
  );

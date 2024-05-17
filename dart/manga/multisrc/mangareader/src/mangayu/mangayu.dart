import '../../../../../../model/source.dart';

Source get mangayuSource => _mangayuSource;
Source _mangayuSource = Source(
    name: "MangaYu",
    baseUrl: "https://mangayu.id",
    lang: "id",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangayu/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"id"
  );

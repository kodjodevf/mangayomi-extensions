import '../../../../../../model/source.dart';

Source get mangatakSource => _mangatakSource;
Source _mangatakSource = Source(
    name: "MangaTak",
    baseUrl: "https://mangatak.com",
    lang: "ar",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangatak/icon.png",
    dateFormat:"MMMM DD, yyyy",
    dateFormatLocale:"ar"
  );

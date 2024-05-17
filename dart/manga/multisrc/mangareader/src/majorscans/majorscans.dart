import '../../../../../../model/source.dart';

Source get majorscansSource => _majorscansSource;
Source _majorscansSource = Source(
    name: "MajorScans",
    baseUrl: "https://www.majorscans.com",
    lang: "tr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/majorscans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"tr"
  );

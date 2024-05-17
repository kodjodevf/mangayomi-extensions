import '../../../../../../model/source.dart';

Source get crowscansSource => _crowscansSource;
Source _crowscansSource = Source(
    name: "Crow Scans",
    baseUrl: "https://crowscans.com",
    lang: "ar",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/crowscans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"ar"
  );

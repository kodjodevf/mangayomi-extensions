import '../../../../../../model/source.dart';

Source get areascansSource => _areascansSource;
Source _areascansSource = Source(
    name: "Area Scans",
    baseUrl: "https://ar.areascans.org",
    lang: "ar",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/areascans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"ar"
  );

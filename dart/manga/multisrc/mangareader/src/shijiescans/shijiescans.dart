import '../../../../../../model/source.dart';

Source get shijiescansSource => _shijiescansSource;
Source _shijiescansSource = Source(
    name: "Shijie Scans",
    baseUrl: "https://shijiescans.com",
    lang: "tr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/shijiescans/icon.png",
    dateFormat:"MMM d, yyy",
    dateFormatLocale:"tr"
  );

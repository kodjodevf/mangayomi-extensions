import '../../../../../../model/source.dart';

Source get zenithscansSource => _zenithscansSource;
Source _zenithscansSource = Source(
    name: "Zenith Scans",
    baseUrl: "https://zenithscans.com",
    lang: "tr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/zenithscans/icon.png",
    dateFormat:"MMM d, yyy",
    dateFormatLocale:"tr"
  );

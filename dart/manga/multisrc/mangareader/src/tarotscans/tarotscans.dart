import '../../../../../../model/source.dart';

  Source get tarotscansSource => _tarotscansSource;
            
  Source _tarotscansSource = Source(
    name: "Tarot Scans",
    baseUrl: "https://www.tarotscans.com",
    lang: "tr",
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/tarotscans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"tr",
  );
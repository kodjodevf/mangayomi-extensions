import '../../../../../model/source.dart';

  Source get tarotscansSource => _tarotscansSource;
            
  Source _tarotscansSource = Source(
    name: "Tarot Scans",
    baseUrl: "https://www.tarotscans.com",
    lang: "tr",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/tarotscans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"tr",
  );
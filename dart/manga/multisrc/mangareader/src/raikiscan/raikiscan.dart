import '../../../../../../model/source.dart';

  Source get raikiscanSource => _raikiscanSource;
            
  Source _raikiscanSource = Source(
    name: "Raiki Scan",
    baseUrl: "https://raikiscan.com",
    lang: "es",
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/raikiscan/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
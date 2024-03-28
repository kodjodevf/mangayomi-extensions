import '../../../../../../model/source.dart';

  Source get turktoonSource => _turktoonSource;
            
  Source _turktoonSource = Source(
    name: "TurkToon",
    baseUrl: "https://turktoon.com",
    lang: "tr",
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/turktoon/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
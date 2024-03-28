import '../../../../../../model/source.dart';

  Source get frscanSource => _frscanSource;
            
  Source _frscanSource = Source(
    name: "FR-Scan",
    baseUrl: "https://fr-scan.com",
    lang: "fr",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/frscan/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"fr",
  );
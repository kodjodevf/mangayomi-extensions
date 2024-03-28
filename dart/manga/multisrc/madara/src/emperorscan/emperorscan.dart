import '../../../../../../model/source.dart';

  Source get emperorscanSource => _emperorscanSource;
            
  Source _emperorscanSource = Source(
    name: "Emperor Scan",
    baseUrl: "https://emperorscan.com",
    lang: "es",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/emperorscan/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es",
  );
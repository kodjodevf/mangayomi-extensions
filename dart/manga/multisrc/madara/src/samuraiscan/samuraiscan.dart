import '../../../../../../model/source.dart';

  Source get samuraiscanSource => _samuraiscanSource;
            
  Source _samuraiscanSource = Source(
    name: "SamuraiScan",
    baseUrl: "https://samuraiscan.com",
    lang: "es",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/samuraiscan/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"es",
  );
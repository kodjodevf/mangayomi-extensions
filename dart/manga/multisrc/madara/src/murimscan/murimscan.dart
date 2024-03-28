import '../../../../../../model/source.dart';

  Source get murimscanSource => _murimscanSource;
            
  Source _murimscanSource = Source(
    name: "MurimScan",
    baseUrl: "https://murimscan.run",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/murimscan/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
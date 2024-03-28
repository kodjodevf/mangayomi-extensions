import '../../../../../../model/source.dart';

  Source get mangakomiSource => _mangakomiSource;
            
  Source _mangakomiSource = Source(
    name: "MangaKomi",
    baseUrl: "https://mangakomi.io",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangakomi/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
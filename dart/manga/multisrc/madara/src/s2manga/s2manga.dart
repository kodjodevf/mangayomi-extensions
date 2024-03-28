import '../../../../../../model/source.dart';

  Source get s2mangaSource => _s2mangaSource;
            
  Source _s2mangaSource = Source(
    name: "S2Manga",
    baseUrl: "https://www.s2manga.com",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/s2manga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
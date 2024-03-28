import '../../../../../../model/source.dart';

  Source get mangaclashSource => _mangaclashSource;
            
  Source _mangaclashSource = Source(
    name: "MangaClash",
    baseUrl: "https://mangaclash.com",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangaclash/icon.png",
    dateFormat:"MM/dd/yy",
    dateFormatLocale:"en_us",
  );
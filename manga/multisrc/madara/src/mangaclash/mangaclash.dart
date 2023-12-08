import '../../../../../model/source.dart';

  Source get mangaclashSource => _mangaclashSource;
            
  Source _mangaclashSource = Source(
    name: "MangaClash",
    baseUrl: "https://mangaclash.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/mangaclash/icon.png",
    dateFormat:"MM/dd/yy",
    dateFormatLocale:"en_us",
  );
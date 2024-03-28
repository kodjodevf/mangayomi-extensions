import '../../../../../../model/source.dart';

  Source get mangadistrictSource => _mangadistrictSource;
            
  Source _mangadistrictSource = Source(
    name: "Manga District",
    baseUrl: "https://mangadistrict.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangadistrict/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"en_us",
  );
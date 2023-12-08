import '../../../../../model/source.dart';

  Source get mangalandSource => _mangalandSource;
            
  Source _mangalandSource = Source(
    name: "Mangaland",
    baseUrl: "https://mangaland.net",
    lang: "es",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/mangaland/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es",
  );
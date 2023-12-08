import '../../../../../model/source.dart';

  Source get factmangaSource => _factmangaSource;
            
  Source _factmangaSource = Source(
    name: "FactManga",
    baseUrl: "https://factmanga.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/factmanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
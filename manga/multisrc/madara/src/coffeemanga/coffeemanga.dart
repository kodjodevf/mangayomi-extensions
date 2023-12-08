import '../../../../../model/source.dart';

  Source get coffeemangaSource => _coffeemangaSource;
            
  Source _coffeemangaSource = Source(
    name: "Coffee Manga",
    baseUrl: "https://coffeemanga.io",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/coffeemanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
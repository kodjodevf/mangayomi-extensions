import '../../../../../model/source.dart';

  Source get mangavisaSource => _mangavisaSource;
            
  Source _mangavisaSource = Source(
    name: "MangaVisa",
    baseUrl: "https://mangavisa.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/mangavisa/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
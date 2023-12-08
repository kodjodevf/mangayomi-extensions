import '../../../../../model/source.dart';

  Source get mangafrSource => _mangafrSource;
            
  Source _mangafrSource = Source(
    name: "Manga-FR",
    baseUrl: "https://manga-fr.me",
    lang: "fr",
    isNsfw:true,
    typeSource: "mmrcms",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mmrcms/src/mangafr/icon.png",
    dateFormat:"d MMM. yyyy",
    dateFormatLocale:"en_us",
  );
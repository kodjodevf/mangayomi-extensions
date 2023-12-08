import '../../../../../model/source.dart';

  Source get pojokmangaSource => _pojokmangaSource;
            
  Source _pojokmangaSource = Source(
    name: "Pojok Manga",
    baseUrl: "https://pojokmanga.net",
    lang: "id",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/pojokmanga/icon.png",
    dateFormat:"MMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
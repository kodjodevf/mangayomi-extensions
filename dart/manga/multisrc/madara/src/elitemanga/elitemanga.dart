import '../../../../../../model/source.dart';

  Source get elitemangaSource => _elitemangaSource;
            
  Source _elitemangaSource = Source(
    name: "Elite Manga",
    baseUrl: "https://www.elitemanga.org",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/elitemanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
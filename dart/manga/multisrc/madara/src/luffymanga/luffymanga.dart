import '../../../../../../model/source.dart';

  Source get luffymangaSource => _luffymangaSource;
            
  Source _luffymangaSource = Source(
    name: "Luffy Manga",
    baseUrl: "https://luffymanga.com",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/luffymanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
import '../../../../../../model/source.dart';

  Source get rio2mangaSource => _rio2mangaSource;
            
  Source _rio2mangaSource = Source(
    name: "Rio2 Manga",
    baseUrl: "https://rio2manga.com",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/rio2manga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
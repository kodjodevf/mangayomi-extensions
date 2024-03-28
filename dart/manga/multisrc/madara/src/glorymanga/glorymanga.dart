import '../../../../../../model/source.dart';

  Source get glorymangaSource => _glorymangaSource;
            
  Source _glorymangaSource = Source(
    name: "Glory Manga",
    baseUrl: "https://glorymanga.com",
    lang: "tr",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/glorymanga/icon.png",
    dateFormat:"dd/MM/yyy",
    dateFormatLocale:"tr",
  );
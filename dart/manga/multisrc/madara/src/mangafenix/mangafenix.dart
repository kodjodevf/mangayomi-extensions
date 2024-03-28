import '../../../../../../model/source.dart';

  Source get mangafenixSource => _mangafenixSource;
            
  Source _mangafenixSource = Source(
    name: "Manga Fenix",
    baseUrl: "https://manhua-fenix.com",
    lang: "es",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangafenix/icon.png",
    dateFormat:"dd MMMM, yyyy",
    dateFormatLocale:"es",
  );
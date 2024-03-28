import '../../../../../../model/source.dart';

  Source get mangasehriSource => _mangasehriSource;
            
  Source _mangasehriSource = Source(
    name: "Manga Şehri",
    baseUrl: "https://mangasehri.com",
    lang: "tr",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangasehri/icon.png",
    dateFormat:"dd/MM/yyy",
    dateFormatLocale:"tr",
  );
import '../../../../../../model/source.dart';

  Source get barmangaSource => _barmangaSource;
            
  Source _barmangaSource = Source(
    name: "BarManga",
    baseUrl: "https://barmanga.com",
    lang: "es",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/barmanga/icon.png",
    dateFormat:"MM/dd/yyyy",
    dateFormatLocale:"es",
  );
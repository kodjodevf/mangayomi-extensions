import '../../../../../../model/source.dart';

  Source get mangaxicoSource => _mangaxicoSource;
            
  Source _mangaxicoSource = Source(
    name: "Mangaxico",
    baseUrl: "https://mangaxico.com",
    lang: "es",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangaxico/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es",
  );
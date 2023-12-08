import '../../../../../model/source.dart';

  Source get mangagalaxySource => _mangagalaxySource;
            
  Source _mangagalaxySource = Source(
    name: "Manga Galaxy",
    baseUrl: "https://mangagalaxy.me",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/mangagalaxy/icon.png",
    dateFormat:"MM/dd/yyyy",
    dateFormatLocale:"en_us",
  );
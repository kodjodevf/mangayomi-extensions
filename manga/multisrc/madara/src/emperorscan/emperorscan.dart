import '../../../../../model/source.dart';

  Source get emperorscanSource => _emperorscanSource;
            
  Source _emperorscanSource = Source(
    name: "Emperor Scan",
    baseUrl: "https://emperorscan.com",
    lang: "es",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/emperorscan/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es",
  );
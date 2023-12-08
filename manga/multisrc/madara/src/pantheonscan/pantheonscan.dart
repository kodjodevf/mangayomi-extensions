import '../../../../../model/source.dart';

  Source get pantheonscanSource => _pantheonscanSource;
            
  Source _pantheonscanSource = Source(
    name: "Pantheon Scan",
    baseUrl: "https://pantheon-scan.com",
    lang: "fr",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/pantheonscan/icon.png",
    dateFormat:"d MMMM yyyy",
    dateFormatLocale:"fr",
  );
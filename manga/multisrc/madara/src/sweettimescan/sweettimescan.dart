import '../../../../../model/source.dart';

  Source get sweettimescanSource => _sweettimescanSource;
            
  Source _sweettimescanSource = Source(
    name: "Sweet Time Scan",
    baseUrl: "https://sweetscan.net",
    lang: "pt-BR",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/sweettimescan/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"pt-br",
  );
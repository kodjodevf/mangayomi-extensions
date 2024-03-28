import '../../../../../../model/source.dart';

  Source get randomscanSource => _randomscanSource;
            
  Source _randomscanSource = Source(
    name: "Random Scan",
    baseUrl: "https://randomscanlators.net",
    lang: "pt-BR",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/randomscan/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"pt-br",
  );
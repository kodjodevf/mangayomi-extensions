import '../../../../../../model/source.dart';

  Source get sinensisSource => _sinensisSource;
            
  Source _sinensisSource = Source(
    name: "Sinensis Scan",
    baseUrl: "https://sinensisscan.net",
    lang: "pt-BR",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/sinensis/icon.png",
    dateFormat:"dd/MM/yyyy",
    dateFormatLocale:"pt-br",
  );
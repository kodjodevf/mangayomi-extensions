import '../../../../../../model/source.dart';

  Source get winterscanSource => _winterscanSource;
            
  Source _winterscanSource = Source(
    name: "Winter Scan",
    baseUrl: "https://winterscan.com",
    lang: "pt-BR",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/winterscan/icon.png",
    dateFormat:"dd 'de' MMMM 'de' yyyy",
    dateFormatLocale:"pt-br",
  );
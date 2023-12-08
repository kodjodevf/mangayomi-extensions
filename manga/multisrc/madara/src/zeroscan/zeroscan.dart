import '../../../../../model/source.dart';

  Source get zeroscanSource => _zeroscanSource;
            
  Source _zeroscanSource = Source(
    name: "Zero Scan",
    baseUrl: "https://zeroscan.com.br",
    lang: "pt-br",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/zeroscan/icon.png",
    dateFormat:"dd/MM/yyyy",
    dateFormatLocale:"pt-br",
  );
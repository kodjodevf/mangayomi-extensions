import '../../../../../model/source.dart';

  Source get ghostscanSource => _ghostscanSource;
            
  Source _ghostscanSource = Source(
    name: "Ghost Scan",
    baseUrl: "https://ghostscan.com.br",
    lang: "pt-BR",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/ghostscan/icon.png",
    dateFormat:"dd 'de' MMMMM 'de' yyyy",
    dateFormatLocale:"pt-br",
  );
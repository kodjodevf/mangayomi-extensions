import '../../../../../../model/source.dart';

  Source get tatakaescanSource => _tatakaescanSource;
            
  Source _tatakaescanSource = Source(
    name: "Tatakae Scan",
    baseUrl: "https://tatakaescan.com",
    lang: "pt-BR",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/tatakaescan/icon.png",
    dateFormat:"dd 'de' MMMMM 'de' yyyy",
    dateFormatLocale:"pt-br",
  );
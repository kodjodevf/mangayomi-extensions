import '../../../../../model/source.dart';

  Source get maidscanSource => _maidscanSource;
            
  Source _maidscanSource = Source(
    name: "Maid Scan",
    baseUrl: "https://maidscan.com.br",
    lang: "pt-BR",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/manga/multisrc/madara/src/maidscan/icon.png",
    dateFormat:"dd 'de' MMMMM 'de' yyyy",
    dateFormatLocale:"pt-br",
  );
import '../../../../../../model/source.dart';

  Source get cerisescansSource => _cerisescansSource;
            
  Source _cerisescansSource = Source(
    name: "Cerise Scan",
    baseUrl: "https://cerisescan.com",
    lang: "pt-BR",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/cerisescans/icon.png",
    dateFormat:"dd 'de' MMMMM 'de' yyyy",
    dateFormatLocale:"pt-br",
  );
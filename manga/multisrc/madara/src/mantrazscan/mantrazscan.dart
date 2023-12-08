import '../../../../../model/source.dart';

  Source get mantrazscanSource => _mantrazscanSource;
            
  Source _mantrazscanSource = Source(
    name: "Mantraz Scan",
    baseUrl: "https://mantrazscan.com",
    lang: "es",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/mantrazscan/icon.png",
    dateFormat:"dd/MM/yyyy",
    dateFormatLocale:"es",
  );
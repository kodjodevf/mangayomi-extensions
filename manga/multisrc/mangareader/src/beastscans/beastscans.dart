import '../../../../../model/source.dart';

  Source get beastscansSource => _beastscansSource;
            
  Source _beastscansSource = Source(
    name: "Beast Scans",
    baseUrl: "https://beast-scans.com",
    lang: "ar",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/beastscans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"ar",
  );
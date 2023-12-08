import '../../../../../model/source.dart';

  Source get anikigaSource => _anikigaSource;
            
  Source _anikigaSource = Source(
    name: "Anikiga",
    baseUrl: "https://anikiga.com",
    lang: "tr",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/anikiga/icon.png",
    dateFormat:"d MMMMM yyyy",
    dateFormatLocale:"tr",
  );
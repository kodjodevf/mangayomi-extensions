import '../../../../../model/source.dart';

  Source get cocoripSource => _cocoripSource;
            
  Source _cocoripSource = Source(
    name: "Coco Rip",
    baseUrl: "https://cocorip.net",
    lang: "es",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/cocorip/icon.png",
    dateFormat:"dd/MM/yyyy",
    dateFormatLocale:"es",
  );
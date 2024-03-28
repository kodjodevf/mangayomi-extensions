import '../../../../../../model/source.dart';

  Source get cocoripSource => _cocoripSource;
            
  Source _cocoripSource = Source(
    name: "Coco Rip",
    baseUrl: "https://cocorip.net",
    lang: "es",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/cocorip/icon.png",
    dateFormat:"dd/MM/yyyy",
    dateFormatLocale:"es",
  );
import '../../../../../../model/source.dart';

  Source get comicznetv2Source => _comicznetv2Source;
            
  Source _comicznetv2Source = Source(
    name: "Comicz.net v2",
    baseUrl: "https://v2.comiz.net",
    lang: "all",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/comicznetv2/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
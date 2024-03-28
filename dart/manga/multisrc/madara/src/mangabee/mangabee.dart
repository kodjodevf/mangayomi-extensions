import '../../../../../../model/source.dart';

  Source get mangabeeSource => _mangabeeSource;
            
  Source _mangabeeSource = Source(
    name: "Manga Bee",
    baseUrl: "https://mangabee.net",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangabee/icon.png",
    dateFormat:"MM/dd/yyyy",
    dateFormatLocale:"en",
  );
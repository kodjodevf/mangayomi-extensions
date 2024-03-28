import '../../../../../../model/source.dart';

  Source get mangaidSource => _mangaidSource;
            
  Source _mangaidSource = Source(
    name: "MangaID",
    baseUrl: "https://mangaid.click",
    lang: "id",
    
    typeSource: "mmrcms",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mmrcms/src/mangaid/icon.png",
    dateFormat:"d MMM. yyyy",
    dateFormatLocale:"en_us",
  );
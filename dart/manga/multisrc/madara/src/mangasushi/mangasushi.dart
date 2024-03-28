import '../../../../../../model/source.dart';

  Source get mangasushiSource => _mangasushiSource;
            
  Source _mangasushiSource = Source(
    name: "Mangasushi",
    baseUrl: "https://mangasushi.org",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangasushi/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
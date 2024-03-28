import '../../../../../../model/source.dart';

  Source get manhuazoneSource => _manhuazoneSource;
            
  Source _manhuazoneSource = Source(
    name: "ManhuaZone",
    baseUrl: "https://manhuazone.org",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/manhuazone/icon.png",
    dateFormat:"MMM d, yyyy",
    dateFormatLocale:"en_us",
  );
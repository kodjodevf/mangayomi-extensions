import '../../../../../../model/source.dart';

  Source get mangapureSource => _mangapureSource;
            
  Source _mangapureSource = Source(
    name: "MangaPure",
    baseUrl: "https://mangapure.net",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangapure/icon.png",
    dateFormat:"MMM dd, HH:mm",
    dateFormatLocale:"en",
  );
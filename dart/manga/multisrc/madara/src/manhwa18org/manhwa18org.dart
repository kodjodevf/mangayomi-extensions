import '../../../../../../model/source.dart';

  Source get manhwa18orgSource => _manhwa18orgSource;
            
  Source _manhwa18orgSource = Source(
    name: "Manhwa18.org",
    baseUrl: "https://manhwa18.org",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/manhwa18org/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
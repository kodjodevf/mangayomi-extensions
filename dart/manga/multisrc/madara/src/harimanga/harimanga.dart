import '../../../../../../model/source.dart';

  Source get harimangaSource => _harimangaSource;
            
  Source _harimangaSource = Source(
    name: "Harimanga",
    baseUrl: "https://harimanga.com",
    lang: "en",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/harimanga/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
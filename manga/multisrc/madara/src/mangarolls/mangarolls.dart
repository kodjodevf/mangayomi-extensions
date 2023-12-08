import '../../../../../model/source.dart';

  Source get mangarollsSource => _mangarollsSource;
            
  Source _mangarollsSource = Source(
    name: "MangaRolls",
    baseUrl: "https://mangarolls.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/mangarolls/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
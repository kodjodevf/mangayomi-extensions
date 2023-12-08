import '../../../../../model/source.dart';

  Source get mangaweebsSource => _mangaweebsSource;
            
  Source _mangaweebsSource = Source(
    name: "Manga Weebs",
    baseUrl: "https://mangaweebs.in",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/mangaweebs/icon.png",
    dateFormat:"dd MMMM HH:mm",
    dateFormatLocale:"en_us",
  );
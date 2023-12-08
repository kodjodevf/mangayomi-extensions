import '../../../../../model/source.dart';

  Source get mangacimSource => _mangacimSource;
            
  Source _mangacimSource = Source(
    name: "Mangacim",
    baseUrl: "https://www.mangacim.com",
    lang: "tr",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/mangacim/icon.png",
    dateFormat:"MMM d, yyy",
    dateFormatLocale:"tr",
  );
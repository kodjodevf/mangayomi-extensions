import '../../../../../model/source.dart';

  Source get mundomangakunSource => _mundomangakunSource;
            
  Source _mundomangakunSource = Source(
    name: "Mundo Mangá-Kun",
    baseUrl: "https://mundomangakun.com.br",
    lang: "pt-br",
    
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/mundomangakun/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"pt-br",
  );
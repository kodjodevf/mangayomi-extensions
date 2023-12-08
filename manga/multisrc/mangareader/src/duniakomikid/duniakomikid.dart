import '../../../../../model/source.dart';

  Source get duniakomikidSource => _duniakomikidSource;
            
  Source _duniakomikidSource = Source(
    name: "DuniaKomik.id",
    baseUrl: "https://duniakomik.id",
    lang: "id",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/duniakomikid/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"id",
  );
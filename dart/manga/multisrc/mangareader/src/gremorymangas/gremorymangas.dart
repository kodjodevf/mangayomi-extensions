import '../../../../../../model/source.dart';

Source get gremorymangasSource => _gremorymangasSource;
Source _gremorymangasSource = Source(
    name: "Gremory Mangas",
    baseUrl: "https://gremorymangas.com",
    lang: "es",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/gremorymangas/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es"
  );

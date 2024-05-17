import '../../../../../../model/source.dart';

Source get lermangasSource => _lermangasSource;
Source _lermangasSource = Source(
    name: "Ler Mangas",
    baseUrl: "https://lermangas.me",
    lang: "pt-br",
    isNsfw:true,
    typeSource: "madara",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/bbranchNamee/dart/manga/multisrc/madara/src/lermangas/icon.png",
    dateFormat:"dd 'de' MMMMM 'de' yyyy",
    dateFormatLocale:"pt-br"
  );

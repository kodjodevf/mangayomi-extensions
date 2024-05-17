import '../../../../../../model/source.dart';

Source get mangaokuSource => _mangaokuSource;
Source _mangaokuSource = Source(
    name: "Manga Oku",
    baseUrl: "https://mangaoku.info",
    lang: "tr",
    isNsfw:false,
    typeSource: "madara",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/bbranchNamee/dart/manga/multisrc/madara/src/mangaoku/icon.png",
    dateFormat:"d MMMM yyyy",
    dateFormatLocale:"tr"
  );

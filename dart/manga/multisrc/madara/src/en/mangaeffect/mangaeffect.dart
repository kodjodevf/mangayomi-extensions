import '../../../../../../../model/source.dart';

Source get mangaeffectSource => _mangaeffectSource;
Source _mangaeffectSource = Source(
  name: "MangaEffect",
  baseUrl: "https://www.mangaread.org",
  lang: "en",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/dart/manga/multisrc/madara/src/en/mangaeffect/icon.png",
  dateFormat: "dd.MM.yyyy",
  dateFormatLocale: "en_us",
);

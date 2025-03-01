import '../../../../../../model/source.dart';

Source get nvmangaSource => _nvmangaSource;
Source _nvmangaSource = Source(
  name: "NvManga",
  baseUrl: "https://nvmanga.com",
  lang: "en",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/dart/manga/multisrc/madara/src/nvmanga/icon.png",
  dateFormat: "dd/MM/yyyy",
  dateFormatLocale: "en",
);

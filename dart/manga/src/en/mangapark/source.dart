import '../../../../../model/source.dart';

Source get mangaparkSource => _mangaparkSource;
const _mangaparkVersion = "1.0.1";
const _mangaparkSourceCodeUrl = "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/en/mangapark/mangapark.dart";
const _mangaparkIconUrl = "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/en/mangapark/icon.png";
Source _mangaparkSource = Source(
  name: "MangaPark",
  baseUrl: "https://mangapark.io",
  apiUrl: "https://mangapark.io/apo/",
  lang: "en", 
  typeSource: "single",
  iconUrl: _mangaparkIconUrl,
  sourceCodeUrl: _mangaparkSourceCodeUrl,
  itemType: ItemType.manga,
  version: _mangaparkVersion,
  dateFormat: "MMM dd yyyy",
  dateFormatLocale: "en",
);

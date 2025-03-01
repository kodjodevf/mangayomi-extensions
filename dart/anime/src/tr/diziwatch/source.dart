import '../../../../../model/source.dart';

Source get diziwatchSource => _diziwatchSource;
const _diziwatchVersion = "0.0.1";
const _diziwatchSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/tr/diziwatch/diziwatch.dart";
Source _diziwatchSource = Source(
  name: "diziWatch",
  baseUrl: "https://diziwatch.net",
  lang: "tr",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/tr/diziwatch/icon.png",
  sourceCodeUrl: _diziwatchSourceCodeUrl,
  version: _diziwatchVersion,
  itemType: ItemType.anime,
);

import '../../../../../model/source.dart';

Source get donghuastreamSource => _donghuastreamSource;
const _donghuastreamVersion = "0.0.2";
const _donghuastreamSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/donghuastream/donghuastream.dart";
Source _donghuastreamSource = Source(
  name: "DonghuaStream",
  baseUrl: "https://donghuastream.org",
  lang: "en",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/donghuastream/icon.png",
  sourceCodeUrl: _donghuastreamSourceCodeUrl,
  version: _donghuastreamVersion,
  itemType: ItemType.anime,
);

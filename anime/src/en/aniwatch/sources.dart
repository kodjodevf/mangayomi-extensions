import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

const aniwatchVersion = "0.0.11";
const aniwatchSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/en/aniwatch/aniwatch-v$aniwatchVersion.dart";

List<Source> get aniwatchSourcesList => _aniwatchSourcesList;
List<Source> _aniwatchSourcesList = [
  Source(
      name: "AniWatch.to",
      baseUrl: "https://aniwatch.to/",
      lang: "en",
      typeSource: "single",
      iconUrl: getIconUrl("aniwatch", "en"),
      version: aniwatchVersion,
      isManga: false,
      appMinVerReq: "0.0.4",
      sourceCodeUrl: aniwatchSourceCodeUrl),
  Source(
      name: "Kaido.to",
      baseUrl: "https://kaido.to/",
      lang: "en",
      typeSource: "single",
      iconUrl: getIconUrl("kaido", "en"),
      version: aniwatchVersion,
      isManga: false,
      appMinVerReq: "0.0.4",
      sourceCodeUrl: aniwatchSourceCodeUrl),
];

import '../../../model/source.dart';
import '../../../utils/utils.dart';

const zorothemeVersion = "0.0.45";
const zorothemeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/multisrc/zorotheme/zorotheme-v$zorothemeVersion.dart";

List<Source> get zorothemeSourcesList => _zorothemeSourcesList;
List<Source> _zorothemeSourcesList = [
  Source(
      name: "AniWatch.to",
      baseUrl: "https://aniwatch.to",
      lang: "en",
      typeSource: "zorotheme",
      iconUrl: getIconUrl("aniwatch", "en"),
      version: zorothemeVersion,
      isManga: false,
      sourceCodeUrl: zorothemeSourceCodeUrl),
  Source(
      name: "Kaido.to",
      baseUrl: "https://kaido.to",
      lang: "en",
      typeSource: "zorotheme",
      iconUrl: getIconUrl("kaido", "en"),
      version: zorothemeVersion,
      isManga: false,
      sourceCodeUrl: zorothemeSourceCodeUrl),
];

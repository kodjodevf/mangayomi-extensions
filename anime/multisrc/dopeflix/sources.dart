import '../../../model/source.dart';
import '../../../utils/utils.dart';

const dopeflixVersion = "0.0.1";
const dopeflixSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/multisrc/dopeflix/dopeflix-v$dopeflixVersion.dart";

List<Source> get dopeflixSourcesList => _dopeflixSourcesList;
List<Source> _dopeflixSourcesList = [
  Source(
      name: "DopeBox",
      baseUrl: "https://dopebox.to",
      lang: "en",
      typeSource: "dopeflix",
      iconUrl: getIconUrl("dopebox", "en"),
      version: dopeflixVersion,
      isManga: false,
      sourceCodeUrl: dopeflixSourceCodeUrl),
  Source(
      name: "SFlix",
      baseUrl: "https://sflix.to",
      lang: "en",
      typeSource: "dopeflix",
      iconUrl: getIconUrl("sflix", "en"),
      version: dopeflixVersion,
      isManga: false,
      sourceCodeUrl: dopeflixSourceCodeUrl),
];

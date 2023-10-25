import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get kisskhSource => _kisskhSource;
const kisskhVersion = "0.0.2";
const kisskhSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/en/kisskh/kisskh-v$kisskhVersion.dart";
Source _kisskhSource = Source(
    name: "KissKH",
    baseUrl: "https://kisskh.co",
    lang: "en",
    typeSource: "single",
    iconUrl: getIconUrl("kisskh", "en"),
    sourceCodeUrl: kisskhSourceCodeUrl,
    version: kisskhVersion,
    isManga: false);

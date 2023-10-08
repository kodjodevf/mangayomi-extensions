import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get franimeSource => _franimeSource;
const franimeVersion = "0.0.21";
const franimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/fr/franime/franime-v$franimeVersion.dart";
Source _franimeSource = Source(
    name: "FrAnime",
    baseUrl: "https://franime.fr",
    apiUrl: "https://api.franime.fr",
    lang: "fr",
    typeSource: "single",
    iconUrl: getIconUrl("franime", "fr"),
    sourceCodeUrl: franimeSourceCodeUrl,
    version: franimeVersion,
    isManga: false,
    appMinVerReq: "0.0.4",
    isFullData: true);

import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get animesultraSource => _animesultraSource;
const animesultraVersion = "0.0.4";
const animesultraSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/fr/animesultra/animesultra-v$animesultraVersion.dart";
Source _animesultraSource = Source(
    name: "AnimesUltra",
    baseUrl: "https://ww.animesultra.net",
    lang: "fr",
    typeSource: "single",
    iconUrl: getIconUrl("animesultra", "fr"),
    sourceCodeUrl: animesultraSourceCodeUrl,
    version: animesultraVersion,
    isManga: false,
    isFullData: false);

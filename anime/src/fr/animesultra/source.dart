import '../../../../model/source.dart';

Source get animesultraSource => _animesultraSource;
const animesultraVersion = "0.0.1";
const animesultraSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/fr/animesultra/animesultra-v$animesultraVersion.dart";
Source _animesultraSource = Source(
    name: "AnimesUltra",
    baseUrl: "https://ww.animesultra.net",
    lang: "fr",
    typeSource: "single",
    iconUrl: 'https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/icon/mangayomi-fr-animesultra.png',
    sourceCodeUrl: animesultraSourceCodeUrl,
    version: animesultraVersion,
    isManga: false,
    isFullData: false);

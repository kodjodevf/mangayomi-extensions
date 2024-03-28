import '../../../../../model/source.dart';

Source get animesultraSource => _animesultraSource;
const _animesultraVersion = "0.0.65";
const _animesultraSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/fr/animesultra/animesultra.dart";
Source _animesultraSource = Source(
    name: "AnimesUltra",
    baseUrl: "https://ww.animesultra.net",
    lang: "fr",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/fr/animesultra/icon.png",
    sourceCodeUrl: _animesultraSourceCodeUrl,
    version: _animesultraVersion,
    isManga: false,
    isFullData: false);

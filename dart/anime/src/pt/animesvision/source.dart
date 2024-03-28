import '../../../../../model/source.dart';

Source get animesvision => _animesvision;
const _animesvisionVersion = "0.0.15";
const _animesvisionCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/pt/animesvision/animesvision.dart";
Source _animesvision = Source(
    name: "AnimesVision",
    baseUrl: "https://animes.vision",
    lang: "pt-br",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/pt/animesvision/icon.png",
    sourceCodeUrl: _animesvisionCodeUrl,
    version: _animesvisionVersion,
    isManga: false);

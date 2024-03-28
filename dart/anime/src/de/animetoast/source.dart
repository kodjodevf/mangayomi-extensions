import '../../../../../model/source.dart';

Source get animetoast => _animetoast;
const _animetoastVersion = "0.0.15";
const _animetoastCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/de/animetoast/animetoast.dart";
Source _animetoast = Source(
    name: "AnimeToast",
    baseUrl: "https://animetoast.cc",
    lang: "de",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/de/animetoast/icon.png",
    sourceCodeUrl: _animetoastCodeUrl,
    version: _animetoastVersion,
    isManga: false);

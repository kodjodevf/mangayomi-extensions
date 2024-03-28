import '../../../../../model/source.dart';

Source get animepaheSource => _animepaheSource;
const _animepaheVersion = "0.0.35";
const _animepaheSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/animepahe/animepahe.dart";
Source _animepaheSource = Source(
    name: "AnimePahe",
    baseUrl: "https://www.animepahe.ru",
    lang: "en",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/animepahe/icon.png",
    sourceCodeUrl: _animepaheSourceCodeUrl,
    version: _animepaheVersion,
    isManga: false);

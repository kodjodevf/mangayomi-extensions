import '../../../../model/source.dart';

Source get animepaheSource => _animepaheSource;
const _animepaheVersion = "0.0.1";
const _animepaheSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/ar/animepahe/animepahe.dart";
Source _animepaheSource = Source(
    name: "animepahe",
    baseUrl: "https://www.animepahe.ru",
    lang: "en",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/ar/animepahe/icon.png",
    sourceCodeUrl: _animepaheSourceCodeUrl,
    version: _animepaheVersion,
    isManga: false);

import '../../../../../model/source.dart';

Source get animesamaSource => _animesama;
const animesamaVersion = "0.0.25";
const animesamaCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/fr/animesama/animesama.dart";
Source _animesama = Source(
    name: "Anime-Sama",
    baseUrl: "https://anime-sama.fr",
    lang: "fr",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/fr/animesama/icon.png",
    sourceCodeUrl: animesamaCodeUrl,
    version: animesamaVersion,
    isManga: false);

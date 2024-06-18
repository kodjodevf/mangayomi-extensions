import '../../../../../model/source.dart';

Source get uhdmoviesSource => _uhdmoviesSource;
const _uhdmoviesVersion = "0.0.45";
const _uhdmoviesSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/uhdmovies/uhdmovies.dart";
Source _uhdmoviesSource = Source(
    name: "UHD Movies",
    baseUrl: "https://uhdmovies.fans",
    lang: "en",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/uhdmovies/icon.png",
    sourceCodeUrl: _uhdmoviesSourceCodeUrl,
    version: _uhdmoviesVersion,
    isManga: false);

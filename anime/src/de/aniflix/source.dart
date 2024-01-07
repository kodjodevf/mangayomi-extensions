import '../../../../model/source.dart';

Source get aniflix => _aniflix;
const _aniflixVersion = "0.0.2";
const _aniflixCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/de/aniflix/aniflix.dart";
Source _aniflix = Source(
    name: "Aniflix",
    baseUrl: "https://aniflix.cc",
    lang: "de",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/de/aniflix/icon.png",
    sourceCodeUrl: _aniflixCodeUrl,
    version: _aniflixVersion,
    isManga: false);

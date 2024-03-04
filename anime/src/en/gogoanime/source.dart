import '../../../../model/source.dart';

Source get gogoanimeSource => _gogoanimeSource;
const _gogoanimeVersion = "0.0.8";
const _gogoanimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/en/gogoanime/gogoanime.dart";
Source _gogoanimeSource = Source(
    name: "Gogoanime",
    baseUrl: "https://gogoanime3.net",
    lang: "en",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/en/gogoanime/icon.png",
    sourceCodeUrl: _gogoanimeSourceCodeUrl,
    version: _gogoanimeVersion,
    isManga: false);

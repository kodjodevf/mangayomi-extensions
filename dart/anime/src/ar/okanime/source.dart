import '../../../../../model/source.dart';

Source get okanimeSource => _okanimeSource;
const _okanimeVersion = "0.0.55";
const _okanimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/ar/okanime/okanime.dart";
Source _okanimeSource = Source(
    name: "Okanime",
    baseUrl: "https://www.okanime.xyz",
    lang: "ar",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/ar/okanime/icon.png",
    sourceCodeUrl: _okanimeSourceCodeUrl,
    version: _okanimeVersion,
    isManga: false);

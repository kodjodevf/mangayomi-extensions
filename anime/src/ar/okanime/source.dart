import '../../../../model/source.dart';

Source get okanimeSource => _okanimeSource;
const _okanimeVersion = "0.0.3";
const _okanimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/ar/okanime/okanime-v$_okanimeVersion.dart";
Source _okanimeSource = Source(
    name: "Okanime",
    baseUrl: "https://www.okanime.xyz",
    lang: "ar",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/ar/okanime/icon.png",
    sourceCodeUrl: _okanimeSourceCodeUrl,
    version: _okanimeVersion,
    isManga: false);

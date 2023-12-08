import '../../../../model/source.dart';

Source get kisskhSource => _kisskhSource;
const _kisskhVersion = "0.0.4";
const _kisskhSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/en/kisskh/kisskh-v$_kisskhVersion.dart";
Source _kisskhSource = Source(
    name: "KissKH",
    baseUrl: "https://kisskh.co",
    lang: "en",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/en/kisskh/icon.png",
    sourceCodeUrl: _kisskhSourceCodeUrl,
    version: _kisskhVersion,
    isManga: false);

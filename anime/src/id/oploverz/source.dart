import '../../../../model/source.dart';

Source get oploverz => _oploverz;
const _oploverzVersion = "0.0.25";
const _oploverzCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/id/oploverz/oploverz-v$_oploverzVersion.dart";
Source _oploverz = Source(
    name: "Oploverz",
    baseUrl: "https://oploverz.red",
    lang: "id",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/id/oploverz/icon.png",
    sourceCodeUrl: _oploverzCodeUrl,
    version: _oploverzVersion,
    isManga: false);

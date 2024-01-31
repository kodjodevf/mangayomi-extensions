import '../../../../model/source.dart';

Source get oploverz => _oploverz;
const _oploverzVersion = "0.0.4";
const _oploverzCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/id/oploverz/oploverz.dart";
Source _oploverz = Source(
    name: "Oploverz",
    baseUrl: "https://oploverz.red",
    lang: "id",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/id/oploverz/icon.png",
    sourceCodeUrl: _oploverzCodeUrl,
    version: _oploverzVersion,
    isManga: false);

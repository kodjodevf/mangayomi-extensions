import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get oploverz => _oploverz;
const oploverzVersion = "0.0.15";
const oploverzCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/id/oploverz/oploverz-v$oploverzVersion.dart";
Source _oploverz = Source(
    name: "Oploverz",
    baseUrl: "https://oploverz.red",
    lang: "id",
    typeSource: "single",
    iconUrl: getIconUrl("oploverz", "id"),
    sourceCodeUrl: oploverzCodeUrl,
    version: oploverzVersion,
    isManga: false);

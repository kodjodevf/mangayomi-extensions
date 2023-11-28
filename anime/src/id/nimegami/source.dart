import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get nimegami => _nimegami;
const nimegamiVersion = "0.0.25";
const nimegamiCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/id/nimegami/nimegami-v$nimegamiVersion.dart";
Source _nimegami = Source(
    name: "NimeGami",
    baseUrl: "https://nimegami.id",
    lang: "id",
    typeSource: "single",
    iconUrl: getIconUrl("nimegami", "id"),
    sourceCodeUrl: nimegamiCodeUrl,
    version: nimegamiVersion,
    isManga: false);

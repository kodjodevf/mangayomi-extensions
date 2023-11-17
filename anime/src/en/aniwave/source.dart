import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get aniwave => _aniwave;
const aniwaveVersion = "0.0.1";
const aniwaveCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/en/aniwave/aniwave-v$aniwaveVersion.dart";
Source _aniwave = Source(
    name: "Aniwave",
    baseUrl: "https://aniwave.to",
    lang: "en",
    typeSource: "single",
    iconUrl: getIconUrl("aniwave", "en"),
    sourceCodeUrl: aniwaveCodeUrl,
    version: aniwaveVersion,
    appMinVerReq: "0.0.8",
    isManga: false);

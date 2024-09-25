import '../../../../../model/source.dart';

Source get _AniZoneSource => _AniZoneSource;
const _AniZoneVersion = "0.0.1";
const _AniZoneSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/fr/AniZone/AniZone.dart";
Source _AniZoneSource = Source(
    name: "AniZone",
    baseUrl: "https://v1.animesz.xyz",
    lang: "fr",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/fr/AniZone/icon.png",
    sourceCodeUrl: _AniZoneSourceCodeUrl,
    version: _AniZoneVersion,
    isManga: false);
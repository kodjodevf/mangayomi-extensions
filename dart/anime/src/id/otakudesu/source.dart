import '../../../../../model/source.dart';

Source get otakudesu => _otakudesu;
const _otakudesuVersion = "0.0.55";
const _otakudesuCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/id/otakudesu/otakudesu.dart";
Source _otakudesu = Source(
    name: "OtakuDesu",
    baseUrl: "https://otakudesu.cloud",
    lang: "id",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/id/otakudesu/icon.png",
    sourceCodeUrl: _otakudesuCodeUrl,
    version: _otakudesuVersion,
    isManga: false);

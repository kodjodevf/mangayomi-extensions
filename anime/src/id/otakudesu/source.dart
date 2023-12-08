import '../../../../model/source.dart';

Source get otakudesu => _otakudesu;
const _otakudesuVersion = "0.0.3";
const _otakudesuCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/id/otakudesu/otakudesu-v$_otakudesuVersion.dart";
Source _otakudesu = Source(
    name: "OtakuDesu",
    baseUrl: "https://otakudesu.cam",
    lang: "id",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/id/otakudesu/icon.png",
    sourceCodeUrl: _otakudesuCodeUrl,
    version: _otakudesuVersion,
    isManga: false);

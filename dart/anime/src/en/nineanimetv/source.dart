import '../../../../../model/source.dart';

Source get nineanimetv => _nineanimetv;
const _nineanimetvVersion = "0.0.3";
const _nineanimetvCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/nineanimetv/nineanimetv.dart";
Source _nineanimetv = Source(
    name: "9AnimeTv",
    baseUrl: "https://9animetv.to",
    lang: "en",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/nineanimetv/icon.png",
    sourceCodeUrl: _nineanimetvCodeUrl,
    version: _nineanimetvVersion,
    isManga: false);

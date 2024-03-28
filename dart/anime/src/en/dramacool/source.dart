import '../../../../../model/source.dart';

Source get dramacoolSource => _dramacoolSource;
const _dramacoolVersion = "0.0.25";
const _dramacoolSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/dramacool/dramacool.dart";
Source _dramacoolSource = Source(
    name: "DramaCool",
    baseUrl: "https://dramacool.pa",
    lang: "en",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/dramacool/icon.png",
    sourceCodeUrl: _dramacoolSourceCodeUrl,
    version: _dramacoolVersion,
    isManga: false);

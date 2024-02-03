import '../../../../model/source.dart';

const _yomirollVersion = "0.0.1";
const _yomirollSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/all/yomiroll/yomiroll.dart";

String _iconUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/anime/src/all/yomiroll/icon.png";

Source get yomirollSource => _yomirollSource;
Source _yomirollSource = Source(
    name: 'Yomiroll',
    baseUrl: "https://crunchyroll.com",
    lang: "all",
    typeSource: "multiple",
    iconUrl: _iconUrl,
    version: _yomirollVersion,
    isManga: false,
    sourceCodeUrl: _yomirollSourceCodeUrl);

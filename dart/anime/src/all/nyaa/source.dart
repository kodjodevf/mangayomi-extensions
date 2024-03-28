import '../../../../../model/source.dart';

const _nyaaVersion = "0.0.2";
const _nyaaSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/all/nyaa/nyaa.dart";

String _iconUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/all/nyaa/icon.png";

Source get nyaaSource => _nyaaSource;
Source _nyaaSource = Source(
    name: 'Nyaa',
    baseUrl: "https://nyaa.si",
    lang: "all",
    typeSource: "torrent",
    iconUrl: _iconUrl,
    version: _nyaaVersion,
    isManga: false,
    sourceCodeUrl: _nyaaSourceCodeUrl);

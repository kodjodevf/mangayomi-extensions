import '../../../../model/source.dart';

Source get wcostreamSource => _wcostreamSource;
const wcostreamVersion = "0.0.1";
const wcostreamSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/fr/wcostream/wcostream-v$wcostreamVersion.dart";
Source _wcostreamSource = Source(
    name: "WCOStream",
    baseUrl: "https://wcostream.fr",
    apiUrl: "https://api.wcostream.fr",
    lang: "en",
    typeSource: "single",
    iconUrl: '',
    sourceCodeUrl: wcostreamSourceCodeUrl,
    version: wcostreamVersion,
    isManga: false,
    isFullData: false);

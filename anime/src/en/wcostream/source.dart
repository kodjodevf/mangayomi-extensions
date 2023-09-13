import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get wcostreamSource => _wcostreamSource;
const wcostreamVersion = "0.0.11";
const wcostreamSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/en/wcostream/wcostream-v$wcostreamVersion.dart";
Source _wcostreamSource = Source(
    name: "WCOStream",
    baseUrl: "https://www.wcostream.org",
    lang: "en",
    typeSource: "single",
    iconUrl: getIconUrl("wcostream", "en"),
    sourceCodeUrl: wcostreamSourceCodeUrl,
    version: wcostreamVersion,
    isManga: false,
    isFullData: false);

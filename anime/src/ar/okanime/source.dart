import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get okanimeSource => _okanimeSource;
const okanimeVersion = "0.0.2";
const okanimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/ar/okanime/okanime-v$okanimeVersion.dart";
Source _okanimeSource = Source(
    name: "Okanime",
    baseUrl: "https://www.okanime.xyz",
    lang: "ar",
    typeSource: "single",
    iconUrl: getIconUrl("okanime", "ar"),
    sourceCodeUrl: okanimeSourceCodeUrl,
    version: okanimeVersion,
    isManga: false);

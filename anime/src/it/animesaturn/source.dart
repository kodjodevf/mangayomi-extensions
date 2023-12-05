import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get animesaturn => _animesaturn;
const animesaturnVersion = "0.0.1";
const animesaturnCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/it/animesaturn/animesaturn-v$animesaturnVersion.dart";
Source _animesaturn = Source(
    name: "AnimeSaturn",
    baseUrl: "https://www.animesaturn.tv",
    lang: "it",
    typeSource: "single",
    iconUrl: getIconUrl("animesaturn", "it"),
    sourceCodeUrl: animesaturnCodeUrl,
    version: animesaturnVersion,
    isManga: false);

import '../../../../model/source.dart';

Source get animesaturn => _animesaturn;
const _animesaturnVersion = "0.0.1";
const _animesaturnCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/it/animesaturn/animesaturn-v$_animesaturnVersion.dart";
Source _animesaturn = Source(
    name: "AnimeSaturn",
    baseUrl: "https://www.animesaturn.tv",
    lang: "it",
    typeSource: "single",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/it/animesaturn/icon.png",
    sourceCodeUrl: _animesaturnCodeUrl,
    version: _animesaturnVersion,
    isManga: false);

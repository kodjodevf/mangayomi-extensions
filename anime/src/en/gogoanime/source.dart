import '../../../../model/source.dart';

Source get gogoanimeSource => _gogoanimeSource;
const gogoanimeVersion = "0.0.12";
const gogoanimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/en/gogoanime/gogoanime-v$gogoanimeVersion.dart";
Source _gogoanimeSource = Source(
    name: "Gogoanime",
    baseUrl: "https://gogoanime.tel",
    lang: "en",
    typeSource: "single",
    iconUrl: 'https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/icon/mangayomi-en-gogoanime.png',
    sourceCodeUrl: gogoanimeSourceCodeUrl,
    version: gogoanimeVersion,
    isManga: false);

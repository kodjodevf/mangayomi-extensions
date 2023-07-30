import '../../../model/source.dart';

Source get franimeSource => _franimeSource;
const franimeVersion = "0.0.1";
const franimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/fr/franime/franime-v$franimeVersion.dart";
Source _franimeSource = Source(
    name: "FrAnime",
    baseUrl: "https://franime.fr",
    apiUrl: "https://api.franime.fr",
    lang: "fr",
    typeSource: "single",
    iconUrl: '',
    sourceCodeUrl: franimeSourceCodeUrl,
    version: franimeVersion,
    isManga: false,
    isFullData: true);

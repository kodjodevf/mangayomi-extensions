import '../../../../model/source.dart';

Source get universanimeSource => _universanimeSource;
const universanimeVersion = "0.0.12";
const universanimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/fr/universanime/universanime-v$universanimeVersion.dart";
Source _universanimeSource = Source(
    name: "UniversAnime",
    baseUrl: "https://www.universanime.co",
    lang: "fr",
    typeSource: "single",
    iconUrl: '',
    sourceCodeUrl: universanimeSourceCodeUrl,
    version: universanimeVersion,
    isManga: false,
    isFullData: true);

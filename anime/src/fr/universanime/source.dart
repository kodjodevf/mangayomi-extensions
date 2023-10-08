import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

Source get universanimeSource => _universanimeSource;
const universanimeVersion = "0.0.2";
const universanimeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/src/fr/universanime/universanime-v$universanimeVersion.dart";
Source _universanimeSource = Source(
    name: "UniversAnime",
    baseUrl: "https://www.universanime.club",
    lang: "fr",
    typeSource: "single",
    iconUrl: getIconUrl("universanime", "fr"),
    sourceCodeUrl: universanimeSourceCodeUrl,
    version: universanimeVersion,
    isManga: false,
    isFullData: true);

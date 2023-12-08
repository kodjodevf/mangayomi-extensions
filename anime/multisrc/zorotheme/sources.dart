import '../../../model/source.dart';
import 'src/aniwatch/aniwatch.dart';
import 'src/kaido/kaido.dart';

const _zorothemeVersion = "0.0.55";
const _zorothemeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/multisrc/zorotheme/zorotheme-v$_zorothemeVersion.dart";

List<Source> get zorothemeSourcesList => _zorothemeSourcesList;
List<Source> _zorothemeSourcesList = [
//AniWatch.to (EN)
  aniwatchSource,
//Kaido.to (EN)
  kaidoSource,
]
    .map((e) => e
      ..sourceCodeUrl = _zorothemeSourceCodeUrl
      ..version = _zorothemeVersion)
    .toList();

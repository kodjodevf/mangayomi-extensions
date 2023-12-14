import '../../../model/source.dart';
import 'src/frenchanime/frenchanime-v0.0.1.dart';
import 'src/wiflix/wiflix.dart';

const _datalifeengineVersion = "0.0.1";
const _datalifeengineSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/multisrc/datalifeengine/datalifeengine-v$_datalifeengineVersion.dart";

List<Source> get datalifeengineSourcesList => _datalifeengineSourcesList;
List<Source> _datalifeengineSourcesList = [
//French Anime (FR)
  frenchanimeSource,
//Wiflix (FR)
  wiflixSource,
]
    .map((e) => e
      ..sourceCodeUrl = _datalifeengineSourceCodeUrl
      ..version = _datalifeengineVersion)
    .toList();

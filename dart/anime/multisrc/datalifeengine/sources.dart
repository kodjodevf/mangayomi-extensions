import '../../../../model/source.dart';
import 'src/frenchanime/frenchanime.dart';
import 'src/wiflix/wiflix.dart';

const _datalifeengineVersion = "0.0.45";
const _datalifeengineSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/multisrc/datalifeengine/datalifeengine.dart";

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

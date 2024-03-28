import '../../../../model/source.dart';
import 'src/hianime/hianime.dart';
import 'src/kaido/kaido.dart';

const _zorothemeVersion = "0.0.9";
const _zorothemeSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/multisrc/zorotheme/zorotheme.dart";

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

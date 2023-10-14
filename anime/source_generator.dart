import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import '../model/source.dart';
import 'src/ar/source.dart';
import 'src/en/aniwatch/sources.dart';
import 'src/en/gogoanime/source.dart';
// import 'src/en/wcostream/source.dart';
import 'src/en/kisskh/source.dart';
import 'src/fr/animesultra/source.dart';
import 'src/fr/franime/source.dart';
import 'src/fr/otakufr/source.dart';
import 'src/fr/universanime/source.dart';

void main() {
  List<Source> _sourcesList = [
    gogoanimeSource,
    franimeSource,
    universanimeSource,
    otakufr,
    // wcostreamSource,
    animesultraSource,
    ...aniwatchSourcesList,
    kisskhSource,
    okanimeSource
  ];
  final List<Map<String, dynamic>> jsonList =
      _sourcesList.map((source) => source.toJson()).toList();
  final jsonString = jsonEncode(jsonList);

  final file = File('anime_index.json');
  file.writeAsStringSync(jsonString);

  log('JSON file created: ${file.path}');
}

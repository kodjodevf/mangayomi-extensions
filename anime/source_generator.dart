import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import '../model/source.dart';
import 'src/en/gogoanime/source.dart';

void main() {
  List<Source> _sourcesList = [gogoanimeSource];
  final List<Map<String, dynamic>> jsonList =
      _sourcesList.map((source) => source.toJson()).toList();
  final jsonString = jsonEncode(jsonList);

  final file = File('anime_index.json');
  file.writeAsStringSync(jsonString);

  log('JSON file created: ${file.path}');
}

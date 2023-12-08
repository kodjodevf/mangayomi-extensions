import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import '../model/source.dart';
import 'multisrc/heancms/sources.dart';
import 'multisrc/madara/sources.dart';
import 'multisrc/mangareader/sources.dart';
import 'multisrc/mmrcms/sources.dart';
import 'multisrc/nepnep/sources.dart';
import 'src/all/batoto/sources.dart';
import 'src/all/comick/sources.dart';
import 'src/all/mangadex/sources.dart';
import 'src/en/mangahere/source.dart';

void main() {
  List<Source> sourcesList = [
    ...madaraSourcesList,
    ...comickSourcesList,
    ...mangaDexSourcesList,
    ...mangareaderSourcesList,
    ...mmrcmsSourcesList,
    ...heancmsSourcesList,
    mangahereSource,
    ...batotoSourcesList,
    ...nepnepSourcesList
  ];
  final List<Map<String, dynamic>> jsonList =
      sourcesList.map((source) => source.toJson()).toList();
  final jsonString = jsonEncode(jsonList);

  final file = File('index.json');
  file.writeAsStringSync(jsonString);

  log('JSON file created: ${file.path}');
}

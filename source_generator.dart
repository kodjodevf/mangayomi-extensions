import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart/manga/manga_source_list.dart';
import 'dart/novel/novel_source_list.dart';
import 'model/source.dart';

void main() {
  final jsSources = _searchJsSources(Directory("javascript"));
  genManga(
    jsSources.where((element) => element.itemType!.name == "manga").toList(),
  );
  genNovel(
    jsSources.where((element) => element.itemType!.name == "novel").toList(),
  );
}

void genManga(List<Source> jsMangasourceList) {
  List<Source> mangaSources = [];
  mangaSources.addAll(dartMangasourceList);
  mangaSources.addAll(jsMangasourceList);
  final List<Map<String, dynamic>> jsonList = mangaSources
      .map((source) => source.toJson())
      .toList();
  final jsonString = jsonEncode(jsonList);

  final file = File('index.json');
  file.writeAsStringSync(jsonString);

  log('JSON file created: ${file.path}');
}

void genNovel(List<Source> jsNovelSourceList) {
  List<Source> novelSources = [];
  novelSources.addAll(dartNovelSourceList);
  novelSources.addAll(jsNovelSourceList);
  final List<Map<String, dynamic>> jsonList = novelSources
      .map((source) => source.toJson())
      .toList();
  final jsonString = jsonEncode(jsonList);

  final file = File('novel_index.json');
  file.writeAsStringSync(jsonString);

  log('JSON file created: ${file.path}');
}

List<Source> _searchJsSources(Directory dir) {
  List<Source> sourceList = [];
  List<FileSystemEntity> entities = dir.listSync();
  for (FileSystemEntity entity in entities) {
    if (entity is Directory) {
      List<FileSystemEntity> entities = entity.listSync();
      for (FileSystemEntity entity in entities) {
        if (entity is Directory) {
          sourceList.addAll(_searchJsSources(entity));
        } else if (entity is File && entity.path.endsWith('.js')) {
          final regex = RegExp(
            r'const\s+mangayomiSources\s*=\s*(\[.*?\]);',
            dotAll: true,
          );
          final defaultSource = Source();
          final match = regex.firstMatch(entity.readAsStringSync());
          if (match != null) {
            for (var sourceJson in jsonDecode(match.group(1)!) as List) {
              final langs = sourceJson["langs"] as List?;
              Source source = Source.fromJson(sourceJson)
                ..sourceCodeLanguage = 1
                ..appMinVerReq =
                    sourceJson["appMinVerReq"] ?? defaultSource.appMinVerReq
                ..sourceCodeUrl =
                    "https://raw.githubusercontent.com/entityJY/mangayomi-extensions-eJ/$branchName/javascript/${sourceJson["pkgPath"] ?? sourceJson["pkgName"]}";
              if (sourceJson["id"] != null) {
                source = source..id = int.tryParse("${sourceJson["id"]}");
              }
              if (langs?.isNotEmpty ?? false) {
                for (var lang in langs!) {
                  final id = sourceJson["ids"]?[lang] as int?;
                  sourceList.add(
                    Source.fromJson(source.toJson())
                      ..lang = lang
                      ..id =
                          id ??
                          'mangayomi-js-"$lang"."${source.name}"'.hashCode,
                  );
                }
              } else {
                sourceList.add(source);
              }
            }
          }
        }
      }
    }
  }
  return sourceList;
}

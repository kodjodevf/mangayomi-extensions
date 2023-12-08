import 'dart:io';

import '../manga/multisrc/madara/sources.dart';

void main(List<String> args) {
  String import = "";
  String listSource =
      """List<Source> get madaraSourcesList => _madaraSourcesList;
List<Source> _madaraSourcesList = [""";
  // sourcesList.sort((a, b) => a.name!.compareTo(b.name!));
  for (var sou in madaraSourcesList) {
    final madaraSourceFile = File(
        'C:/DEV/flutter/mangayomi-extensions/anime/multisrc/madara/src/${sou.name!.toLowerCase()}/${sou.name!.toLowerCase()}.dart');
    final dateFormat =
        sou.dateFormat!.isEmpty ? '' : 'dateFormat:"${sou.dateFormat}",';
    final dateFormatLocale = sou.dateFormatLocale!.isEmpty
        ? ''
        : 'dateFormatLocale:"${sou.dateFormatLocale!.toLowerCase()}",';
    final isNsfw = sou.isNsfw! ? '' : 'isNsfw: true,';
    final iconUrl = sou.name!.isEmpty
        ? ''
        : 'iconUrl:${getIconUrl(sou.name!.toLowerCase())},';
    final test = ''' 
  import '../../../../../model/source.dart';

  Source get ${sou.name!.toLowerCase()}Source => _${sou.name!.toLowerCase()}Source;
            
  Source _${sou.name!.toLowerCase()}Source = Source(
    name: "${sou.name}",
    baseUrl: "${sou.baseUrl}",
    lang: "${sou.lang}",
    $isNsfw
    typeSource: "${sou.typeSource}",
    $iconUrl
    $dateFormat
    $dateFormatLocale
  );''';
    madaraSourceFile.writeAsStringSync(test.trimLeft().trimRight().trim());
  }
  listSource += " ];";
  print(import + listSource);
}

String getIconUrl(String name) {
  return '"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime/multisrc/madara/src/$name/icon.png"';
}

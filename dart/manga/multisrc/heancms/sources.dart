import '../../../../model/source.dart';
import 'src/yugenmangas/yugenmangas.dart';
import 'src/omegascans/omegascans.dart';
import 'src/perfscan/perfscan.dart';

const heancmsVersion = "0.0.75";
const heancmsSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/heancms/heancms.dart";

List<Source> get heancmsSourcesList => _heancmsSourcesList;
List<Source> _heancmsSourcesList = [
//YugenMangas (ES)
  yugenmangasSource,
//OmegaScans (EN)
  omegascansSource,
//Perf Scan (FR)
  perfscanSource,
]
    .map((e) => e
      ..sourceCodeUrl = heancmsSourceCodeUrl
      ..version = heancmsVersion)
    .toList();

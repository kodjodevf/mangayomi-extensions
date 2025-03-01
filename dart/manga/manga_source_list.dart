import '../../model/source.dart';
import 'multisrc/madara/sources.dart';
import 'multisrc/mangabox/sources.dart';
import 'multisrc/mangareader/sources.dart';
import 'multisrc/mmrcms/sources.dart';
import 'multisrc/nepnep/sources.dart';
import 'src/en/mangahere/source.dart';

List<Source> dartMangasourceList = [
  ...madaraSourcesList,
  ...mangareaderSourcesList,
  ...mmrcmsSourcesList,
  mangahereSource,
  ...nepnepSourcesList,
  ...mangaboxSourcesList,
];

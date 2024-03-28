import '../../model/source.dart';
import 'multisrc/heancms/sources.dart';
import 'multisrc/madara/sources.dart';
import 'multisrc/mangabox/sources.dart';
import 'multisrc/mangareader/sources.dart';
import 'multisrc/mmrcms/sources.dart';
import 'multisrc/nepnep/sources.dart';
import 'src/all/batoto/sources.dart';
import 'src/all/comick/sources.dart';
import 'src/all/mangadex/sources.dart';
import 'src/all/nhentai/sources.dart';
import 'src/en/mangahere/source.dart';

List<Source> dartMangasourceList = [
  ...madaraSourcesList,
  ...comickSourcesList,
  ...mangaDexSourcesList,
  ...mangareaderSourcesList,
  ...mmrcmsSourcesList,
  ...heancmsSourcesList,
  mangahereSource,
  ...nepnepSourcesList,
  ...mangaboxSourcesList,
  ...batotoSourcesList,
  ...nhentaiSourcesList
];

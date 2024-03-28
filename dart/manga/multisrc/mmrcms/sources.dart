import '../../../../model/source.dart';
import 'src/scanvf/scanvf.dart';
import 'src/komikid/komikid.dart';
import 'src/mangaid/mangaid.dart';
import 'src/jpmangas/jpmangas.dart';
import 'src/onma/onma.dart';
import 'src/readcomicsonline/readcomicsonline.dart';
import 'src/lelscanvf/lelscanvf.dart';
import 'src/mangafr/mangafr.dart';

const mmrcmsVersion = "0.0.65";
const mmrcmsSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mmrcms/mmrcms.dart";

List<Source> get mmrcmsSourcesList => _mmrcmsSourcesList;
List<Source> _mmrcmsSourcesList = [
//Scan VF (FR)
  scanvfSource,
//Komikid (ID)
  komikidSource,
//MangaID (ID)
  mangaidSource,
//Jpmangas (FR)
  jpmangasSource,
//مانجا اون لاين (AR)
  onmaSource,
//Read Comics Online (EN)
  readcomicsonlineSource,
//Lelscan-VF (FR)
  lelscanvfSource,
//Manga-FR (FR)
  mangafrSource,
]
    .map((e) => e
      ..sourceCodeUrl = mmrcmsSourceCodeUrl
      ..version = mmrcmsVersion)
    .toList();

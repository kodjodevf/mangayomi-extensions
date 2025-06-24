import '../../../../model/source.dart';
import 'src/fr/scanvf/scanvf.dart';
import 'src/ar/onma/onma.dart';
import 'src/en/readcomicsonline/readcomicsonline.dart';

const mmrcmsVersion = "0.0.8";
const mmrcmsSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mmrcms/mmrcms.dart";

List<Source> get mmrcmsSourcesList => _mmrcmsSourcesList;
List<Source> _mmrcmsSourcesList =
    [
          //Scan VF (FR)
          scanvfSource,
          //مانجا اون لاين (AR)
          onmaSource,
          //Read Comics Online (EN)
          readcomicsonlineSource,
        ]
        .map(
          (e) => e
            ..itemType = ItemType.manga
            ..sourceCodeUrl = mmrcmsSourceCodeUrl
            ..version = mmrcmsVersion,
        )
        .toList();

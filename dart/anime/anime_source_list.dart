import '../../model/source.dart';
import 'multisrc/datalifeengine/sources.dart';
import 'multisrc/dopeflix/sources.dart';
import 'multisrc/zorotheme/sources.dart';
import 'src/all/animeworldindia/sources.dart';
import 'src/all/nyaa/source.dart';
import 'src/ar/okanime/source.dart';
import 'src/de/aniflix/source.dart';
import 'src/de/animetoast/source.dart';
import 'src/en/animepahe/source.dart';
import 'src/en/aniwave/source.dart';
import 'src/en/dramacool/source.dart';
import 'src/en/gogoanime/source.dart';
import 'src/en/nineanimetv/source.dart';
import 'src/fr/animesama/source.dart';
import 'src/hi/yomovies/source.dart';
import 'src/en/kisskh/source.dart';
import 'src/en/uhdmovies/source.dart';
import 'src/fr/animesultra/source.dart';
import 'src/fr/franime/source.dart';
import 'src/fr/otakufr/source.dart';
import 'src/id/nimegami/source.dart';
import 'src/id/oploverz/source.dart';
import 'src/id/otakudesu/source.dart';
import 'src/it/animesaturn/source.dart';
import 'src/pt/animesvision/source.dart';
import 'src/sq/filma24/source.dart';

List<Source> dartAnimesourceList = [
  gogoanimeSource,
  franimeSource,
  otakufr,
  animesultraSource,
  ...zorothemeSourcesList,
  kisskhSource,
  okanimeSource,
  otakudesu,
  nimegami,
  oploverz,
  aniwave,
  ...dopeflixSourcesList,
  animesaturn,
  uhdmoviesSource,
  ...datalifeengineSourcesList,
  filma24,
  dramacoolSource,
  yomoviesSource,
  animesamaSource,
  nineanimetv,
  aniflix,
  ...animeworldindiaSourcesList,
  nyaaSource,
  animepaheSource,
  animetoast,
  animesvision
];

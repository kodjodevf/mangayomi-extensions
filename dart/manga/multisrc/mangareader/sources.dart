import '../../../../model/source.dart';
import 'src/beastscans/beastscans.dart';
import 'src/lelmanga/lelmanga.dart';
import 'src/asurascans/asurascans.dart';
import 'src/komiklab/komiklab.dart';
import 'src/azurescans/azurescans.dart';
import 'src/cosmicscans/cosmicscans.dart';
import 'src/cosmicscansid/cosmicscansid.dart';
import 'src/dojingnet/dojingnet.dart';
import 'src/duniakomikid/duniakomikid.dart';
import 'src/geceninlordu/geceninlordu.dart';
import 'src/infernalvoidscans/infernalvoidscans.dart';
import 'src/katakomik/katakomik.dart';
import 'src/kanzenin/kanzenin.dart';
import 'src/komikstation/komikstation.dart';
import 'src/komikmama/komikmama.dart';
import 'src/kumapoi/kumapoi.dart';
import 'src/komikucom/komikucom.dart';
import 'src/magusmanga/magusmanga.dart';
import 'src/mangaindome/mangaindome.dart';
import 'src/mangacim/mangacim.dart';
import 'src/mangatale/mangatale.dart';
import 'src/mangawt/mangawt.dart';
import 'src/manhwax/manhwax.dart';
import 'src/melokomik/melokomik.dart';
import 'src/mihentai/mihentai.dart';
import 'src/origamiorpheans/origamiorpheans.dart';
import 'src/phenixscans/phenixscans.dart';
import 'src/piscans/piscans.dart';
import 'src/raikiscan/raikiscan.dart';
import 'src/ravenscans/ravenscans.dart';
import 'src/shadowmangas/shadowmangas.dart';
import 'src/suryascans/suryascans.dart';
import 'src/sushiscans/sushiscans.dart';
import 'src/sushiscan/sushiscan.dart';
import 'src/tarotscans/tarotscans.dart';
import 'src/tukangkomik/tukangkomik.dart';
import 'src/turktoon/turktoon.dart';
import 'src/uzaymanga/uzaymanga.dart';
import 'src/xcalibrscans/xcalibrscans.dart';

const mangareaderVersion = "0.0.9";
const mangareaderSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/mangareader.dart";

List<Source> get mangareaderSourcesList => _mangareaderSourcesList;
List<Source> _mangareaderSourcesList = [
//Beast Scans (AR)
  beastscansSource,
//Lelmanga (FR)
  lelmangaSource,
//Asura Scans (EN)
  asurascansSource,
//KomikLab Scans (EN)
  komiklabSource,
//Azure Scans (EN)
  azurescansSource,
//Cosmic Scans (EN)
  cosmicscansSource,
//CosmicScans.id (ID)
  cosmicscansidSource,
//Dojing.net (ID)
  dojingnetSource,
//DuniaKomik.id (ID)
  duniakomikidSource,
//Gecenin Lordu (TR)
  geceninlorduSource,
//Infernal Void Scans (EN)
  infernalvoidscansSource,
//KataKomik (ID)
  katakomikSource,
//Kanzenin (ID)
  kanzeninSource,
//Komik Station (ID)
  komikstationSource,
//KomikMama (ID)
  komikmamaSource,
//KumaPoi (ID)
  kumapoiSource,
//Komiku.com (ID)
  komikucomSource,
//Magus Manga (AR)
  magusmangaSource,
//Manga Indo.me (ID)
  mangaindomeSource,
//Mangacim (TR)
  mangacimSource,
//MangaTale (ID)
  mangataleSource,
//MangaWT (TR)
  mangawtSource,
//Manhwax (EN)
  manhwaxSource,
//MELOKOMIK (ID)
  melokomikSource,
//Mihentai (ALL)
  mihentaiSource,
//Origami Orpheans (PT-BR)
  origamiorpheansSource,
//PhenixScans (FR)
  phenixscansSource,
//Pi Scans (ID)
  piscansSource,
//Raiki Scan (ES)
  raikiscanSource,
//Raven Scans (EN)
  ravenscansSource,
//Shadow Mangas (ES)
  shadowmangasSource,
//Surya Scans (EN)
  suryascansSource,
//Sushi-Scans (FR)
  sushiscansSource,
//Sushi-Scan (FR)
  sushiscanSource,
//Tarot Scans (TR)
  tarotscansSource,
//TukangKomik (ID)
  tukangkomikSource,
//TurkToon (TR)
  turktoonSource,
//Uzay Manga (TR)
  uzaymangaSource,
//xCaliBR Scans (EN)
  xcalibrscansSource,
]
    .map((e) => e
      ..sourceCodeUrl = mangareaderSourceCodeUrl
      ..version = mangareaderVersion)
    .toList();

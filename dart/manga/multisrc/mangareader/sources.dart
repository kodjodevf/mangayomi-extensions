import '../../../../model/source.dart';
import 'src/lelmanga/lelmanga.dart';
import 'src/komiklab/komiklab.dart';
import 'src/azurescans/azurescans.dart';
import 'src/cosmicscans/cosmicscans.dart';
import 'src/cosmicscansid/cosmicscansid.dart';
import 'src/duniakomikid/duniakomikid.dart';
import 'src/geceninlordu/geceninlordu.dart';
import 'src/infernalvoidscans/infernalvoidscans.dart';
import 'src/katakomik/katakomik.dart';
import 'src/komikstation/komikstation.dart';
import 'src/komikmama/komikmama.dart';
import 'src/komikucom/komikucom.dart';
import 'src/mangaindome/mangaindome.dart';
import 'src/mangacim/mangacim.dart';
import 'src/mangatale/mangatale.dart';
import 'src/mangawt/mangawt.dart';
import 'src/melokomik/melokomik.dart';
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
import 'src/miauscan/miauscan.dart';
import 'src/thunderscans/thunderscans.dart';
import 'src/areamanga/areamanga.dart';
import 'src/areascans/areascans.dart';
import 'src/aresnov/aresnov.dart';
import 'src/mangaflame/mangaflame.dart';
import 'src/manganoon/manganoon.dart';
import 'src/mangaswat/mangaswat.dart';
import 'src/potatomanga/potatomanga.dart';
import 'src/stellarsaber/stellarsaber.dart';
import 'src/rizzcomic/rizzcomic.dart';
import 'src/berserkerscan/berserkerscan.dart';
import 'src/carteldemanhwas/carteldemanhwas.dart';
import 'src/dtupscan/dtupscan.dart';
import 'src/gremorymangas/gremorymangas.dart';
import 'src/ryujinmanga/ryujinmanga.dart';
import 'src/senpaiediciones/senpaiediciones.dart';
import 'src/skymangas/skymangas.dart';
import 'src/flamescansfr/flamescansfr.dart';
import 'src/mangasscans/mangasscans.dart';
import 'src/rimuscans/rimuscans.dart';
import 'src/vfscan/vfscan.dart';
import 'src/comicaso/comicaso.dart';
import 'src/kiryuu/kiryuu.dart';
import 'src/komikav/komikav.dart';
import 'src/komikindoco/komikindoco.dart';
import 'src/mangakyo/mangakyo.dart';
import 'src/mangayu/mangayu.dart';
import 'src/mangkomik/mangkomik.dart';
import 'src/masterkomik/masterkomik.dart';
import 'src/natsu/natsu.dart';
import 'src/sheamanga/sheamanga.dart';
import 'src/shirakami/shirakami.dart';
import 'src/walpurgisscan/walpurgisscan.dart';
import 'src/diskusscan/diskusscan.dart';
import 'src/irisscanlator/irisscanlator.dart';
import 'src/mangaschan/mangaschan.dart';
import 'src/mangasonline/mangasonline.dart';
import 'src/sssscanlator/sssscanlator.dart';
import 'src/tsundokutraducoes/tsundokutraducoes.dart';
import 'src/mangamoon/mangamoon.dart';
import 'src/adumanga/adumanga.dart';
import 'src/afroditscans/afroditscans.dart';
import 'src/athenamanga/athenamanga.dart';
import 'src/gaiatoon/gaiatoon.dart';
import 'src/majorscans/majorscans.dart';
import 'src/mangaefendisi/mangaefendisi.dart';
import 'src/mangakings/mangakings.dart';
import 'src/merlinshoujo/merlinshoujo.dart';
import 'src/nirvanamanga/nirvanamanga.dart';
import 'src/patimanga/patimanga.dart';
import 'src/raindropfansub/raindropfansub.dart';
import 'src/sereinscan/sereinscan.dart';
import 'src/shijiescans/shijiescans.dart';
import 'src/summertoon/summertoon.dart';
import 'src/zenithscans/zenithscans.dart';

const mangareaderVersion = "0.1.65";
const mangareaderSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/mangareader.dart";

List<Source> get mangareaderSourcesList => _mangareaderSourcesList;
List<Source> _mangareaderSourcesList =
    [
          //Lelmanga (FR)
          lelmangaSource,
          //KomikLab Scans (EN)
          komiklabSource,
          //Azure Scans (EN)
          azurescansSource,
          //Cosmic Scans (EN)
          cosmicscansSource,
          //CosmicScans.id (ID)
          cosmicscansidSource,
          //DuniaKomik.id (ID)
          duniakomikidSource,
          //Gecenin Lordu (TR)
          geceninlorduSource,
          //Infernal Void Scans (EN)
          infernalvoidscansSource,
          //KataKomik (ID)
          katakomikSource,
          //Komik Station (ID)
          komikstationSource,
          //KomikMama (ID)
          komikmamaSource,
          //Komiku.com (ID)
          komikucomSource,
          //Manga Indo.me (ID)
          mangaindomeSource,
          //Mangacim (TR)
          mangacimSource,
          //MangaTale (ID)
          mangataleSource,
          //MangaWT (TR)
          mangawtSource,
          //MELOKOMIK (ID)
          melokomikSource,
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
          //Miau Scan (ALL)
          miauscanSource,
          //Thunder Scans (ALL)
          thunderscansSource,
          //أريا مانجا (AR)
          areamangaSource,
          //Area Scans (AR)
          areascansSource,
          //SCARManga (AR)
          aresnovSource,
          //Umi Manga (AR)
          beastscansSource,
          //Manga Flame (AR)
          mangaflameSource,
          //مانجا نون (AR)
          manganoonSource,
          //MangaSwat (AR)
          mangaswatSource,
          //PotatoManga (AR)
          potatomangaSource,
          //StellarSaber (AR)
          stellarsaberSource,
          //Rizz Comic (EN)
          rizzcomicSource,
          //Berserker Scan (ES)
          berserkerscanSource,
          //Cartel de Manhwas (ES)
          carteldemanhwasSource,
          //De Todo Un Poco Scan (ES)
          dtupscanSource,
          //Gremory Mangas (ES)
          gremorymangasSource,
          //RyujinManga (ES)
          ryujinmangaSource,
          //Senpai Ediciones (ES)
          senpaiedicionesSource,
          //SkyMangas (ES)
          skymangasSource,
          //Legacy Scans (FR)
          flamescansfrSource,
          //Mangas Scans (FR)
          mangasscansSource,
          //Rimu Scans (FR)
          rimuscansSource,
          //VF Scan (FR)
          vfscanSource,
          //Comicaso (ID)
          comicasoSource,
          //Kiryuu (ID)
          kiryuuSource,
          //APKOMIK (ID)
          komikavSource,
          //KomikIndo.co (ID)
          komikindocoSource,
          //Mangakyo (ID)
          mangakyoSource,
          //MangaYu (ID)
          mangayuSource,
          //Siren Komik (ID)
          mangkomikSource,
          //Tenshi.id (ID)
          masterkomikSource,
          //Natsu (ID)
          natsuSource,
          //Shea Manga (ID)
          sheamangaSource,
          //Shirakami (ID)
          shirakamiSource,
          //Walpurgi Scan (IT)
          walpurgisscanSource,
          //Diskus Scan (PT-BR)
          diskusscanSource,
          //Iris Scanlator (PT-BR)
          irisscanlatorSource,
          //Mangás Chan (PT-BR)
          mangaschanSource,
          //Mangás Online (PT-BR)
          mangasonlineSource,
          //SSSScanlator (PT-BR)
          sssscanlatorSource,
          //Tsundoku Traduções (PT-BR)
          tsundokutraducoesSource,
          //Manga-Moon (TH)
          mangamoonSource,
          //Adu Manga (TR)
          adumangaSource,
          //Afrodit Scans (TR)
          afroditscansSource,
          //Athena Manga (TR)
          athenamangaSource,
          //Gaiatoon (TR)
          gaiatoonSource,
          //MajorScans (TR)
          majorscansSource,
          //Manga Efendisi (TR)
          mangaefendisiSource,
          //Manga Kings (TR)
          mangakingsSource,
          //Merlin Shoujo (TR)
          merlinshoujoSource,
          //Nirvana Manga (TR)
          nirvanamangaSource,
          //Pati Manga (TR)
          patimangaSource,
          //Raindrop Fansub (TR)
          raindropfansubSource,
          //Serein Scan (TR)
          sereinscanSource,
          //Shijie Scans (TR)
          shijiescansSource,
          //SummerToon (TR)
          summertoonSource,
          //Zenith Scans (TR)
          zenithscansSource,
        ]
        .map(
          (e) =>
              e
                ..itemType = ItemType.manga
                ..sourceCodeUrl = mangareaderSourceCodeUrl
                ..version = mangareaderVersion,
        )
        .toList();

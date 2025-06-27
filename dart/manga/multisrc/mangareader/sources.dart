import '../../../../model/source.dart';
import 'src/en/erosscans/erosscans.dart';
import 'src/fr/lelmanga/lelmanga.dart';
import 'src/en/komiklab/komiklab.dart';
import 'src/en/azurescans/azurescans.dart';
import 'src/en/cosmicscans/cosmicscans.dart';
import 'src/id/cosmicscansid/cosmicscansid.dart';
import 'src/id/duniakomikid/duniakomikid.dart';
import 'src/tr/geceninlordu/geceninlordu.dart';
import 'src/en/infernalvoidscans/infernalvoidscans.dart';
import 'src/id/katakomik/katakomik.dart';
import 'src/id/komikstation/komikstation.dart';
import 'src/id/komikmama/komikmama.dart';
import 'src/id/komikucom/komikucom.dart';
import 'src/id/mangaindome/mangaindome.dart';
import 'src/tr/mangacim/mangacim.dart';
import 'src/id/mangatale/mangatale.dart';
import 'src/tr/mangawt/mangawt.dart';
import 'src/id/melokomik/melokomik.dart';
import 'src/pt/origamiorpheans/origamiorpheans.dart';
import 'src/fr/phenixscans/phenixscans.dart';
import 'src/id/piscans/piscans.dart';
import 'src/es/raikiscan/raikiscan.dart';
import 'src/en/ravenscans/ravenscans.dart';
import 'src/es/shadowmangas/shadowmangas.dart';
import 'src/en/suryascans/suryascans.dart';
import 'src/fr/sushiscans/sushiscans.dart';
import 'src/fr/sushiscan/sushiscan.dart';
import 'src/tr/tarotscans/tarotscans.dart';
import 'src/id/tukangkomik/tukangkomik.dart';
import 'src/tr/turktoon/turktoon.dart';
import 'src/tr/uzaymanga/uzaymanga.dart';
import 'src/en/xcalibrscans/xcalibrscans.dart';
import 'src/all/miauscan/miauscan.dart';
import 'src/all/thunderscans/thunderscans.dart';
import 'src/ar/areamanga/areamanga.dart';
import 'src/ar/areascans/areascans.dart';
import 'src/ar/aresnov/aresnov.dart';
import 'src/ar/mangaflame/mangaflame.dart';
import 'src/ar/manganoon/manganoon.dart';
import 'src/ar/mangaswat/mangaswat.dart';
import 'src/ar/stellarsaber/stellarsaber.dart';
import 'src/en/rizzcomic/rizzcomic.dart';
import 'src/es/berserkerscan/berserkerscan.dart';
import 'src/es/carteldemanhwas/carteldemanhwas.dart';
import 'src/es/dtupscan/dtupscan.dart';
import 'src/es/gremorymangas/gremorymangas.dart';
import 'src/es/ryujinmanga/ryujinmanga.dart';
import 'src/es/senpaiediciones/senpaiediciones.dart';
import 'src/es/skymangas/skymangas.dart';
import 'src/fr/flamescansfr/flamescansfr.dart';
import 'src/fr/mangasscans/mangasscans.dart';
import 'src/fr/rimuscans/rimuscans.dart';
import 'src/fr/vfscan/vfscan.dart';
import 'src/id/comicaso/comicaso.dart';
import 'src/id/kiryuu/kiryuu.dart';
import 'src/id/komikav/komikav.dart';
import 'src/id/komikindoco/komikindoco.dart';
import 'src/id/mangakyo/mangakyo.dart';
import 'src/id/mangayu/mangayu.dart';
import 'src/id/mangkomik/mangkomik.dart';
import 'src/id/masterkomik/masterkomik.dart';
import 'src/id/natsu/natsu.dart';
import 'src/id/sheamanga/sheamanga.dart';
import 'src/id/shirakami/shirakami.dart';
import 'src/it/walpurgisscan/walpurgisscan.dart';
import 'src/pt/diskusscan/diskusscan.dart';
import 'src/pt/irisscanlator/irisscanlator.dart';
import 'src/pt/mangaschan/mangaschan.dart';
import 'src/pt/mangasonline/mangasonline.dart';
import 'src/pt/sssscanlator/sssscanlator.dart';
import 'src/pt/tsundokutraducoes/tsundokutraducoes.dart';
import 'src/th/mangamoon/mangamoon.dart';
import 'src/tr/adumanga/adumanga.dart';
import 'src/tr/afroditscans/afroditscans.dart';
import 'src/tr/athenamanga/athenamanga.dart';
import 'src/tr/gaiatoon/gaiatoon.dart';
import 'src/tr/majorscans/majorscans.dart';
import 'src/tr/mangaefendisi/mangaefendisi.dart';
import 'src/tr/mangakings/mangakings.dart';
import 'src/tr/merlinshoujo/merlinshoujo.dart';
import 'src/tr/nirvanamanga/nirvanamanga.dart';
import 'src/tr/patimanga/patimanga.dart';
import 'src/tr/raindropfansub/raindropfansub.dart';
import 'src/tr/sereinscan/sereinscan.dart';
import 'src/tr/shijiescans/shijiescans.dart';
import 'src/tr/summertoon/summertoon.dart';
import 'src/tr/zenithscans/zenithscans.dart';

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
          //Manga Flame (AR)
          mangaflameSource,
          //مانجا نون (AR)
          manganoonSource,
          //MangaSwat (AR)
          mangaswatSource,
          //StellarSaber (AR)
          stellarsaberSource,
          //Rizz Comic (EN)
          rizzcomicSource,
          //Berserker Scan (ES)
          berserkerscanSource,
          // Eros Scan (ES)
          erosscansSource,
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
          (e) => e
            ..itemType = ItemType.manga
            ..sourceCodeUrl = mangareaderSourceCodeUrl
            ..version = mangareaderVersion,
        )
        .toList();

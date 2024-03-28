import '../../../../../../model/source.dart';

  Source get hentaixcomicSource => _hentaixcomicSource;
            
  Source _hentaixcomicSource = Source(
    name: "HentaiXComic",
    baseUrl: "https://hentaixcomic.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/hentaixcomic/icon.png",
    dateFormat:"MMM d, yyyy",
    dateFormatLocale:"en_us",
  );
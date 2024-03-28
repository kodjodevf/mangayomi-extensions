import '../../../../../../model/source.dart';

  Source get hentaimangaSource => _hentaimangaSource;
            
  Source _hentaimangaSource = Source(
    name: "Hentai Manga",
    baseUrl: "https://hentaimanga.me",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/hentaimanga/icon.png",
    dateFormat:"MMM d, yyyy",
    dateFormatLocale:"en_us",
  );
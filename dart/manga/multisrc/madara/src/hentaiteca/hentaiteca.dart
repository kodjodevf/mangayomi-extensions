import '../../../../../../model/source.dart';

  Source get hentaitecaSource => _hentaitecaSource;
            
  Source _hentaitecaSource = Source(
    name: "Hentai Teca",
    baseUrl: "https://hentaiteca.net",
    lang: "pt-BR",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/hentaiteca/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"pt-br",
  );
import '../../../../../../model/source.dart';

  Source get mangasoriginesSource => _mangasoriginesSource;
            
  Source _mangasoriginesSource = Source(
    name: "Mangas Origines",
    baseUrl: "https://mangas-origines.xyz",
    lang: "fr",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/mangasorigines/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"fr",
  );
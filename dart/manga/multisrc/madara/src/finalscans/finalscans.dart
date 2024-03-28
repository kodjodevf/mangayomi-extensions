import '../../../../../../model/source.dart';

  Source get finalscansSource => _finalscansSource;
            
  Source _finalscansSource = Source(
    name: "Final Scans",
    baseUrl: "https://finalscans.com",
    lang: "pt-br",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/finalscans/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"pt-br",
  );
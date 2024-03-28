import '../../../../../../model/source.dart';

  Source get toonizySource => _toonizySource;
            
  Source _toonizySource = Source(
    name: "Toonizy",
    baseUrl: "https://toonizy.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/toonizy/icon.png",
    dateFormat:"MMM d, yy",
    dateFormatLocale:"en",
  );
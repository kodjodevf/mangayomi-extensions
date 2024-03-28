import '../../../../../../model/source.dart';

  Source get manhwanewSource => _manhwanewSource;
            
  Source _manhwanewSource = Source(
    name: "ManhwaNew",
    baseUrl: "https://manhwanew.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/manhwanew/icon.png",
    dateFormat:"dd/MM/yyyy",
    dateFormatLocale:"en",
  );
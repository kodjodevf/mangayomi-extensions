import '../../../../../../model/source.dart';

  Source get manhwahentaimeSource => _manhwahentaimeSource;
            
  Source _manhwahentaimeSource = Source(
    name: "Manhwahentai.me",
    baseUrl: "https://manhwahentai.me",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/manhwahentaime/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
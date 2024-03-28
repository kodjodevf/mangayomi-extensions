import '../../../../../../model/source.dart';

  Source get tankouhentaiSource => _tankouhentaiSource;
            
  Source _tankouhentaiSource = Source(
    name: "Tankou Hentai",
    baseUrl: "https://tankouhentai.com",
    lang: "pt-BR",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/tankouhentai/icon.png",
    dateFormat:"dd 'de' MMMMM 'de' YYYY",
    dateFormatLocale:"pt-br",
  );
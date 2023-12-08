import '../../../../../model/source.dart';

  Source get yugenmangasSource => _yugenmangasSource;
            
  Source _yugenmangasSource = Source(
    name: "YugenMangas",
    baseUrl: "https://yugenmangas.lat",
    lang: "es",
    
    typeSource: "heancms",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/heancms/src/yugenmangas/icon.png",
    dateFormat:"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
    dateFormatLocale:"en",
  );
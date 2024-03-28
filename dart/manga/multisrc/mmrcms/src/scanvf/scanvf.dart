import '../../../../../../model/source.dart';

  Source get scanvfSource => _scanvfSource;
            
  Source _scanvfSource = Source(
    name: "Scan VF",
    baseUrl: "https://www.scan-vf.net",
    lang: "fr",
    
    typeSource: "mmrcms",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mmrcms/src/scanvf/icon.png",
    dateFormat:"d MMM. yyyy",
    dateFormatLocale:"en_us",
  );
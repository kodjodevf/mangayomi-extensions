import '../../../../../model/source.dart';

  Source get scantradvfSource => _scantradvfSource;
            
  Source _scantradvfSource = Source(
    name: "Scantrad-VF",
    baseUrl: "https://scantrad-vf.co",
    lang: "fr",
    
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/manga/multisrc/madara/src/scantradvf/icon.png",
    dateFormat:"d MMMM yyyy",
    dateFormatLocale:"fr",
  );
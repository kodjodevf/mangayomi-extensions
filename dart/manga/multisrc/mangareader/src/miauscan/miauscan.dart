import '../../../../../../model/source.dart';

Source get miauscanSource => _miauscanSource;
Source _miauscanSource = Source(
    name: "Miau Scan",
    baseUrl: "https://lectormiau.com",
    lang: "all",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/miauscan/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es"
  );

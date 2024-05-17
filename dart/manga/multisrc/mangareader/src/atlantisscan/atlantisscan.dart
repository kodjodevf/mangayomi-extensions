import '../../../../../../model/source.dart';

Source get atlantisscanSource => _atlantisscanSource;
Source _atlantisscanSource = Source(
    name: "Atlantis Scan",
    baseUrl: "https://scansatlanticos.com",
    lang: "es",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/atlantisscan/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us"
  );

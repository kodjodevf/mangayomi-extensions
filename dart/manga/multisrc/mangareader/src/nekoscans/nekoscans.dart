import '../../../../../../model/source.dart';

Source get nekoscansSource => _nekoscansSource;
Source _nekoscansSource = Source(
    name: "NekoScans",
    baseUrl: "https://nekoscans.com",
    lang: "es",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/nekoscans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"es"
  );

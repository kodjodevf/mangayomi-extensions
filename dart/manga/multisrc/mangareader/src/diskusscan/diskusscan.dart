import '../../../../../../model/source.dart';

Source get diskusscanSource => _diskusscanSource;
Source _diskusscanSource = Source(
    name: "Diskus Scan",
    baseUrl: "https://diskusscan.com",
    lang: "pt-br",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/diskusscan/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"pt-br"
  );

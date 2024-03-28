import '../../../../../../model/source.dart';

Source get komikstationSource => _komikstationSource;

Source _komikstationSource = Source(
  name: "Komik Station",
  baseUrl: "https://komikstation.co",
  lang: "id",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/komikstation/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "id",
);

import '../../../../../../model/source.dart';

Source get perfscanSource => _perfscanSource;

Source _perfscanSource = Source(
  name: "Perf Scan",
  baseUrl: "https://perf-scan.fr",
  apiUrl: "https://api.perf-scan.fr",
  lang: "fr",
  typeSource: "heancms",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/heancms/src/perfscan/icon.png",
  dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
  dateFormatLocale: "en",
);

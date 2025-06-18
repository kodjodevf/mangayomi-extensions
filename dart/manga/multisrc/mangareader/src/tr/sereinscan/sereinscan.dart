import '../../../../../../../model/source.dart';

Source get sereinscanSource => _sereinscanSource;
Source _sereinscanSource = Source(
  name: "Serein Scan",
  baseUrl: "https://sereinscan.com",
  lang: "tr",
  isNsfw: false,
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/tr/sereinscan/icon.png",
  dateFormat: "MMM d, yyy",
  dateFormatLocale: "tr",
);

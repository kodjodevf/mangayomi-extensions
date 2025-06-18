import '../../../../../../../model/source.dart';

Source get dtupscanSource => _dtupscanSource;
Source _dtupscanSource = Source(
  name: "De Todo Un Poco Scan",
  baseUrl: "https://dtupscan.com",
  lang: "es",
  isNsfw: false,
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/es/dtupscan/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "es",
);

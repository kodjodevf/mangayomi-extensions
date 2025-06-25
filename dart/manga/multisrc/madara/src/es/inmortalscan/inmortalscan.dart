import '../../../../../../../model/source.dart';

Source get inmortalscanSource => _inmortalscanSource;

Source _inmortalscanSource = Source(
  name: "Inmortal Scan",
  baseUrl: "https://scaninmortal.com",
  lang: "es",

  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/es/inmortalscan/icon.png",
  dateFormat: "MMMM d, yyyy",
  dateFormatLocale: "es",
);

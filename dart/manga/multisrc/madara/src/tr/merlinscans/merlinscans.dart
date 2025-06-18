import '../../../../../../../model/source.dart';

Source get merlinscansSource => _merlinscansSource;
Source _merlinscansSource = Source(
  name: "Merlin Scans",
  baseUrl: "https://merlinscans.com",
  lang: "tr",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/dart/manga/multisrc/madara/src/tr/merlinscans/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "tr",
);

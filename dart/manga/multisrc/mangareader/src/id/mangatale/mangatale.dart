import '../../../../../../../model/source.dart';

Source get mangataleSource => _mangataleSource;

Source _mangataleSource = Source(
  name: "MangaTale",
  baseUrl: "https://mangatale.co",
  lang: "id",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/id/mangatale/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "id",
);

import '../../../../model/source.dart';

Source get novelUpdatesSource => _novelUpdatesSource;
const _novelUpdatesVersion = "0.0.1";
const _novelUpdatesSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/novel/src/en/novelupdates.dart";
Source _novelUpdatesSource = Source(
  name: "NovelUpdates",
  baseUrl: "https://www.novelupdates.com",
  lang: "en",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/en/icon.png",
  sourceCodeUrl: _novelUpdatesSourceCodeUrl,
  itemType: ItemType.novel,
  version: _novelUpdatesVersion,
  dateFormat: "MMM dd,yyyy",
  dateFormatLocale: "en",
);

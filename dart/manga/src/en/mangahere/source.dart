import '../../../../../model/source.dart';

Source get mangahereSource => _mangahereSource;
const _mangahereVersion = "0.0.7";
const _mangahereSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/en/mangahere/mangahere.dart";
Source _mangahereSource = Source(
  name: "MangaHere",
  baseUrl: "http://www.mangahere.cc",
  lang: "en",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/en/mangahere/icon.png",
  sourceCodeUrl: _mangahereSourceCodeUrl,
  version: _mangahereVersion,
  dateFormat: "MMM dd,yyyy",
  dateFormatLocale: "en",
);


import '../../../../model/source.dart';

Source get mangahereSource => _mangahereSource;
const mangahereVersion = "0.0.1";
const mangahereSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/src/en/mangahere/mangahere-v$mangahereVersion.dart";
Source _mangahereSource = Source(
  name: "MangaHere",
  baseUrl: "http://www.mangahere.cc",
  lang: "en",
  typeSource: "single",
  iconUrl: '',
  sourceCodeUrl: mangahereSourceCodeUrl,
  version: mangahereVersion,
  dateFormat: "MMM dd,yyyy",
  dateFormatLocale: "en",
);

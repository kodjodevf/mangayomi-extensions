import '../../../model/source.dart';
import '../../../utils/utils.dart';

const nepnepVersion = "0.0.1";
const nepnepSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/nepnep/nepnep-v$nepnepVersion.dart";
const defaultDateFormat = "yyyy-MM-dd HH:mm:ss";
const defaultDateFormatLocale = "en";

List<Source> get nepnepSourcesList => _nepnepSourcesList;
List<Source> _nepnepSourcesList = [
  Source(
    name: "MangaSee",
    baseUrl: "https://mangasee123.com",
    lang: "en",
    typeSource: "nepnep",
    iconUrl: getIconUrl("mangasee", "fr"),
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: nepnepVersion,
    sourceCodeUrl: nepnepSourceCodeUrl,
  ),
  Source(
    name: "MangaLife",
    baseUrl: "https://manga4life.com",
    lang: "en",
    typeSource: "nepnep",
    iconUrl: getIconUrl("mangalife", "id"),
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: nepnepVersion,
    sourceCodeUrl: nepnepSourceCodeUrl,
  ),
];

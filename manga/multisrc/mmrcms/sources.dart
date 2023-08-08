import '../../../model/source.dart';

const mmrcmsVersion = "0.0.11";
const mmrcmsSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mmrcms/mmrcms-v$mmrcmsVersion.dart";
const defaultDateFormat = "d MMM. yyyy";
const defaultDateFormatLocale = "en_US";

List<Source> get mmrcmsSourcesList => _mmrcmsSourcesList;
List<Source> _mmrcmsSourcesList = [
  Source(
    name: "Scan VF",
    baseUrl: "https://www.scan-vf.net",
    lang: "fr",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ),
  Source(
    name: "Komikid",
    baseUrl: "https://www.komikid.com",
    lang: "id",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ),
  Source(
    name: "MangaID",
    baseUrl: "https://mangaid.click",
    lang: "id",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ),
  Source(
    name: "Jpmangas",
    baseUrl: "https://jpmangas.cc",
    lang: "fr",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ),

  Source(
    name: "مانجا اون لاين",
    baseUrl: "https://onma.top",
    lang: "ar",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ),
  Source(
    name: "Read Comics Online",
    baseUrl: "https://readcomicsonline.ru",
    lang: "en",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ), 
  Source(
    name: "Lelscan-VF",
    baseUrl: "https://www.lelscanvf.cc/",
    lang: "fr",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ),

  Source(
    name: "Manga-FR",
    baseUrl: "https://manga-fr.me",
    lang: "fr",
    typeSource: "mmrcms",
    iconUrl: '',
    dateFormat: defaultDateFormat,
    dateFormatLocale: defaultDateFormatLocale,
    version: mmrcmsVersion,
    sourceCodeUrl: mmrcmsSourceCodeUrl,
  ),
];

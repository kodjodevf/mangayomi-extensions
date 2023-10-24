import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

const comickVersion = "0.0.3";
const comickSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/src/all/comick/comick-v$comickVersion.dart";

String iconUrl = getIconUrl("comickfun", "all");
const apiUrl = 'https://api.comick.fun';
const baseUrl = 'https://comick.app';
const isNsfw = true;

List<String> languages = [
  "all",
  "en",
  "pt-br",
  "ru",
  "fr",
  "es-419",
  "pl",
  "tr",
  "it",
  "es",
  "id",
  "hu",
  "vi",
  "zh-hk",
  "ar",
  "de",
  "zh",
  "ca",
  "bg",
  "th",
  "fa",
  "uk",
  "mn",
  "ro",
  "he",
  "ms",
  "tl",
  "ja",
  "hi",
  "my",
  "ko",
  "cs",
  "pt",
  "nl",
  "sv",
  "bn",
  "no",
  "lt",
  "el",
  "sr",
  "da",
];

List<Source> get comickSourcesList => _comickSourcesList;
List<Source> _comickSourcesList = languages
    .map((e) => Source(
        name: 'Comick',
        apiUrl: apiUrl,
        baseUrl: baseUrl,
        lang: e,
        typeSource: "comick",
        iconUrl: iconUrl,
        dateFormat: "yyyy-MM-dd'T'HH:mm:ss'Z'",
        isNsfw: isNsfw,
        dateFormatLocale: "en",
        version: comickVersion,
        sourceCodeUrl: comickSourceCodeUrl))
    .toList();

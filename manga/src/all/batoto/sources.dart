import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

const batotoVersion = "0.0.2";
const batotoSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/src/all/batoto/batoto-v$batotoVersion.dart";

String _iconUrl = getIconUrl("batoto", "all");
const baseUrl = 'https://bato.to';
const isNsfw = true;

List<String> languages = [
  "all",
  "en",
  "ar",
  "bg",
  "zh",
  "cs",
  "da",
  "nl",
  "fil",
  "fi",
  "fr",
  "de",
  "el",
  "he",
  "hi",
  "hu",
  "id",
  "it",
  "ja",
  "ko",
  "ms",
  "pl",
  "pt",
  "pt-br",
  "ro",
  "ru",
  "es",
  "es-419",
  "sv",
  "th",
  "tr",
  "uk",
  "vi",
  "af",
  "sq",
  "am",
  "hy",
  "az",
  "be",
  "bn",
  "bs",
  "my",
  "km",
  "ca",
  "ceb",
  "zh-hk",
  "zh-tw",
  "hr",
  "en-us",
  "eo",
  "et",
  "fo",
  "ka",
  "gn",
  "gu",
  "ht",
  "ha",
  "is",
  "ig",
  "ga",
  "jv",
  "kn",
  "kk",
  "ku",
  "ky",
  "lo",
  "lv",
  "lt",
  "lb",
  "mk",
  "mg",
  "ml",
  "mt",
  "mi",
  "mr",
  "mn",
  "ne",
  "no",
  "ny",
  "ps",
  "fa",
  "rm",
  "sm",
  "sr",
  "sh",
  "st",
  "sn",
  "sd",
  "si",
  "sk",
  "sl",
  "so",
  "sw",
  "tg",
  "ta",
  "ti",
  "to",
  "tk",
  "ur",
  "uz",
  "yo",
  "zu",
  "eu",
  "pt-PT",
];

List<Source> get batotoSourcesList => _batotoSourcesList;
List<Source> _batotoSourcesList = languages
    .map((e) => Source(
        name: 'Bato.to',
        baseUrl: baseUrl,
        lang: e,
        typeSource: "bato.to",
        iconUrl: _iconUrl,
        dateFormat: "MMM dd,yyyy",
        isNsfw: isNsfw,
        dateFormatLocale: "en",
        version: batotoVersion,
        appMinVerReq: "0.0.43",
        sourceCodeUrl: batotoSourceCodeUrl))
    .toList();

import '../../../../model/source.dart';
import '../../../../utils/utils.dart';

const apiUrl = 'https://api.mangadex.org';
const baseUrl = 'https://mangadex.org';
const isNsfw = true;
const mangadexVersion = "0.0.35";
const mangadexSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/src/all/mangadex/mangadex-v$mangadexVersion.dart";
String _iconUrl = getIconUrl("mangadex", "all");

final languages = [
  "ar",
  "bn",
  "bg",
  "my",
  "ca",
  "zh",
  "zh-hk",
  "cs",
  "da",
  "nl",
  "en",
  "tl",
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
  "kk",
  "ko",
  "la",
  "lt",
  "ms",
  "mn",
  "ne",
  "no",
  "fa",
  "pl",
  "pt-br",
  "pt",
  "ro",
  "ru",
  "sh",
  "es-419",
  "es",
  "sv",
  "ta",
  "th",
  "tr",
  "uk",
  "vi"
];

List<Source> get mangaDexSourcesList => _mangaDexSourcesList;
List<Source> _mangaDexSourcesList = languages
    .map((e) => Source(
        name: 'MangaDex',
        apiUrl: apiUrl,
        baseUrl: baseUrl,
        lang: e,
        typeSource: "mangadex",
        iconUrl: _iconUrl,
        dateFormat: "yyyy-MM-dd'T'HH:mm:ss+SSS",
        isNsfw: isNsfw,
        dateFormatLocale: 'en_Us',
        version: mangadexVersion,
        sourceCodeUrl: mangadexSourceCodeUrl))
    .toList();

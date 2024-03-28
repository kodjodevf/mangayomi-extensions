import '../../../../../model/source.dart';

const _apiUrl = 'https://api.mangadex.org';
const _baseUrl = 'https://mangadex.org';
const _isNsfw = true;
const _mangadexVersion = "0.0.75";
const _mangadexSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/all/mangadex/mangadex.dart";
String _iconUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/all/mangadex/icon.png";

final _languages = [
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
List<Source> _mangaDexSourcesList = _languages
    .map((e) => Source(
        name: 'MangaDex',
        apiUrl: _apiUrl,
        baseUrl: _baseUrl,
        lang: e,
        typeSource: "mangadex",
        iconUrl: _iconUrl,
        dateFormat: "yyyy-MM-dd'T'HH:mm:ss+SSS",
        isNsfw: _isNsfw,
        dateFormatLocale: 'en_Us',
        version: _mangadexVersion,
        sourceCodeUrl: _mangadexSourceCodeUrl))
    .toList();

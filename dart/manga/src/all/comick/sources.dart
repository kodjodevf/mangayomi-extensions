import '../../../../../model/source.dart';

const _comickVersion = "0.0.7";
const _comickSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/all/comick/comick.dart";

String _iconUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/src/all/comick/icon.png";
const _apiUrl = 'https://api.comick.fun';
const _baseUrl = 'https://comick.app';
const _isNsfw = true;

List<String> _languages = [
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
List<Source> _comickSourcesList = _languages
    .map((e) => Source(
        name: 'Comick',
        apiUrl: _apiUrl,
        baseUrl: _baseUrl,
        lang: e,
        typeSource: "comick",
        iconUrl: _iconUrl,
        dateFormat: "yyyy-MM-dd'T'HH:mm:ss'Z'",
        isNsfw: _isNsfw,
        dateFormatLocale: "en",
        version: _comickVersion,
        sourceCodeUrl: _comickSourceCodeUrl))
    .toList();

import '../../../model/source.dart';
import '../../../utils/utils.dart';

const heancmsVersion = "0.0.11";
const heancmsSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/heancms/heancms-v$heancmsVersion.dart";
const defaultDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ";
const defaultDateFormatLocale = "en";
List<Source> get heanCmsSourcesList => _heanCmsSourcesList;
List<Source> _heanCmsSourcesList = [
  Source(
      name: "YugenMangas",
      baseUrl: "https://yugenmangas.net",
      apiUrl: "https://api.yugenmangas.net",
      lang: "es",
      typeSource: "heancms",
      isNsfw: true,
      iconUrl: getIconUrl("yugenmangas", "es"),
      sourceCodeUrl: heancmsSourceCodeUrl,
      version: heancmsVersion,
      dateFormat: defaultDateFormat,
      dateFormatLocale: defaultDateFormatLocale),
  Source(
      name: "OmegaScans",
      baseUrl: "https://omegascans.org",
      apiUrl: "https://api.omegascans.org",
      lang: "en",
      typeSource: "heancms",
      isNsfw: true,
      iconUrl: getIconUrl("omegascans", "en"),
      sourceCodeUrl: heancmsSourceCodeUrl,
      version: heancmsVersion,
      dateFormat: defaultDateFormat,
      dateFormatLocale: defaultDateFormatLocale),
];

import '../../../model/source.dart';
import '../../../utils/utils.dart';

const heancmsVersion = "0.0.2";
const heancmsSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/heancms/heancms-v$heancmsVersion.dart";
const defaultDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ";
const defaultDateFormatLocale = "en";
List<Source> get heanCmsSourcesList => _heanCmsSourcesList;
List<Source> _heanCmsSourcesList = [
  Source(
      name: "YugenMangas",
      baseUrl: "https://yugenmangas.lat",
      apiUrl: "https://api.yugenmangas.lat",
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
  Source(
      name: "Reaper Scans",
      baseUrl: "https://reaperscans.net",
      apiUrl: "https://api.reaperscans.net",
      lang: "pt-BR",
      typeSource: "heancms",
      isNsfw: true,
      iconUrl: getIconUrl("reaperscans", "pt-BR"),
      sourceCodeUrl: heancmsSourceCodeUrl,
      version: heancmsVersion,
      dateFormat: defaultDateFormat,
      dateFormatLocale: defaultDateFormatLocale),
  Source(
      name: "Perf Scan",
      baseUrl: "https://perf-scan.fr",
      apiUrl: "https://api.perf-scan.fr",
      lang: "fr",
      typeSource: "heancms",
      isNsfw: true,
      iconUrl: getIconUrl("perfscan", "fr"),
      sourceCodeUrl: heancmsSourceCodeUrl,
      version: heancmsVersion,
      dateFormat: defaultDateFormat,
      dateFormatLocale: defaultDateFormatLocale),
  Source(
      name: "Glorious Scan",
      baseUrl: "https://gloriousscan.com",
      apiUrl: "https://api.gloriousscan.com",
      lang: "pt-BR",
      typeSource: "heancms",
      isNsfw: true,
      iconUrl: getIconUrl("gloriousscan", "pt-BR"),
      sourceCodeUrl: heancmsSourceCodeUrl,
      version: heancmsVersion,
      dateFormat: defaultDateFormat,
      dateFormatLocale: defaultDateFormatLocale),
];

import '../../../../../../../model/source.dart';

Source get mhscansSource => _mhscansSource;
Source _mhscansSource = Source(
  name: "MHScans",
  baseUrl: "https://twobluescans.com",
  lang: "es",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/dart/manga/multisrc/madara/src/es/mhscans/icon.png",
  dateFormat: "dd 'de' MMMM 'de' yyyy",
  dateFormatLocale: "es",
);

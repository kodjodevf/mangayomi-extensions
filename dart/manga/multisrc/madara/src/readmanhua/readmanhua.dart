import '../../../../../../model/source.dart';

Source get readmanhuaSource => _readmanhuaSource;
Source _readmanhuaSource = Source(
  name: "ReadManhua",
  baseUrl: "https://readmanhua.net",
  lang: "en",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/dart/manga/multisrc/madara/src/readmanhua/icon.png",
  dateFormat: "dd MMM yyyy",
  dateFormatLocale: "en_us",
);

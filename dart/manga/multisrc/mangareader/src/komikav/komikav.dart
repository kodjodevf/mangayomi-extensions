import '../../../../../../model/source.dart';

Source get komikavSource => _komikavSource;
Source _komikavSource = Source(
    name: "APKOMIK",
    baseUrl: "https://apkomik.cc",
    lang: "id",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/komikav/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"id"
  );

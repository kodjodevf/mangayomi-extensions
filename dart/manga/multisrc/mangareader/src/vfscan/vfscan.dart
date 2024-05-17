import '../../../../../../model/source.dart';

Source get vfscanSource => _vfscanSource;
Source _vfscanSource = Source(
    name: "VF Scan",
    baseUrl: "https://www.vfscan.cc",
    lang: "fr",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/vfscan/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"fr"
  );

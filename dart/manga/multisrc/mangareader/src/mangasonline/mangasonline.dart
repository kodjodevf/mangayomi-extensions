import '../../../../../../model/source.dart';

Source get mangasonlineSource => _mangasonlineSource;
Source _mangasonlineSource = Source(
    name: "Mangás Online",
    baseUrl: "https://mangasonline.cc",
    lang: "pt-br",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangasonline/icon.png",
    dateFormat:"MMMMM dd, yyyy",
    dateFormatLocale:"pt-br"
  );

import '../../../../../../model/source.dart';

Source get mangkomikSource => _mangkomikSource;
Source _mangkomikSource = Source(
    name: "Siren Komik",
    baseUrl: "https://sirenkomik.my.id",
    lang: "id",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangkomik/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"id"
  );

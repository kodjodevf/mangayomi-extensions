import '../../../../../../model/source.dart';

Source get mangamoonSource => _mangamoonSource;
Source _mangamoonSource = Source(
    name: "Manga-Moon",
    baseUrl: "https://manga-moons.net",
    lang: "th",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangamoon/icon.png",
    dateFormat:"MMMM d, yyyy",
    dateFormatLocale:"th"
  );

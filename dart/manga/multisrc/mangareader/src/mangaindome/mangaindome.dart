import '../../../../../../model/source.dart';

Source get mangaindomeSource => _mangaindomeSource;

Source _mangaindomeSource = Source(
  name: "Manga Indo.me",
  baseUrl: "https://mangaindo.me",
  lang: "id",
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangaindome/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "en_us",
);

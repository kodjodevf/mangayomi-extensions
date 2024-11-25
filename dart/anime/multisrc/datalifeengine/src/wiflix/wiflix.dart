import '../../../../../../model/source.dart';

Source get wiflixSource => _wiflixSource;

Source _wiflixSource = Source(
  name: "Wiflix",
  baseUrl: "https://wiflix.bot",
  lang: "fr",
  typeSource: "datalifeengine",
  itemType: ItemType.anime,
  iconUrl:
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/multisrc/datalifeengine/src/wiflix/icon.png",
);

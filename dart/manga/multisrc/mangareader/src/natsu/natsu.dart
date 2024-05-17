import '../../../../../../model/source.dart';

Source get natsuSource => _natsuSource;
Source _natsuSource = Source(
    name: "Natsu",
    baseUrl: "https://natsu.id",
    lang: "id",
    isNsfw:false,
    typeSource: "mangareader",
    iconUrl: "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/natsu/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"id"
  );

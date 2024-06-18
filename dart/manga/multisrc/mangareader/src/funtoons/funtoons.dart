import '../../../../../../model/source.dart';

Source get funtoonsSource => _funtoonsSource;
Source _funtoonsSource = Source(
    name: "FunToons",
    baseUrl: "https://funtoons.online",
    lang: "th",
    isNsfw: true,
    typeSource: "mangareader",
    iconUrl:
        "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/mangareader/src/funtoons/icon.png",
    dateFormat: "MMMM dd, yyyy",
    dateFormatLocale: "th",
    hasCloudflare: true);

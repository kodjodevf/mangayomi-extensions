import '../../../../../../model/source.dart';

  Source get adultwebtoonSource => _adultwebtoonSource;
            
  Source _adultwebtoonSource = Source(
    name: "Adult Webtoon",
    baseUrl: "https://adultwebtoon.com",
    lang: "en",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/manga/multisrc/madara/src/adultwebtoon/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );
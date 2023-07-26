class Source {
  String? id;
  String? name;

  String? baseUrl;

  String? lang;

  bool? isNsfw;

  String? sourceCodeUrl;

  String? typeSource;

  String? iconUrl;

  bool? hasCloudflare;

  String? dateFormat;

  String? dateFormatLocale;

  String? apiUrl;

  String? version;

  bool? isManga;
  
  Source({
    this.id = null,
    this.name = "",
    this.baseUrl = "",
    this.lang = "",
    this.typeSource = "",
    this.iconUrl = "",
    this.dateFormat,
    this.dateFormatLocale,
    this.isNsfw = false,
    this.hasCloudflare = false,
    this.sourceCodeUrl = "",
    this.apiUrl = "",
    this.version = "",
    this.isManga = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id ?? 'mangayomi-$lang.$name'.hashCode,
      'baseUrl': baseUrl,
      "lang": lang,
      "typeSource": typeSource,
      "iconUrl": iconUrl,
      "dateFormat": dateFormat,
      "dateFormatLocale": dateFormatLocale,
      "isNsfw": isNsfw,
      "hasCloudflare": hasCloudflare,
      "sourceCodeUrl": sourceCodeUrl,
      "apiUrl": apiUrl,
      "version": version,
      "isManga": isManga,
    };
  }
}

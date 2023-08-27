String getIconUrl(String name, String lang) {
  return name.isEmpty
      ? ""
      : 'https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/icon/mangayomi-$lang-$name.png';
}

String getIconUrl(String name, String lang) {
  return name.isEmpty
      ? ""
      : 'https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/icons/mangayomi-$lang-$name.png';
}

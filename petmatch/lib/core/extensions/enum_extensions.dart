extension EnumNameExtension on Object {
  String get enumName {
    final text = toString();
    final idx = text.lastIndexOf('.');
    return idx < 0 ? text : text.substring(idx + 1);
  }
}

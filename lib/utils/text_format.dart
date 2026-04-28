class TextFormat {
  static getTextFormt(String key) {
    if (key.isEmpty) return '';
    final result = key.replaceAllMapped(
      RegExp(r'(?<!^)(?=[A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}

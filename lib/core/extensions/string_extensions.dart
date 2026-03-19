extension StringExtensions on String {
  /// Capitalize the first letter of the string.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncate string to [maxLength] characters, appending [ellipsis] if cut.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Returns true if the string is a valid positive number.
  bool get isNumeric => double.tryParse(this) != null;

  /// Removes all whitespace from the string.
  String get removeWhitespace => replaceAll(' ', '');

  /// Converts to Vietnamese title case (capitalizes each word).
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}

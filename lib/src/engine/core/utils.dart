extension MapExtensions<K, V> on Map<K, V> {
  Iterable<(K, V)> get pairs =>
      entries.map((entry) => (entry.key, entry.value));
}

extension IntExtensions on int {
  /// Converts the number to a string, with separating commas for thousands,
  /// millions, etc.
  ///
  /// If [w] is given, pads the result on the left to at least that many
  /// characters.
  String fmt({int? w}) {
    var result = toString();

    // TODO: Handle negative numbers.

    if (this > 999999999) {
      result =
          "${result.substring(0, result.length - 9)},"
          "${result.substring(result.length - 9)}";
    }

    if (this > 999999) {
      result =
          "${result.substring(0, result.length - 6)},"
          "${result.substring(result.length - 6)}";
    }

    if (this > 999) {
      result =
          "${result.substring(0, result.length - 3)},"
          "${result.substring(result.length - 3)}";
    }

    return result.padLeft(w ?? 0);
  }
}

extension NumExtensions on num {
  /// Converts the number to a string.
  ///
  /// If [d] is given, includes that many digits of precision. If [w] is given,
  /// pads the result on the left to at least that many characters.
  String fmt({int? w, int? d}) =>
      (d != null ? toStringAsFixed(d) : toString()).padLeft(w ?? 0);

  /// Converts the number to a percentage string where a value of 1 is 100%.
  ///
  /// If [d] is given, includes that many digits of precision. If [w] is given,
  /// pads the result on the left to at least that many characters.
  String fmtPercent({int? w, int? d}) =>
      '${(this * 100).toStringAsFixed(d ?? 0)}%'.padLeft(w ?? 0);
}

extension ObjectExtensions on Object {
  /// Converts the object to a string and pads on the right to at least [w]
  /// characters if given.
  String fmt({int? w}) => toString().padRight(w ?? 0);
}

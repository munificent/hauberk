extension IntExtensions on int {
  static final RegExp _groups = RegExp(r"^(\d{1,3})((\d{3})+)$");

  /// Converts the number to a string, with separating commas for thousands,
  /// millions, etc.
  ///
  /// If [w] is given, pads the result on the left to at least that many
  /// characters.
  String fmt({int? w, bool sign = false}) {
    var result = abs().toString();

    // Separate digit groups with commas.
    if (_groups.firstMatch(result) case var match?) {
      var rest = match[2]!;
      var sections = [
        match[1]!,
        for (var i = 0; i < rest.length ~/ 3; i++)
          rest.substring(i * 3, i * 3 + 3),
      ];

      result = sections.join(",");
    }

    if (this < 0) {
      result = "-$result";
    } else if (this > 0 && sign) {
      result = "+$result";
    }

    return result.padLeft(w ?? 0);
  }
}

extension MapExtensions<K, V> on Map<K, V> {
  Iterable<(K, V)> get pairs =>
      entries.map((entry) => (entry.key, entry.value));
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

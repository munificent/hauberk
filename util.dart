library util;

import 'dart:math';

part 'util/array2d.dart';
part 'util/chain.dart';
part 'util/direction.dart';
part 'util/rect.dart';
part 'util/rng.dart';
part 'util/vec.dart';

// TODO(bob): Where should this go?
sign(num n) {
  return (n < 0) ? -1 : (n > 0) ? 1 : 0;
}

num clamp(num min, num value, num max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

String padLeft(String text, int length) {
  final result = new StringBuffer();
  for (var i = length - text.length; i >= 0; i--) {
    result.add(' ');
  }
  result.add(text);
  return result.toString();
}

String padRight(String text, int length, [String padChar = ' ']) {
  final result = new StringBuffer();
  result.add(text);
  for (var i = length - text.length; i >= 0; i--) {
    result.add(padChar);
  }
  return result.toString();
}

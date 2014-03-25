library dngn.util;

export 'util/array2d.dart';
export 'util/chain.dart';
export 'util/direction.dart';
export 'util/rect.dart';
export 'util/rng.dart';
export 'util/vec.dart';

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
    result.write(' ');
  }
  result.write(text);
  return result.toString();
}

String padRight(String text, int length, [String padChar = ' ']) {
  final result = new StringBuffer();
  result.write(text);
  for (var i = length - text.length; i >= 0; i--) {
    result.write(padChar);
  }
  return result.toString();
}

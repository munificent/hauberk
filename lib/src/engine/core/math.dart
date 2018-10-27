/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
double lerpDouble(num value, num min, num max, double outMin, double outMax) {
  assert(min < max);

  if (value <= min) return outMin;
  if (value >= max) return outMax;

  var t = (value - min) / (max - min);
  return outMin + t * (outMax - outMin);
}

/// Remaps [value] within the range [min]-[max] to the output range
/// [outMin]-[outMax].
int lerpInt(int value, int min, int max, int outMin, int outMax) =>
    lerpDouble(value, min, max, outMin.toDouble(), outMax.toDouble()).round();

/// Produces a psuedo-random 32-bit unsigned integer for the point at [x, y]
/// using [seed].
///
/// This can be used to associate random values with tiles without having to
/// store them.
int hashPoint(int x, int y, [int seed]) {
  seed ??= 0;

  // From: https://stackoverflow.com/a/12996028/9457
  hashInt(int n) {
    n = (((n >> 16) ^ n) * 0x45d9f3b) & 0xffffffff;
    n = (((n >> 16) ^ n) * 0x45d9f3b) & 0xffffffff;
    n = (n >> 16) ^ n;
    return n;
  }

  return hashInt(hashInt(hashInt(seed) + x) + y) & 0xffffffff;
}

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

// TODO: Not currently used. Delete?
/// Finds the quadratic curve that goes through [x0],[y0], [x1],[y1], and
/// [x2],[y2]. Then calculates the y position at [x].
double quadraticInterpolate(num x,
    {num x0, num y0, num x1, num y1, num x2, num y2}) {
  // From: http://mathonline.wikidot.com/deleted:quadratic-polynomial-interpolation
  var a = ((x - x1) * (x - x2)) / ((x0 - x1) * (x0 - x2));
  var b = ((x - x0) * (x - x2)) / ((x1 - x0) * (x1 - x2));
  var c = ((x - x0) * (x - x1)) / ((x2 - x0) * (x2 - x1));

  return y0 * a + y1 * b + y2 * c;
}

/// Produces a psuedo-random 32-bit unsigned integer for the point at [x, y]
/// using [seed].
///
/// This can be used to associate random values with tiles without having to
/// store them.
int hashPoint(int x, int y, [int seed]) {
  seed ??= 0;

  // From: https://stackoverflow.com/a/12996028/9457
  int hashInt(int n) {
    n = (((n >> 16) ^ n) * 0x45d9f3b) & 0xffffffff;
    n = (((n >> 16) ^ n) * 0x45d9f3b) & 0xffffffff;
    n = (n >> 16) ^ n;
    return n;
  }

  return hashInt(hashInt(hashInt(seed) + x) + y) & 0xffffffff;
}

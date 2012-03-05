
// TODO(bob): Just use a final static when those can have non-const
// initializers.
/// A singleton instance of Rng globally available.
Rng get rng() {
  if (_rng == null) _rng = new Rng(new Date.now().value);
  return _rng;
}

Rng _rng;


/// The Random Number God: deliverer of good and ill fortune alike.
/// Implemented using a [Mersenne Twister]. Note: I just ported it straight from
/// wikipedia, and have only loosely tested it.
///
/// [Mersenne Twister]: http://en.wikipedia.org/wiki/Mersenne_Twister
class Rng {
  final List<int> _pool;
  int _index = 0;

  /// The number of elements in the state pool.
  static final _SIZE = 624;

  Rng(int seed) : _pool = new List<int>(_SIZE) {
    _pool[0] = seed;
    for (var i = 1; i < _SIZE; i++) {
      final a = (_pool[i - 1]) >> 30;
      final b = 0x6c078965 * (_pool[i - 1] ^ a) + i;
      _pool[i] = b & 0xffffffff;
    }
  }

  /// Gets a random int within a given range. If [max] is given, then it is
  /// in the range `[minOrMax, max)`. Otherwise, it is `[0, minOrMax)`. In
  /// other words, `next(3)` returns a `0`, `1`, or `2`, and `next(2, 5)`
  /// returns `2`, `3`, or `4`.
  int next(int minOrMax, [int max]) {
    if (max == null) {
      max = minOrMax;
      minOrMax = 0;
    }

    return ((nextInt() / 0xffffffff) * (max - minOrMax) + minOrMax).toInt();
  }

  /// Gets a random number in the range `[0-2^32)`.
  int nextInt() {
    if (_index == 0) _fillPool();

    var y = _pool[_index];
    y ^= y >> 11;
    y ^= (y << 7) & 0x9d2c5680;
    y ^= (y << 15) & 0xefc60000;
    y ^= y >> 18;

    _index = (_index + 1) % _SIZE;
    return y;
  }

  /// Gets a random item from the given list.
  item(List items) => items[next(items.length)];

  /// Gets a random [Vec] within the given [Rect] (half-inclusive).
  Vec vecInRect(Rect rect) {
    return new Vec(next(rect.left, rect.right), next(rect.top, rect.bottom));
  }

  void _fillPool() {
    for (var i = 0; i < _SIZE; i++) {
      final a = _pool[(i + 1) % _SIZE] & 0x7fffffff;
      final b = (_pool[i] & 0x80000000) >> 31;
      final y = b + a;
      _pool[i] = _pool[(i + 397) % _SIZE] ^ (y << 1);
      if (y % 2 != 0) _pool[i] ^= 0x9908b0df;
    }
  }
}
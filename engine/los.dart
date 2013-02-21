part of engine;

/// Line-of-sight object for tracing a straight line from a [start] to [end]
/// and determining which intermediate tiles are touched.
class Los implements Iterable<Vec> {
  final Vec first;
  final Vec last;

  Los(this.first, this.last);

  Iterator<Vec> get iterator => new LosIterator(first, last);

  int get length {
    throw new UnsupportedError("LOS iteration is unbounded.");
  }

  // TODO(bob): Use a mixin when available.
  bool get isEmpty => IterableMixinWorkaround.isEmpty(this);
  Vec get single => IterableMixinWorkaround.single(this);
  Iterable<Vec> map(f(Vec element)) => IterableMixinWorkaround.map(this, f);
  // TODO(bob): Remove when removed from Iterable.
  Iterable<Vec> mappedBy(f(Vec element)) => IterableMixinWorkaround.map(this, f);
  Iterable<Vec> where(bool test(Vec element)) => IterableMixinWorkaround.where(this, test);
  Iterable expand(f(Vec element)) => IterableMixinWorkaround.expand(this, f);
  bool contains(Vec element) => IterableMixinWorkaround.contains(this, element);
  void forEach(void f(Vec o)) => IterableMixinWorkaround.forEach(this, f);
  bool any(bool f(Vec o)) => IterableMixinWorkaround.any(this, f);
  bool every(bool f(Vec o)) => IterableMixinWorkaround.every(this, f);
  reduce(seed, f(accumulator, Vec o)) => IterableMixinWorkaround.reduce(this, seed, f);
  String join([String separator]) => IterableMixinWorkaround.join(this, separator);
  List<Vec> toList() => new List.from(this);
  Set<Vec> toSet() => new Set.from(this);
  Vec min([int compare(Vec a, Vec b)]) => IterableMixinWorkaround.min(this, compare);
  Vec max([int compare(Vec a, Vec b)]) => IterableMixinWorkaround.max(this, compare);
  Iterable<Vec> take(int n) {
    throw new UnimplementedError();
  }
  Iterable<Vec> takeWhile(bool test(Vec value)) => IterableMixinWorkaround.takeWhile(this, test);
  Iterable<Vec> skip(int n) {
    throw new UnimplementedError();
  }
  Iterable<Vec> skipWhile(bool test(Vec value)) => IterableMixinWorkaround.skipWhile(this, test);
  Vec firstMatching(bool test(Vec value), {Vec orElse()}) => IterableMixinWorkaround.firstMatching(this, test, orElse);
  Vec lastMatching(bool test(Vec value), {Vec orElse()}) => IterableMixinWorkaround.lastMatching(this, test, orElse);
  Vec singleMatching(bool test(Vec value)) => IterableMixinWorkaround.singleMatching(this, test);
  Vec elementAt(int index) => IterableMixinWorkaround.elementAt(this, index);
}

class LosIterator implements Iterator<Vec> {
  final Vec start;
  final Vec end;
  Vec current;
  int error;
  int primary;
  int secondary;
  Vec primaryIncrement;
  Vec secondaryIncrement;

  LosIterator(this.start, this.end) {
    var delta = end - start;

    // Figure which octant the line is in and increment appropriately.
    primaryIncrement = new Vec(sign(delta.x), 0);
    secondaryIncrement = new Vec(0, sign(delta.y));

    // Discard the signs now that they are accounted for.
    delta = delta.abs();

    // Assume moving horizontally each step.
    primary = delta.x;
    secondary = delta.y;

    // Swap the order if the y magnitude is greater.
    if (delta.y > delta.x) {
      var temp = primary;
      primary = secondary;
      secondary = temp;

      temp = primaryIncrement;
      primaryIncrement = secondaryIncrement;
      secondaryIncrement = temp;
    }

    current = start;
    error = 0;
  }

  /// Always returns `true` to allow a line to overshoot the end point. Make
  /// sure you terminate iteration yourself.
  bool moveNext() {
    current += primaryIncrement;

    // See if we need to step in the secondary direction.
    error += secondary;
    if (error * 2 >= primary) {
      current += secondaryIncrement;
      error -= primary;
    }

    return true;
  }
}

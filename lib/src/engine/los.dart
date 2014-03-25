library dngn.engine.los;

import 'dart:collection';

import '../util.dart';

/// Line-of-sight object for tracing a straight line from a [start] to [end]
/// and determining which intermediate tiles are touched.
class Los extends IterableBase<Vec> {
  final Vec first;
  final Vec last;

  Los(this.first, this.last);

  Iterator<Vec> get iterator => new LosIterator(first, last);

  int get length {
    throw new UnsupportedError("LOS iteration is unbounded.");
  }
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

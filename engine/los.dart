/// Line-of-sight object for tracing a straight line from a [start] to [end]
/// and determining which intermediate tiles are touched.
class Los implements Iterable<Vec> {
  final Vec start;
  final Vec end;

  Los(this.start, this.end);

  Iterator<Vec> iterator() => new LosIterator(start, end);
}

class LosIterator implements Iterator<Vec> {
  final Vec start;
  final Vec end;
  Vec pos;
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

    pos = start;
    error = 0;
  }

  bool hasNext() => pos != end;

  Vec next() {
    // Move it first, gets it off the entity in the first step.
    pos += primaryIncrement;

    // See if we need to step in the secondary direction.
    error += secondary;
    if (error * 2 >= primary) {
      pos += secondaryIncrement;
      error -= primary;
    }

    return pos;
  }
}

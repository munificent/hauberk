import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

import 'architect.dart';

/// Uses a cellular automata to carve out rounded open cavernous areas.
class Cavern extends Architecture {
  // TODO: Fields to tune density distribution, thresholds, and number of
  // rounds of smoothing.

  Iterable<String> build() sync* {
    // True is wall, false is floor, null is untouchable tiles that belong to
    // other architectures.
    var cells1 = Array2D<bool>(width, height);
    var cells2 = Array2D<bool>(width, height);

    // TODO: Diagonals too?
    // TODO: Radial from center?
    // TODO: If this is the last architecture placed, it should fill the whole
    // area.
    var directions = Direction.cardinal.toList();
    directions.add(Direction.none);

    var region = rng.item(directions);
    print(region);

    for (var pos in cells1.bounds) {
      if (!canCarve(pos)) continue;
      cells1[pos] = rng.float(1.0) < _density(region, pos);
    }

    for (var i = 0; i < 5; i++) {
      for (var pos in cells1.bounds) {
        // Don't touch unavailable cells.
        if (cells1[pos] == null) continue;

        var walls = 0;
        for (var dir in Direction.all) {
          var here = pos + dir;
          if (!cells1.bounds.contains(here) || cells1[here] != false) walls++;
        }

        if (cells1[pos]) {
          // Survival threshold.
          cells2[pos] = walls >= 3;
        } else {
          // Birth threshold.
          cells2[pos] = walls >= 5;
        }
      }

      var temp = cells1;
      cells1 = cells2;
      cells2 = temp;
      yield "Round";
    }

    for (var pos in cells1.bounds) {
      if (cells1[pos] == false) carve(pos.x, pos.y);
    }
  }

  double _density(Direction region, Vec pos) {
    // TODO: Vary density randomly some.
    const min = 0.3;
    const max = 0.7;

    switch (region) {
      case Direction.none:
        return 0.45;
      case Direction.n:
        return lerpDouble(pos.y, 0, height, min, max);
      case Direction.s:
        return lerpDouble(pos.y, 0, height, max, min);
      case Direction.e:
        return lerpDouble(pos.x, 0, height, min, max);
      case Direction.w:
        return lerpDouble(pos.x, 0, height, max, min);
    }

    throw "unreachable";
  }
}

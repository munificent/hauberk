import 'dart:math' as math;

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

    for (var pos in cells1.bounds) {
      if (!canCarve(pos)) continue;
      cells1[pos] = rng.float(1.0) < _density(region, pos);
    }

    for (var i = 0; i < 4; i++) {
      for (var pos in cells1.bounds) {
        // Don't touch unavailable cells.
        if (cells1[pos] == null) continue;

        var walls = 0;
        for (var here in pos.neighbors) {
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

  double _density(Region region, Vec pos) {
    // TODO: Vary density randomly some.
    const min = 0.3;
    const max = 0.7;

    switch (region) {
      case Region.everywhere:
        return 0.45;
      case Region.n:
        return lerpDouble(pos.y, 0, height, min, max);
      case Region.ne:
        var distance = math.max(width - pos.x - 1, pos.y);
        var range = math.min(width, height);
        return lerpDouble(distance, 0, range, min, max);
      case Region.e:
        return lerpDouble(pos.x, 0, width, min, max);
      case Region.se:
        var distance = math.max(width - pos.x - 1, height - pos.y - 1);
        var range = math.min(width, height);
        return lerpDouble(distance, 0, range, min, max);
      case Region.s:
        return lerpDouble(pos.y, 0, height, max, min);
      case Region.sw:
        var distance = math.max(pos.x, height - pos.y - 1);
        var range = math.min(width, height);
        return lerpDouble(distance, 0, range, min, max);
      case Region.w:
        return lerpDouble(pos.x, 0, width, max, min);
      case Region.nw:
        var distance = math.max(pos.x, pos.y);
        var range = math.min(width, height);
        return lerpDouble(distance, 0, range, min, max);
    }

    throw "unreachable";
  }
}

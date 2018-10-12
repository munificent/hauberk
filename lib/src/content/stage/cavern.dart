import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

import '../tiles.dart';
import 'architecture.dart';

/// Uses a cellular automata to carve out rounded open cavernous areas.
class Cavern extends Architecture {
  // TODO: Fields to tune density distribution, thresholds, and number of
  // rounds of smoothing.

  Iterable<String> build() sync* {
    var cells1 = Array2D<bool>(stage.width - 2, stage.height - 2);
    var cells2 = Array2D<bool>(stage.width - 2, stage.height - 2);

    for (var pos in cells1.bounds) {
      ;
      var distance = (pos - cells1.bounds.center).length;
      var density =
          lerpDouble(distance, 0, cells1.bounds.center.length, 0.3, 0.6);
//      var density = lerpDouble(pos.x, 0, cells1.width, 0.2, 0.5);
      cells1[pos] = rng.float(1.0) < density;
    }

    for (var i = 0; i < 5; i++) {
      for (var pos in cells1.bounds) {
        var walls = 0;
        for (var dir in Direction.all) {
          var here = pos + dir;
          if (!cells1.bounds.contains(here) || cells1[here]) walls++;
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
      setFloor(pos.x + 1, pos.y + 1, !cells1[pos]);
    }
  }
}

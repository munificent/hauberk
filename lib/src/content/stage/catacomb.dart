import 'package:piecemeal/piecemeal.dart';

// TODO: Move blob.dart.
import '../dungeon/blob.dart';
import 'architect.dart';

/// Places a number of random blobs.
class Catacomb extends Architecture {
  // TODO: Fields to tune numbers below.
  // TODO: Don't cover entire stage?

  Iterable<String> build() sync* {
    for (var i = 0; i < 100; i++) {
      var cave = rng.oneIn(10) ? Blob.make32() : Blob.make16();
      for (var j = 0; j < 400; j++) {
        // Blobs tend to have unused space on the sides, so allow the position
        // to leak past the edge.
        var x = rng.range(-8, width - cave.width + 16);
        var y = rng.range(-8, height - cave.height + 16);

        if (_tryPlaceCave(cave, x, y)) {
          yield "cave";
          break;
        }
      }
    }
  }

  bool _tryPlaceCave(Array2D<bool> cave, int x, int y) {
    for (var pos in cave.bounds) {
      if (cave[pos]) {
        if (!canCarve(pos.offset(x, y))) return false;
      }
    }

    for (var pos in cave.bounds) {
      if (cave[pos]) carve(pos.x + x, pos.y + y);
    }

    return true;
  }
}

import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';
import 'blob.dart';

/// Places a number of random blobs.
class Catacomb extends Architecture {
  // TODO: Fields to tune numbers below.

  Iterable<String> build(Region region) sync* {
    for (var i = 0; i < 40; i++) {
      var cave = rng.oneIn(10) ? Blob.make32() : Blob.make16();
      for (var j = 0; j < 400; j++) {
        // TODO: dungeon.dart has similar code for placing the starting room.
        // Unify.
        // TODO: This puts pretty hard boundaries around the region. Is there
        // a way to more softly distribute the caves?
        var xMin = -8;
        var xMax = width - cave.width + 8;
        var yMin = -8;
        var yMax = height - cave.height + 8;

        switch (region) {
          case Region.everywhere:
            // Do nothing.
            break;
          case Region.n:
            yMax = height ~/ 2 - cave.height;
            break;
          case Region.ne:
            xMin = width ~/ 2;
            yMax = height ~/ 2 - cave.height;
            break;
          case Region.e:
            xMin = width ~/ 2;
            break;
          case Region.se:
            xMin = width ~/ 2;
            yMin = height ~/ 2;
            break;
          case Region.s:
            yMin = height ~/ 2;
            break;
          case Region.sw:
            xMax = width ~/ 2 - cave.width;
            yMin = height ~/ 2;
            break;
          case Region.w:
            xMax = width ~/ 2 - cave.width;
            break;
          case Region.nw:
            xMax = width ~/ 2 - cave.width;
            yMax = height ~/ 2 - cave.height;
            break;
        }

        // Blobs tend to have unused space on the sides, so allow the position
        // to leak past the edge.
        var x = rng.range(xMin, xMax);
        var y = rng.range(yMin, yMax);

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

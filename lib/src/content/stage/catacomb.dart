import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';
import 'blob.dart';

/// Places a number of random blobs.
class Catacomb extends Architecture {
  /// How much open space it tries to carve.
  final double _density;

  /// The minimum chamber size.
  final int _minSize;

  /// The maximum chamber size.
  final int _maxSize;

  Catacomb({double density, int minSize, int maxSize})
      : _density = density ?? 0.3,
        _minSize = minSize ?? 8,
        _maxSize = maxSize ?? 32;

  Iterable<String> build() sync* {
    // Don't try to make chambers bigger than the stage.
    var maxSize = _maxSize.toDouble();
    maxSize = math.min(maxSize, height.toDouble());
    maxSize = math.min(maxSize, width.toDouble());
    maxSize = math.sqrt(maxSize);

    // Make sure the size range isn't backwards.
    var minSize = math.sqrt(_minSize);
    minSize = math.min(minSize, maxSize);

    var failed = 0;
    while (carvedDensity < _density && failed < 100) {
      // Square the size to skew the distribution so that larges ones are
      // rarer than smaller ones.
      var size = math.pow(rng.float(minSize, maxSize), 2.0).toInt();
      var cave = Blob.make(size);

      var placed = false;
      for (var i = 0; i < 400; i++) {
        // TODO: dungeon.dart has similar code for placing the starting room.
        // Unify.
        // TODO: This puts pretty hard boundaries around the region. Is there
        // a way to more softly distribute the caves?
        var xMin = 1;
        var xMax = width - cave.width;
        var yMin = 1;
        var yMax = height - cave.height;

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

        var x = rng.range(xMin, xMax);
        var y = rng.range(yMin, yMax);

        if (_tryPlaceCave(cave, x, y)) {
          yield "cave";
          placed = true;
          break;
        }
      }

      if (!placed) failed++;
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

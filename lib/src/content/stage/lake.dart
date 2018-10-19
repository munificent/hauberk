import 'package:piecemeal/piecemeal.dart';

import 'architect.dart';
import 'blob.dart';

/// Uses a cellular automata to carve out rounded open cavernous areas.
class Lake extends Architecture {
  Iterable<String> build() sync* {
    var lakeCount = rng.inclusive(1, 2);
    for (var i = 0; i < lakeCount; i++) {
      _placeLake(rng.oneIn(3) ? Blob.make16() : Blob.make32());
      yield "Placing lake";
    }
  }

  void _placeLake(Array2D<bool> lake) {
    var x = rng.range(0, width - lake.width);
    var y = rng.range(0, height - lake.height);

    for (var pos in lake.bounds) {
      if (lake[pos]) placeWater(pos.offset(x, y));
    }
  }
}

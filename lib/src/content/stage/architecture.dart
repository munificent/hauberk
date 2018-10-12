import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'architect.dart';

class ArchitecturalStyle {
  /// Which order architectures are run. Lower numbers first.
  final int order;

  final Architecture Function() _factory;

  ArchitecturalStyle(this.order, this._factory);

  Architecture create(Architect architect) {
    var architecture = _factory();
    architecture._architect = architect;
    return architecture;
  }
}

/// Each architecture is a separate algorithm and some tuning parameters for it
/// that generates part of a stage.
abstract class Architecture {
  Architect get architect => _architect;
  Architect _architect;

  Iterable<String> build();

  Stage get stage => _architect.stage;
  Rect get bounds => _architect.stage.bounds;
  int get width => _architect.stage.width;
  int get height => _architect.stage.height;

  // TODO: Tell architect that this architecture owns this tile too?
  /// Marks the tile at [x], [y], as open floor if [isFloor] is true.
  void setFloor(int x, int y, [bool isFloor = true]) {
    if (isFloor) stage.get(x, y).type = Tiles.unfillable;
  }
  // TODO: Should we mark neighbors of this as claimed too so that they aren't
  // considered available for other architectures?

  /// Whether the tile at [pos] has already been claimed for use.
  bool isAvailable(Vec pos) => stage[pos].type == Tiles.fillable;
}

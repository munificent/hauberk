import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

// TODO: Move into this directory.
import '../tiles.dart';
import 'catacomb.dart';
import 'cavern.dart';

/// The main class that orchestrates painting and populating the stage.
class Architect {
  static Array2D<Architecture> debugOwners;

  static final ResourceSet<ArchitecturalStyle> styles = ResourceSet();

  static void _initializeStyles() {
    styles.defineTags("style");

    // TODO: Define more.
    styles.addUnnamed(ArchitecturalStyle(1, () => Catacomb()), 1, 1.0, "style");
    styles.addUnnamed(ArchitecturalStyle(1, () => Cavern()), 1, 1.0, "style");
  }

  final Lore _lore;
  final Stage stage;
  final int _depth;
  final Array2D<Architecture> _owners;

  Architect(this._lore, this.stage, this._depth)
      : _owners = Array2D(stage.width, stage.height) {
    if (styles.isEmpty) _initializeStyles();

    debugOwners = _owners;
  }

  /// Marks the tile at [x], [y] as open floor for [architecture].
  void _carve(Architecture architecture, int x, int y) {
    assert(_owners.get(x, y) == null || _owners.get(x, y) == architecture);

    stage.get(x, y).type = Tiles.unfillable;

    _owners.set(x, y, architecture);
    for (var dir in Direction.all) {
      var here = dir.offset(x, y);
      if (_owners.bounds.contains(here)) {
        _owners[here] = architecture;
      }
    }
  }

  Iterable<String> buildStage(Function(Vec) placeHero) sync* {
    // Initialize the stage with an edge of solid rock and everything else open
    // but fillable.
    for (var pos in stage.bounds) {
      stage[pos].type = Tiles.fillable;
    }

    // Build out the different architectures.
    // TODO: Take order into account.
    // TODO: Remember styles to decorate later.
    var styleCount = rng.inclusive(1, 2);
    for (var i = 0; i < styleCount; i++) {
      var style = styles.tryChoose(_depth, "style");
      var architect = style.create(this);
      yield* architect.build();
    }

    for (var pos in stage.bounds.trace()) {
      stage[pos].type = Tiles.rock;
    }

    // Fill in the remaining fillable tiles and keep everything connected.
    yield* _fillPassages();

    // TODO: Decorate and populate.

    // TODO: Style tiles.

    // TODO: Temp.
    placeHero(stage.findOpenTile());
  }

  /// Takes all of the remaining fillable tiles and fills them randomly with
  /// solid tiles or open tiles, making sure to preserve reachability.
  Iterable<String> _fillPassages() sync* {
    var unfillable = <Vec>[];
    var fillable = <Vec>[];
    for (var pos in stage.bounds) {
      var tile = stage[pos].type;
      if (tile == Tiles.unfillable) {
        unfillable.add(pos);
      } else if (tile == Tiles.fillable) {
        fillable.add(pos);
      }
    }

    rng.shuffle(unfillable);
    rng.shuffle(fillable);

    var start = unfillable.first;

    for (var pos in fillable) {
      // We may have already processed it.
      if (stage[pos].type != Tiles.fillable) continue;

      // Try to fill this tile.
      stage[pos].type = Tiles.filled;

      // TODO: There is probably a tighter way to optimize this by taking
      // cardinal and intercardinal directions into account.

      // Simple optimization: A tile with 0, 1, 7, or 8 solid tiles next to it
      // can't possibly break a path.
      var solidNeighbors = 0;
      for (var dir in Direction.all) {
        if (!stage[pos + dir].type.isTraversable) {
          solidNeighbors++;
        }
      }

      // If there is zero or one solid neighbor, you can walk around the tile.
      if (solidNeighbors <= 1) continue;

      // If there are sever or eight solid neighbors, it's already a cul-de-sac.
      if (solidNeighbors >= 7) continue;

      // See if we can still reach all the unfillable tiles.
      var reachedCave = 0;
      var flow = _CardinalFlow(stage, start);
      for (var reached in flow.reachable) {
        if (stage[reached].type == Tiles.unfillable) {
          reachedCave++;
        }
      }

      // Make sure we can reach every other open area from the starting one.
      // -1 to not count the starting tile.
      if (reachedCave != unfillable.length - 1) {
        // Filling this tile would cause something to be unreachable, so mark
        // it open.
        stage[pos].type = Tiles.unfilled;
      } else {
        // Optimization: Since we've already calculated the reachability to
        // everything, we can also eagerly fill in fillable regions that are
        // already cut off from the caves and passages.
        for (var pos in stage.bounds.inflate(-1)) {
          if (stage[pos].type == Tiles.fillable && flow.costAt(pos) == null) {
            stage[pos].type = Tiles.filled;
          }
        }
      }

      yield "$pos";
    }
  }
}

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
  Architect _architect;

  Iterable<String> build();

  Rect get bounds => _architect.stage.bounds;

  int get width => _architect.stage.width;

  int get height => _architect.stage.height;

  /// Marks the tile at [x], [y] as open floor for this architecture.
  void carve(int x, int y) {
    _architect._carve(this, x, y);
  }

  /// Whether this architecture can carve the tile at [pos].
  bool canCarve(Vec pos) {
    if (!_architect.stage.bounds.contains(pos)) return false;

    // Can't already be in use.
    if (_architect._owners[pos] != null) return false;

    // Need at least one tile of padding between other architectures.
    for (var dir in Direction.all) {
      var here = pos + dir;
      if (!_architect.stage.bounds.contains(here)) continue;

      var owner = _architect._owners[here];
      if (owner != null && owner != this) return false;
    }

    return true;
  }
}

class _CardinalFlow extends Flow {
  bool get includeDiagonals => false;

  _CardinalFlow(Stage stage, Vec start) : super(stage, start);

  /// The cost to enter [tile] at [pos] or `null` if the tile cannot be entered.
  int tileCost(int parentCost, Vec pos, Tile tile, bool isDiagonal) {
    // Can't enter impassable tiles.
    if (!tile.canEnter(Motility.walk)) return null;

    return 1;
  }
}

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

import '../tiles.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'dungeon.dart';
import 'lake.dart';
import 'painter.dart';
import 'river.dart';

// TODO: Consider regions that are randomly placed blobs in the middle too.
class Region {
  final String name;

  /// Cover the whole stage.
  static const everywhere = Region("everywhere");
  static const n = Region("n");
  static const ne = Region("ne");
  static const e = Region("e");
  static const se = Region("se");
  static const s = Region("s");
  static const sw = Region("sw");
  static const w = Region("w");
  static const nw = Region("nw");

  static const directions = [n, ne, e, se, s, sw, w, nw];

  const Region(this.name);
}

/// The main class that orchestrates painting and populating the stage.
class Architect {
  static Array2D<Architecture> debugOwners;

  static final ResourceSet<ArchitecturalStyle> _styles = ResourceSet();

  static void _initializeStyles() {
    _styles.defineTags("style");

    // TODO: Define more.
    _styles.addUnnamed(ArchitecturalStyle(() => Catacomb()), 1, 2.0, "style");
    _styles.addUnnamed(ArchitecturalStyle(() => Cavern()), 1, 1.0, "style");
    // TODO: Do we want to build this out after water is placed? Should water
    // be allowed to overlap it? Doing it after water might give it a more
    // interesting look. (Perhaps even sometimes run caverns or catacombs after
    // water?
    _styles.addUnnamed(ArchitecturalStyle(() => Dungeon()), 1, 10.0, "style");
    // TODO: Forest style that uses cavern-like CA to open an organic-shaped
    // area and then fills it with grass and trees. (Maybe just a specific
    // painter for Cavern?

    // TODO: Different liquid types including some that are dry.
    // TODO: Shore or islands?
    _styles.addUnnamed(ArchitecturalStyle(() => Lake(), isAquatic: true), 1, 1.0, "style");
    _styles.addUnnamed(ArchitecturalStyle(() => River(), isAquatic: true), 1, 1.0, "style");
  }

  final Lore _lore;
  final Stage stage;
  final int _depth;
  final Array2D<Architecture> _owners;

  Architect(this._lore, this.stage, this._depth)
      : _owners = Array2D(stage.width, stage.height) {
    if (_styles.isEmpty) _initializeStyles();

    debugOwners = _owners;
  }

  Iterable<String> buildStage(Function(Vec) placeHero) sync* {
    // Initialize the stage with an edge of solid and everything else open but
    // fillable.
    for (var pos in stage.bounds) {
      stage[pos].type = Tiles.fillable;
    }

    var styles = _pickStyles();

    int lastNonAquatic;
    for (var i = styles.length - 1; i >= 0; i--) {
      if (!styles[i]._isAquatic) {
        lastNonAquatic = i;
        break;
      }
    }

    // Pick unique regions for each style. The last non-aquatic one always
    // gets "everywhere" to ensure the entire stage is covered.
    var possibleRegions = Region.directions.toList();
    var regions = <Region>[];
    for (var i = 0; i < styles.length; i++) {
      if (i == lastNonAquatic || styles[i]._isAquatic) {
        regions.add(Region.everywhere);
      } else {
        regions.add(rng.take(possibleRegions));
      }
    }

    for (var i = 0; i < styles.length; i++) {
      var architect = styles[i].create(this, regions[i]);
      yield* architect.build();
    }

    for (var pos in stage.bounds.trace()) {
      stage[pos].type = Tiles.filled;
    }

    // TODO: Who owns passages? How are they styled?
    // Fill in the remaining fillable tiles and keep everything connected.
    yield* _fillPassages();

    // TODO: Add shortcuts.

    // TODO: Decorate and populate.
    // TODO: Instead of bleeding themes around, here's a simpler idea:
    // 1. Choose a random place to spawn a monster/item.
    // 2. Do a random walk from there to a result tile.
    // 3. Use the result tile's architecture/style/whatever to generate the
    //    monster/item.
    // 4. Place it in the original random location.
    // This way, you can get nearby styles and foreshadowing without a lot of
    // complex calculation.

    // Paint the tiles.
    // TODO: Associate different painters with different owners.
    var tilesByOwner = <Architecture, List<Vec>>{};
    for (var pos in stage.bounds) {
      var owner = _owners[pos];
      if (owner == null) {
        // TODO: Define a painter for the no-owner tiles.
        var tile = stage[pos];
        if (tile.type == Tiles.filled) {
          tile.type = Tiles.rock;
        } else if (tile.type == Tiles.unfilled) {
          // TODO: Turn unfilled tiles into bridges when surrounded by water.
          tile.type = Tiles.floor;
        }
      } else {
        tilesByOwner.putIfAbsent(owner, () => []).add(pos);
      }
    }

    var painter = Painter();
    tilesByOwner.forEach((architecture, tiles) {
      for (var pos in tiles) {
        stage[pos].type = painter.paint(pos, stage[pos].type);
      }
    });

    // TODO: Temp.
    placeHero(stage.findOpenTile());
  }

  List<ArchitecturalStyle> _pickStyles() {
    var result = <ArchitecturalStyle>[];

    // TODO: Change count range based on depth?
    var count = math.min(rng.taper(1, 10), 5);
    var hasNonAquatic = false;

    while (!hasNonAquatic || result.length < count) {
      var style = _styles.tryChoose(_depth, "style");

      // Make sure there's at least one walkable style.
      if (!style._isAquatic) hasNonAquatic = true;

      // TODO: Retry in this case?
      if (!result.contains(style)) result.add(style);
    }

    return result;
  }

  /// Marks the tile at [x], [y] as open floor for [architecture].
  void _carve(Architecture architecture, int x, int y) {
    assert(_owners.get(x, y) == null || _owners.get(x, y) == architecture);
    assert(stage.get(x, y).type == Tiles.fillable);

    stage.get(x, y).type = Tiles.unfillable;

    _owners.set(x, y, architecture);
    for (var dir in Direction.all) {
      var here = dir.offset(x, y);
      if (_owners.bounds.contains(here)) {
        _owners[here] = architecture;
      }
    }
  }

  bool _canCarve(Architecture architecture, Vec pos) {
    if (!stage.bounds.contains(pos)) return false;

    // Can't already be in use.
    if (_owners[pos] != null) return false;

    // Or water.
    if (stage[pos].type == Tiles.aquatic) return false;

    // Need at least one tile of padding between other architectures.
    for (var dir in Direction.all) {
      var here = pos + dir;
      if (!stage.bounds.contains(here)) continue;

      var owner = _owners[here];
      if (owner != null && owner != architecture) return false;
    }

    return true;
  }

  /// Takes all of the remaining fillable tiles and fills them randomly with
  /// solid tiles or open tiles, making sure to preserve reachability.
  Iterable<String> _fillPassages() sync* {
    // TODO: There might be faster way to do this using Tarjan's articulation
    // point algorithm. Something like:
    // 1. Find all articulation points. Mark them unfilled. These must be
    //    passages.
    // 2. Pick a random remaining non-articulation point and mark it filled. We
    //    know this is safe to do.
    // 3. As long as non-articulation points remain, go to 1.
    var unfillable = <Vec>[];
    var fillable = <Vec>[];
    for (var pos in stage.bounds.inflate(-1)) {
      var tile = stage[pos].type;
      if (tile == Tiles.unfillable) {
        unfillable.add(pos);
      } else if (tile == Tiles.fillable || tile == Tiles.aquatic) {
        fillable.add(pos);
      }
    }

    rng.shuffle(unfillable);
    rng.shuffle(fillable);

    var start = unfillable.first;

    for (var pos in fillable) {
      // We may have already processed it.
      var tile = stage[pos];
      if (tile.type != Tiles.fillable && tile.type != Tiles.aquatic) continue;

      // Try to fill this tile.
      tile.type = tile.type == Tiles.fillable ? Tiles.filled : Tiles.water;

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

      // If there are seven or eight solid neighbors, it's already a cul-de-sac.
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
        tile.type = Tiles.unfilled;
      } else {
        // Optimization: Since we've already calculated the reachability to
        // everything, we can also eagerly fill in fillable regions that are
        // already cut off from the caves and passages.
        for (var pos in stage.bounds.inflate(-1)) {
          if (flow.costAt(pos) == null) {
            if (stage[pos].type == Tiles.fillable) {
              stage[pos].type = Tiles.filled;
            } else if (stage[pos].type == Tiles.aquatic) {
              stage[pos].type = Tiles.water;
            }
          }
        }
      }

      yield "$pos";
    }
  }
}

class ArchitecturalStyle {
  final Architecture Function() _factory;
  final bool _isAquatic;

  ArchitecturalStyle(this._factory, {bool isAquatic})
      : _isAquatic = isAquatic ?? false;

  Architecture create(Architect architect, Region region) {
    var architecture = _factory();
    architecture._architect = architect;
    architecture._region = region;
    return architecture;
  }
}

/// Each architecture is a separate algorithm and some tuning parameters for it
/// that generates part of a stage.
abstract class Architecture {
  Architect _architect;
  Region _region;

  Iterable<String> build();

  Rect get bounds => _architect.stage.bounds;

  int get width => _architect.stage.width;

  int get height => _architect.stage.height;

  Region get region => _region;

  /// Marks the tile at [x], [y] as open floor for this architecture.
  void carve(int x, int y) => _architect._carve(this, x, y);

  /// Whether this architecture can carve the tile at [pos].
  bool canCarve(Vec pos) => _architect._canCarve(this, pos);

  void placeWater(Vec pos) {
    _architect.stage[pos].type = Tiles.aquatic;
    _architect._owners[pos] = null;
  }

  /// Marks the tile at [pos] as not allowing a passage to be dug through it.
  void preventPassage(Vec pos) {
    assert(_architect._owners[pos] == null || _architect._owners[pos] == this);

    if (_architect.stage[pos].type == Tiles.fillable) {
      _architect.stage[pos].type = Tiles.filled;
    }
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

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

import '../tiles.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'dungeon.dart';
import 'lake.dart';
import 'painter.dart';
import 'river.dart';

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

  static final ResourceSet<ArchitecturalStyle> _caves = ResourceSet();
  static final ResourceSet<ArchitecturalStyle> _waters = ResourceSet();

  static void _initializeStyles() {
    _caves.defineTags("style");

    // TODO: Define more.
    _caves.addUnnamed(ArchitecturalStyle(() => Catacomb()), 1, 2.0, "style");
    _caves.addUnnamed(ArchitecturalStyle(() => Cavern()), 1, 1.0, "style");
    // TODO: Do we want to build this out after water is placed? Should water
    // be allowed to overlap it? Doing it after water might give it a more
    // interesting look. (Perhaps even sometimes run caverns or catacombs after
    // water?
    _caves.addUnnamed(ArchitecturalStyle(() => Dungeon()), 1, 10.0, "style");

    // TODO: Rivers.
    // TODO: Different liquid types.
    _waters.defineTags("style");
    _waters.addUnnamed(ArchitecturalStyle(() => Lake()), 1, 1.0, "style");
    _waters.addUnnamed(ArchitecturalStyle(() => River()), 1, 1.0, "style");
  }

  final Lore _lore;
  final Stage stage;
  final int _depth;
  final Array2D<Architecture> _owners;

  Architect(this._lore, this.stage, this._depth)
      : _owners = Array2D(stage.width, stage.height) {
    if (_caves.isEmpty) _initializeStyles();

    debugOwners = _owners;
  }

  Iterable<String> buildStage(Function(Vec) placeHero) sync* {
    // Initialize the stage with an edge of solid and everything else open but
    // fillable.
    for (var pos in stage.bounds) {
      stage[pos].type = Tiles.fillable;
    }

    // Carve natural caverns.
    var caves = _pickStyles(_caves, 1, 3);

    // Pick unique regions for each. The last one always gets "everywhere" to
    // ensure the entire stage is covered.
    var possibleRegions = Region.directions.toList();
    var regions = <Region>[];
    for (var i = 0; i < caves.length - 1; i++) {
      regions.add(rng.take(possibleRegions));
    }
    regions.add(Region.everywhere);

    for (var i = 0; i < caves.length; i++) {
      var architect = caves[i].create(this);
      yield* architect.build(regions[i]);
    }

    // Add water features.
    var waters = _pickStyles(_waters, 0, 2);
    for (var water in waters) {
      yield* water.create(this).build(Region.everywhere);
    }

    for (var pos in stage.bounds.trace()) {
      stage[pos].type = Tiles.filled;
    }

    // TODO: Who owns passages? How are they styled?
    // Fill in the remaining fillable tiles and keep everything connected.
    yield* _fillPassages();

    // TODO: Decorate and populate.

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

  List<ArchitecturalStyle> _pickStyles(
      ResourceSet<ArchitecturalStyle> styles, int min, int max) {
    var result = <ArchitecturalStyle>[];
    var count = rng.inclusive(min, max);
    for (var i = 0; i < count; i++) {
      var style = styles.tryChoose(_depth, "style");
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

  ArchitecturalStyle(this._factory);

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

  Iterable<String> build(Region region);

  Rect get bounds => _architect.stage.bounds;

  int get width => _architect.stage.width;

  int get height => _architect.stage.height;

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

    _architect.stage[pos].type = Tiles.filled;
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

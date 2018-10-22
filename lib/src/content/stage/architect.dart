import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../tiles.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'dungeon.dart';
import 'lake.dart';
import 'painter.dart';
import 'reachability.dart';
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
    _styles.addUnnamed(
        ArchitecturalStyle(() => Lake(), isAquatic: true), 1, 1.0, "style");
    _styles.addUnnamed(
        ArchitecturalStyle(() => River(), isAquatic: true), 1, 1.0, "style");
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
      stage[pos].type = TempTiles.unformed;
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
      stage[pos].type = TempTiles.solid;
    }

    // Fill in the remaining fillable tiles and keep everything connected.
    var unownedPassages = <Vec>[];

    yield* _fillPassages(unownedPassages);

    yield* _claimPassages(unownedPassages);

    // TODO: Add shortcuts.

    // TODO: Place stairs.

    // TODO: Decorate and populate.
    // TODO: Instead of bleeding themes around, here's a simpler idea:
    // 1. Choose a random place to spawn a monster/item.
    // 2. Do a random walk from there to a result tile.
    // 3. Use the result tile's architecture/style/whatever to generate the
    //    monster/item.
    // 4. Place it in the original random location.
    // This way, you can get nearby styles and foreshadowing without a lot of
    // complex calculation.

    _paintTiles();

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

      if (!result.contains(style)) result.add(style);
    }

    return result;
  }

  /// Marks the tile at [x], [y] as open floor for [architecture].
  void _carve(Architecture architecture, int x, int y) {
    assert(_owners.get(x, y) == null || _owners.get(x, y) == architecture);
    assert(stage.get(x, y).type == TempTiles.unformed);

    stage.get(x, y).type = TempTiles.open;

    // Claim all neighboring dry tiles too. This way the architecture can paint
    // the surrounding solid tiles however it wants.
    _owners.set(x, y, architecture);
    for (var dir in Direction.all) {
      var here = dir.offset(x, y);
      if (_owners.bounds.contains(here) &&
          stage[here].type != TempTiles.unformedWet) {
        _owners[here] = architecture;
      }
    }
  }

  bool _canCarve(Architecture architecture, Vec pos) {
    if (!stage.bounds.contains(pos)) return false;

    // Can't already be in use.
    if (_owners[pos] != null) return false;

    // Or water.
    if (stage[pos].type == TempTiles.unformedWet) return false;

    // Need at least one tile of padding between other dry architectures so that
    // this one can have a ring of solid tiles around itself without impinging
    // on the other architecture. This means that there will be at least two
    // solid tiles between two open tiles of different architectures, one owned
    // by each. That way, if they style their walls differently, one doesn't
    // bleed into the other.
    for (var here in pos.neighbors) {
      if (!stage.bounds.contains(here)) continue;

      if (stage[here].type == TempTiles.unformedWet) continue;

      var owner = _owners[here];
      if (owner != null && owner != architecture) return false;
    }

    return true;
  }

  /// Takes all of the remaining fillable tiles and fills them randomly with
  /// solid tiles or open tiles, making sure to preserve reachability.
  Iterable<String> _fillPassages(List<Vec> unownedPassages) sync* {
    // TODO: There might be faster way to do this using Tarjan's articulation
    // point algorithm. Something like:
    // 1. Find all articulation points. Mark them unfilled. These must be
    //    passages.
    // 2. Pick a random remaining non-articulation point and mark it filled. We
    //    know this is safe to do.
    // 3. As long as non-articulation points remain, go to 1.
    var openCount = 0;
    var start = Vec.zero;
    var startDistance = 99999;

    var unformed = <Vec>[];
    for (var pos in stage.bounds.inflate(-1)) {
      var tile = stage[pos].type;
      if (tile == TempTiles.open) {
        openCount++;

        // Prefer a starting tile near the center.
        var distance = (pos - stage.bounds.center).rookLength;
        if (distance < startDistance) {
          start = pos;
          startDistance = distance;
        }
      } else if (!_isFormed(tile)) {
        unformed.add(pos);
      }
    }

    rng.shuffle(unformed);

    var reachability = Reachability(stage, start);

    for (var pos in unformed) {
      var tile = stage[pos];

      // We may have already processed it.
      if (_isFormed(tile.type)) continue;

      // Try to fill this tile.
      _fill(tile);

      // Optimization: If it's already been cut off, we know it can be filled.
      if (!reachability.isReachable(pos)) continue;

      reachability.fill(pos);

      // TODO: There is probably a tighter way to optimize this by taking
      // cardinal and intercardinal directions into account.

      // Simple optimization: A tile with 0, 1, 7, or 8 solid tiles next to it
      // can't possibly break a path.
      var solidNeighbors = 0;
      for (var neighbor in pos.neighbors) {
        if (!stage[neighbor].type.isTraversable) {
          solidNeighbors++;
        }
      }

      // If there is zero or one solid neighbor, you can walk around the tile.
      if (solidNeighbors <= 1) continue;

      // If there are seven or eight solid neighbors, it's already a cul-de-sac.
      if (solidNeighbors >= 7) continue;

      // See if we can still reach all the unfillable tiles.
      var reachedOpen = 0;
      for (var here in stage.bounds) {
        if (reachability.isReachable(here) &&
            stage[here].type == TempTiles.open) {
          reachedOpen++;
        }
      }

      // Make sure we can reach every other open area from the starting one.
      if (reachedOpen != openCount) {
        // Filling this tile would cause something to be unreachable, so it must
        // be a passage.
        _makePassage(unownedPassages, pos);
        reachability.undoFill();
      }

      yield "$pos";
    }
  }

  void _makePassage(List<Vec> unownedPassages, Vec pos) {
    var tile = stage[pos];

    // Filling this tile would cause something to be unreachable, so it must
    // be a passage.
    if (tile.type == TempTiles.solid) {
      tile.type = TempTiles.passage;
    } else if (tile.type == TempTiles.solidWet) {
      tile.type = TempTiles.passageWet;
    } else {
      assert(false, "Unexpected tile type.");
    }

    var owner = _owners[pos];
    if (owner == null) {
      unownedPassages.add(pos);
    } else {
      // The passage is within the edge of an architecture, so extend the
      // boundary around it too.
      _claimNeighbors(pos, owner);
    }
  }

  /// Find owners for all passage tiles that don't currently have one.
  ///
  /// This works by finding the passage tiles that have a neighboring owner and
  /// spreading that owner to this one. It does that repeatedly until all tiles
  /// are claimed.
  Iterable<String> _claimPassages(List<Vec> unownedPassages) sync* {
    while (true) {
      var stillUnowned = <Vec>[];
      for (var pos in unownedPassages) {
        var neighbors = <Architecture>[];
        for (var neighbor in pos.neighbors) {
          var owner = _owners[neighbor];
          if (owner != null) neighbors.add(owner);
        }

        if (neighbors.isNotEmpty) {
          var owner = rng.item(neighbors);
          _owners[pos] = owner;
          _claimNeighbors(pos, owner);
        } else {
          stillUnowned.add(pos);
        }
      }

      if (stillUnowned.isEmpty) break;
      unownedPassages = stillUnowned;

      yield "Claim";
    }
  }

  /// Claims any neighboring tiles of [pos] for [owner] if they don't already
  /// have an owner.
  void _claimNeighbors(Vec pos, Architecture owner) {
    for (var neighbor in pos.neighbors) {
      if (_owners[neighbor] == null) _owners[neighbor] = owner;
    }
  }

  /// Turn the temporary tiles into real tiles based on each architecutre's
  /// painters.
  void _paintTiles() {
    for (var pos in stage.bounds) {
      var tile = stage[pos];
      var owner = _owners[pos];
      if (owner == null) {
        tile.type = Painter.base.paint(tile.type);
      } else {
        tile.type = owner.painter.paint(tile.type);
      }
    }
  }

  void _fill(Tile tile) {
    if (tile.type == TempTiles.unformed) {
      tile.type = TempTiles.solid;
    } else if (tile.type == TempTiles.unformedWet) {
      tile.type = TempTiles.solidWet;
    } else {
      assert(tile.type == TempTiles.solid || tile.type == TempTiles.solidWet,
          "Unexpected tile type.");
    }
  }

  bool _isFormed(TileType type) =>
      type != TempTiles.unformed && type != TempTiles.unformedWet;
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

  Painter get painter => Painter.base;

  /// Marks the tile at [x], [y] as open floor for this architecture.
  void carve(int x, int y) => _architect._carve(this, x, y);

  /// Whether this architecture can carve the tile at [pos].
  bool canCarve(Vec pos) => _architect._canCarve(this, pos);

  void placeWater(Vec pos) {
    _architect.stage[pos].type = TempTiles.unformedWet;
    _architect._owners[pos] = this;
  }

  /// Marks the tile at [pos] as not allowing a passage to be dug through it.
  void preventPassage(Vec pos) {
    assert(_architect._owners[pos] == null ||
        _architect._owners[pos] == this ||
        _architect.stage[pos].type == TempTiles.unformedWet);

    if (_architect.stage[pos].type == TempTiles.unformed) {
      _architect.stage[pos].type = TempTiles.solid;
    }
  }
}

/// Temporary tile types used during stage generation.
class TempTiles {
  /// An unformed tile that can be turned into aquatic, passage, or solid.
  static final unformed = Tiles.tile("unformed", "?", slate).open();

  /// An unformed tile that can be turned into water of some kind when "filled"
  /// or a bridge when used as a passage.
  static final unformedWet = Tiles.tile("unformed wet", "≈", slate).open();

  /// An open floor tile generated by an architecture.
  static final open = Tiles.tile("open", "·", gunsmoke).open();

  /// A solid tile that has been filled in the passage generator.
  static final solid = Tiles.tile("solid", "#", gunsmoke).solid();

  /// An open tile that the passage generator knows must remain open.
  static final passage = Tiles.tile("passage", "-", gunsmoke).open();

  /// An untraversable wet tile that has been filled in the passage generator.
  static final solidWet = Tiles.tile("solid wet", "≈", cornflower).solid();

  /// A traversable wet tile that the passage generator knows must remain open.
  static final passageWet = Tiles.tile("wet passage", "-", cornflower).open();
}

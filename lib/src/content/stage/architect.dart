import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import '../decor/decor.dart';
import 'architectural_style.dart';
import 'painter.dart';
import 'reachability.dart';

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

  final Lore _lore;
  final Stage stage;
  final int _depth;
  final Array2D<Architecture> _owners;

  Architect(this._lore, this.stage, this._depth)
      : _owners = Array2D(stage.width, stage.height) {
    debugOwners = _owners;
  }

  Iterable<String> buildStage(Function(Vec) placeHero) sync* {
    // Initialize the stage with an edge of solid and everything else open but
    // fillable.
    for (var pos in stage.bounds) {
      stage[pos].type = Tiles.unformed;
    }

    var styles = _pickStyles();

    int lastNonAquatic;
    for (var i = styles.length - 1; i >= 0; i--) {
      if (!styles[i].isAquatic) {
        lastNonAquatic = i;
        break;
      }
    }

    // Pick unique regions for each style. The last non-aquatic one always
    // gets "everywhere" to ensure the entire stage is covered.
    var possibleRegions = Region.directions.toList();
    var regions = <Region>[];
    for (var i = 0; i < styles.length; i++) {
      if (i == lastNonAquatic || styles[i].isAquatic) {
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
      stage[pos].type = Tiles.solid;
    }

    // Fill in the remaining fillable tiles and keep everything connected.
    var unownedPassages = <Vec>[];

    yield* _fillPassages(unownedPassages);

    yield* _claimPassages(unownedPassages);

    // TODO: Add shortcuts.
    // TODO: Here's an idea for shortcuts. After carving rooms, randomly pick
    // some of them and divide them with temporary walls. Then build passages
    // as normal. Since the entire room is no longer connected to itself, the
    // passage generator will generate multiple paths to each side of it. Then
    // remove those dividers.

    // TODO: Place doors.
    // TODO: Place stairs.

    // TODO: Populate.
    // TODO: Instead of bleeding themes around, here's a simpler idea:
    // 1. Choose a random place to spawn a monster/item.
    // 2. Do a random walk from there to a result tile.
    // 3. Use the result tile's architecture/style/whatever to generate the
    //    monster/item.
    // 4. Place it in the original random location.
    // This way, you can get nearby styles and foreshadowing without a lot of
    // complex calculation.

    _paintTiles();

    // TODO: Should this happen before or after painting?
    yield* _placeDecor();

    // TODO: Temp.
    placeHero(stage.findOpenTile());
  }

  List<ArchitecturalStyle> _pickStyles() {
    var result = <ArchitecturalStyle>[];

    // TODO: Change count range based on depth?
    var count = math.min(rng.taper(1, 10), 5);
    var hasNonAquatic = false;

    while (!hasNonAquatic || result.length < count) {
      var style = ArchitecturalStyle.all.tryChoose(_depth, "style");

      // Make sure there's at least one walkable style.
      if (!style.isAquatic) hasNonAquatic = true;

      if (!result.contains(style)) result.add(style);
    }

    return result;
  }

  /// Marks the tile at [x], [y] as open floor for [architecture].
  void _carve(Architecture architecture, int x, int y) {
    assert(_owners.get(x, y) == null || _owners.get(x, y) == architecture);
    assert(stage.get(x, y).type == Tiles.unformed);

    stage.get(x, y).type = Tiles.open;

    // Claim all neighboring dry tiles too. This way the architecture can paint
    // the surrounding solid tiles however it wants.
    _owners.set(x, y, architecture);
    for (var dir in Direction.all) {
      var here = dir.offset(x, y);
      if (_owners.bounds.contains(here) &&
          stage[here].type != Tiles.unformedWet) {
        _owners[here] = architecture;
      }
    }
  }

  bool _canCarve(Architecture architecture, Vec pos) {
    if (!stage.bounds.contains(pos)) return false;

    // Can't already be in use.
    if (_owners[pos] != null) return false;

    // Or water.
    if (stage[pos].type == Tiles.unformedWet) return false;

    // Need at least one tile of padding between other dry architectures so that
    // this one can have a ring of solid tiles around itself without impinging
    // on the other architecture. This means that there will be at least two
    // solid tiles between two open tiles of different architectures, one owned
    // by each. That way, if they style their walls differently, one doesn't
    // bleed into the other.
    for (var here in pos.neighbors) {
      if (!stage.bounds.contains(here)) continue;

      if (stage[here].type == Tiles.unformedWet) continue;

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
      if (tile == Tiles.open) {
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
            stage[here].type == Tiles.open) {
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
    if (tile.type == Tiles.solid) {
      tile.type = Tiles.passage;
    } else if (tile.type == Tiles.solidWet) {
      tile.type = Tiles.passageWet;
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

  Iterable<String> _placeDecor() sync* {
    var tilesByOwner = <Architecture, List<Vec>>{};
    for (var pos in stage.bounds) {
      var owner = _owners[pos];
      if (owner != null) {
        tilesByOwner.putIfAbsent(owner, () => []).add(pos);
      }
    }

    for (var entry in tilesByOwner.entries) {
      var architecture = entry.key;
      var tiles = entry.value;

      var painter = DecorPainter._(architecture);

      // TODO: Let architecture/theme control density.
      var decorTiles = rng.round(tiles.length * 0.1);
      decorTiles = rng.float(decorTiles * 0.8, decorTiles * 1.2).ceil();

      var tries = 0;
      while (tries++ < decorTiles && painter._painted < decorTiles) {
        var decor = Decor.choose(architecture.theme);
        if (decor == null) continue;

        var allowed = <Vec>[];

        for (var tile in tiles) {
          if (decor.canPlace(painter, tile)) {
            allowed.add(tile);
          }
        }

        if (allowed.isNotEmpty) {
          decor.place(painter, rng.item(allowed));
          yield "Placed decor";
        }
      }
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
    if (tile.type == Tiles.unformed) {
      tile.type = Tiles.solid;
    } else if (tile.type == Tiles.unformedWet) {
      tile.type = Tiles.solidWet;
    } else {
      assert(tile.type == Tiles.solid || tile.type == Tiles.solidWet,
          "Unexpected tile type.");
    }
  }

  bool _isFormed(TileType type) =>
      type != Tiles.unformed && type != Tiles.unformedWet;
}

// TODO: Figure out how this interacts with Painter.
class DecorPainter {
  final Architecture _architecture;
  int _painted = 0;

  DecorPainter._(this._architecture);

  Rect get bounds => _architecture._architect.stage.bounds;

  bool ownsTile(Vec pos) =>
      _architecture._architect._owners[pos] == _architecture;

  TileType getTile(Vec pos) {
    assert(ownsTile(pos));
    return _architecture._architect.stage[pos].type;
  }

  void setTile(Vec pos, TileType type) {
    assert(_architecture._architect._owners[pos] == _architecture);
    _architecture._architect.stage[pos].type = type;
    _painted++;
  }
}

/// Each architecture is a separate algorithm and some tuning parameters for it
/// that generates part of a stage.
abstract class Architecture {
  Architect _architect;
  ArchitecturalStyle _style;
  Region _region;

  Iterable<String> build();

  Rect get bounds => _architect.stage.bounds;

  int get width => _architect.stage.width;

  int get height => _architect.stage.height;

  Region get region => _region;

  Painter get painter => Painter.base;

  String get theme => _style.theme;

  void bind(ArchitecturalStyle style, Architect architect, Region region) {
    _architect = architect;
    _style = style;
    _region = region;
  }

  /// Marks the tile at [x], [y] as open floor for this architecture.
  void carve(int x, int y) => _architect._carve(this, x, y);

  /// Whether this architecture can carve the tile at [pos].
  bool canCarve(Vec pos) => _architect._canCarve(this, pos);

  void placeWater(Vec pos) {
    _architect.stage[pos].type = Tiles.unformedWet;
    _architect._owners[pos] = this;

    // TODO: Should water own the walls that surround it (if not already owned)?
  }

  /// Marks the tile at [pos] as not allowing a passage to be dug through it.
  void preventPassage(Vec pos) {
    assert(_architect._owners[pos] == null ||
        _architect._owners[pos] == this ||
        _architect.stage[pos].type == Tiles.unformedWet);

    if (_architect.stage[pos].type == Tiles.unformed) {
      _architect.stage[pos].type = Tiles.solid;
    }
  }
}

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'architectural_style.dart';
import 'decorator.dart';
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

  final Lore lore;
  final Stage stage;
  final int depth;
  final Array2D<Architecture> _owners;

  int _carvedTiles = 0;

  Architect(this.lore, this.stage, this.depth)
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

    int lastFillable;
    for (var i = styles.length - 1; i >= 0; i--) {
      if (styles[i].canFill) {
        lastFillable = i;
        break;
      }
    }

    // Pick unique regions for each style. The last non-aquatic one always
    // gets "everywhere" to ensure the entire stage is covered.
    var possibleRegions = Region.directions.toList();
    var regions = <Region>[];
    for (var i = 0; i < styles.length; i++) {
      if (i == lastFillable || !styles[i].canFill) {
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
    yield* _addShortcuts(unownedPassages);
    yield* _claimPassages(unownedPassages);

    var decorator = Decorator(this);
    yield* decorator.decorate();

    placeHero(decorator.heroPos);
  }

  Architecture ownerAt(Vec pos) => _owners[pos];

  List<ArchitecturalStyle> _pickStyles() {
    var result = <ArchitecturalStyle>[];

    // TODO: Change count range based on depth?
    var count = math.min(rng.taper(1, 10), 5);
    var hasFillable = false;

    while (!hasFillable || result.length < count) {
      var style = ArchitecturalStyle.all.tryChoose(depth);

      // Make sure there's at least one style that can fill the entire stage.
      if (style.canFill) hasFillable = true;

      if (!result.contains(style)) result.add(style);
    }

    return result;
  }

  /// Marks the tile at [x], [y] as open floor for [architecture].
  void _carve(Architecture architecture, int x, int y, TileType tile) {
    assert(_owners.get(x, y) == null || _owners.get(x, y) == architecture);
    assert(stage.get(x, y).type == Tiles.unformed);

    stage.get(x, y).type = tile ?? Tiles.open;
    _carvedTiles++;

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

    var count = 0;
    for (var pos in unformed) {
      var tile = stage[pos];

      // We may have already processed it.
      if (_isFormed(tile.type)) continue;

      // Try to fill this tile.
      if (tile.type == Tiles.unformed) {
        tile.type = Tiles.solid;
      } else if (tile.type == Tiles.unformedWet) {
        tile.type = Tiles.solidWet;
      } else {
        assert(tile.type == Tiles.solid || tile.type == Tiles.solidWet,
            "Unexpected tile type.");
      }

      // Optimization: If it's already been cut off, we know it can be filled.
      if (!reachability.isReachable(pos)) continue;

      reachability.fill(pos);

      // See if we can still reach all the unfillable tiles.
      if (reachability.reachedOpenCount != openCount) {
        // Filling this tile would cause something to be unreachable, so it must
        // be a passage.
        _makePassage(unownedPassages, pos);
        reachability.undoFill();
      }

      // Yielding is slow, so don't do it often.
      if (count++ % 20 == 0) yield "$pos";
    }
  }

  Iterable<String> _addShortcuts(List<Vec> unownedPassages) sync* {
    var possibleStarts = <_Path>[];
    for (var pos in stage.bounds.inflate(-1)) {
      if (!_isOpenAt(pos)) continue;

      for (var dir in Direction.cardinal) {
        // Needs to be in an open area going into a solid area, like:
        //
        //     .#
        //     >#
        //     .#
        // TODO: Could loosen this somewhat. Should we let shortcuts start from
        // passages? Corners?
        if (!_isOpenAt(pos + dir.rotateLeft90)) continue;
        if (!_isSolidAt(pos + dir.rotateLeft45)) continue;
        if (!_isSolidAt(pos + dir)) continue;
        if (!_isSolidAt(pos + dir.rotateRight45)) continue;
        if (!_isOpenAt(pos + dir.rotateRight90)) continue;

        possibleStarts.add(_Path(pos, dir));
      }
    }

    rng.shuffle(possibleStarts);

    var shortcuts = 0;

    // TODO: Vary this?
    var maxShortcuts = rng.range(5, 40);

    for (var path in possibleStarts) {
      if (!_tryShortcut(unownedPassages, path.pos, path.dir)) continue;

      yield "Shortcut";
      shortcuts++;
      if (shortcuts >= maxShortcuts) break;
    }
  }

  /// Tries to place a shortcut from [start] going towards [heading].
  ///
  /// The [start] position is the open tile next to the wall where the shortcut
  /// will begin.
  ///
  /// Returns `true` if a shortcut was added.
  bool _tryShortcut(List<Vec> unownedPassages, Vec start, Direction heading) {
    // A shortcut can start here, so try to walk it until it hits another open
    // area.
    var tiles = <Vec>[];
    var pos = start + heading;

    while (true) {
      tiles.add(pos);

      var next = pos + heading;
      if (!stage.bounds.contains(next)) return false;

      if (_isOpenAt(next)) {
        if (_isShortcut(start, next, tiles.length)) {
          for (var pos in tiles) {
            _makePassage(unownedPassages, pos);
          }
          return true;
        }

        // We found a path, but it's not worth it.
        return false;
      }

      // If the passage runs into an opening on the side, it's weird, so don't
      // put a shortcut.
      if (!_isSolidAt(next + heading.rotateLeft90)) return false;
      if (!_isSolidAt(next + heading.rotateRight90)) return false;

      // Don't make shortcuts that are too long.
      if (rng.percent(tiles.length * 10)) return false;

      // TODO: Consider having the path turn randomly.

      // Keep going.
      pos = next;
    }
  }

  /// Returns `true` if a passage with [length] from [from] to [to] is
  /// significantly shorter than the current shortest path between those points.
  ///
  /// Used to avoid placing pointless shortcuts on the stage.
  bool _isShortcut(Vec from, Vec to, int passageLength) {
    // If the current path from [from] to [to] is this long or longer, then
    // the shortcut is worth adding.
    var longLength = passageLength * 2 + rng.range(8, 16);

    var pathfinder = _LengthPathfinder(stage, from, to, longLength);

    // If there is an existing path that's short enough, this isn't a shortcut.
    return !pathfinder.search();
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

  bool _isFormed(TileType type) =>
      type != Tiles.unformed && type != Tiles.unformedWet;

  bool _isOpenAt(Vec pos) {
    var type = stage[pos].type;
    return type == Tiles.open ||
        type == Tiles.passage ||
        type == Tiles.passageWet;
  }

  bool _isSolidAt(Vec pos) {
    var type = stage[pos].type;
    return type == Tiles.solid || type == Tiles.solidWet;
  }
}

class _Path {
  final Vec pos;
  final Direction dir;

  _Path(this.pos, this.dir);
}

/// Each architecture is a separate algorithm and some tuning parameters for it
/// that generates part of a stage.
abstract class Architecture {
  Architect _architect;
  ArchitecturalStyle _style;
  Region _region;

  Iterable<String> build();

  int get depth => _architect.depth;

  Rect get bounds => _architect.stage.bounds;

  int get width => _architect.stage.width;

  int get height => _architect.stage.height;

  Region get region => _region;

  String get paintStyle => "rock";

  /// Gets the ratio of carved tiles to carvable tiles.
  ///
  /// This tells you how much of the stage has been opened up by architectures.
  double get carvedDensity {
    var possible = (width - 2) * (height - 2);
    return _architect._carvedTiles / possible;
  }

  ArchitecturalStyle get style => _style;

  void bind(ArchitecturalStyle style, Architect architect, Region region) {
    _architect = architect;
    _style = style;
    _region = region;
  }

  /// Override this if the architecture wants to handle spawning monsters in its
  /// tiles itself.
  bool spawnMonsters(Painter painter) => false;

  /// Sets the tile at [x], [y] to [tile] and owned by this architecture.
  ///
  /// If [tile] is omitted, uses [Tiles.open].
  void carve(int x, int y, [TileType tile]) =>
      _architect._carve(this, x, y, tile);

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

/// Used to see if there is already a path between two points in the dungeon
/// before adding an extra passage between two open areas.
///
/// Returns `true` if it can find an existing path shorter or as short as the
/// given max length.
class _LengthPathfinder extends Pathfinder<bool> {
  final int _maxLength;

  _LengthPathfinder(Stage stage, Vec start, Vec end, this._maxLength)
      : super(stage, start, end);

  bool processStep(Path path) {
    if (path.length >= _maxLength) return false;

    return null;
  }

  bool reachedGoal(Path path) => true;

  int stepCost(Vec pos, Tile tile) {
    if (tile.canEnter(Motility.doorAndWalk)) return 1;

    return null;
  }

  bool unreachableGoal() => false;
}

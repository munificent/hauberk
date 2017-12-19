import 'dart:collection';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'fov.dart';
import 'stage.dart';

/// Calculates the lighting and occlusion for the level.
///
/// This determines which tiles the hero (and the player) can see, as well as
/// how much light is cast on each tile.
///
/// This information potentially affects the entire level and needs to be
/// recalculated whenever the hero moves, a light-carrying actor moves, a door
/// is opened, a light-element attack is made, etc. Thus, this is one of the
/// most performance-critical parts of the engine.
///
/// The algorithms used here are designed to give acceptable results while also
/// being efficient, at the expense of sacrificing realism. Also, much of this
/// code is micro-optimized in ways that do matter for performance.
class Lighting {
  /// The maximum illumination value of a tile.
  ///
  /// This is clamped because the light propagation code uses a bucket queue
  /// which assumes a maximum light level.
  static const max = 255;

  /// Given an emanation "level", returns the quantity of light produced.
  ///
  /// The levels are tuned higher-level echelons where each value corresponds
  /// to a "nice-looking" increasing radius of light. Changing the attenuation
  /// values below will likely require these to be re-tuned.
  static int emanationForLevel(int level) {
    switch (level) {
      case 1:
        // Only the tile itself.
        return 40;

      case 2:
        // A 3x3 "plus" shape.
        return 56;

      case 3:
        // A 3x3 square.
        return 72;

      case 4:
        // A 5x5 diamond.
        return 96;

      case 5:
        // A 5x5 circle.
        return 120;

      case 6:
        // A 7x7 circle.
        return 160;

      case 7:
        // A 9x9 circle.
        return 200;

      case 8:
        // A 11x11 circle.
        return 240;

      default:
        // Anything else is clamped.
        if (level <= 0) return 0;
        return max;
    }
  }

  /// How much brightness decreases each step in a cardinal direction.
  static final _attenuate = 256 ~/ 6;

  /// How much brightness decreases each diagonal step.
  ///
  /// The "1.5" scale is to roughly approximate the `sqrt(2)` Cartesian length
  /// of the diagonal. This gives the fall-off a more circular appearance. This
  /// is a little weird because distance in terms of game mechanics (i.e. how
  /// many steps you have to take to get from point A to B) treats diagonals as
  /// the same length as straight lines, but it looks nicer.
  ///
  /// Using 1.5 instead of a closer approximation to `sqrt(2)` because it makes
  /// fall-off look a little less squarish.
  static final _diagonalAttenuate = (_attenuate * 1.5).ceil();

  final Stage _stage;

  /// The cached illumination on each tile from tile emanation values.
  final Array2D<int> _floorLight;

  /// The cached illumination on each tile from actor emanation.
  ///
  /// We store this separately from [_floorLight] because there are many more
  /// emanating tiles than actors but actors change (move) more frequently.
  /// Splitting these into two layers lets us recalculate one without
  /// invalidating the other.
  final Array2D<int> _actorLight;

  final Fov _fov;
  final _LightQueue _queue = new _LightQueue();

  bool _floorLightDirty = true;
  bool _actorLightDirty = true;
  bool _visibilityDirty = true;

  Lighting(Stage stage)
      : _stage = stage,
        _floorLight = new Array2D(stage.width, stage.height, 0),
        _actorLight = new Array2D(stage.width, stage.height, 0),
        _fov = new Fov(stage);

  void dirtyFloorLight() {
    _floorLightDirty = true;
  }

  void dirtyActorLight() {
    _actorLightDirty = true;
  }

  void dirtyVisibility() {
    _visibilityDirty = true;
  }

  void refresh() {
    if (_floorLightDirty) _lightFloor();
    if (_actorLightDirty) _lightActors();
    if (_visibilityDirty) _fov.refresh(_stage.game.hero.pos);

    if (_floorLightDirty || _actorLightDirty || _visibilityDirty) {
      _mergeLayers();
      _lightWalls();
      _updateExplored();
    }

    _floorLightDirty = false;
    _actorLightDirty = false;
    _visibilityDirty = false;
  }

  /// Recalculates [_floorLight] by propagating light from the emanating tiles
  /// and items on the ground.
  void _lightFloor() {
    _queue.reset();

    for (var y = 0; y < _stage.height; y++) {
      for (var x = 0; x < _stage.width; x++) {
        var pos = new Vec(x, y);
        var tile = _stage[pos];

        // Take the tile's light.
        var emanation = tile.emanation;

        // Add any light from items laying on the tile.
        for (var item in _stage.itemsAt(pos)) {
          if (item.emanationLevel == 0) continue;
          emanation += emanationForLevel(item.emanationLevel);
        }

        if (emanation > 0) {
          emanation = math.min(emanation, max);
          _floorLight.set(x, y, emanation);
          _queue.add(pos, emanation);
        } else {
          _floorLight[pos] = 0;
        }
      }
    }

    _process(_floorLight);
  }

  /// Recalculates [_actorLight] by propagating light from the emanating actors.
  void _lightActors() {
    _actorLight.fill(0);
    _queue.reset();

    for (var actor in _stage.actors) {
      var emanation = emanationForLevel(actor.emanationLevel);

      if (emanation > 0) {
        _actorLight[actor.pos] = emanation;
        _queue.add(actor.pos, emanation);
      }
    }

    _process(_actorLight);
  }

  /// Combines the light layers of opaque tiles into a single summed
  /// illumination value.
  ///
  /// This should be called after the layers have been updated.
  void _mergeLayers() {
    for (var y = 0; y < _stage.height; y++) {
      for (var x = 0; x < _stage.width; x++) {
        var tile = _stage.get(x, y);
        if (tile.blocksView) continue;

        tile.illumination =
            (_floorLight.get(x, y) + _actorLight.get(x, y)).clamp(0, max);
      }
    }
  }

  /// Illuminates opaque tiles based on the nearest transparent neighbor's
  /// illumination.
  ///
  /// This must be called after [_mergeLayers].
  void _lightWalls() {
    // Now that we've illuminated the transparent tiles, illuminate the opaque
    // tiles based on their nearest open neighbor's illumination.
    for (var y = 0; y < _stage.height; y++) {
      for (var x = 0; x < _stage.width; x++) {
        var tile = _stage.get(x, y);
        if (!tile.blocksView) continue;

        var illumination = 0;
        var openNeighbor = false;

        checkNeighbor(Vec offset) {
          // Not using Vec for math because that creates a lot of temporary
          // objects and this method is performance critical.
          var neighborX = x + offset.x;
          var neighborY = y + offset.y;

          if (neighborX < 0) return;
          if (neighborX >= _stage.width) return;
          if (neighborY < 0) return;
          if (neighborY >= _stage.height) return;

          var neighborTile = _stage.get(neighborX, neighborY);

          if (neighborTile.isOccluded) return;
          if (neighborTile.blocksView) return;

          openNeighbor = true;
          illumination = math.max(illumination, neighborTile.illumination);
        }

        // First, see if any of the cardinal neighbors are lit.
        for (var dir in Direction.cardinal) {
          checkNeighbor(dir);
        }

        // If so, we use their light. Only if not do we check the corners. This
        // makes the corners of room walls visible, but avoids overly lightening
        // walls that don't need to be because they aren't in corners.
        if (!openNeighbor) {
          for (var dir in Direction.intercardinal) {
            checkNeighbor(dir);
          }
        }

        tile.illumination = illumination;
      }
    }
  }

  void _updateExplored() {
    var numExplored = 0;
    for (var y = 0; y < _stage.height; y++) {
      for (var x = 0; x < _stage.width; x++) {
        numExplored += _stage.get(x, y).updateExplored();
      }
    }

    _stage.game.hero.explore(numExplored);
  }

  void _process(Array2D<int> tiles) {
    while (true) {
      var pos = _queue.removeNext();
      if (pos == null) break;

      var parentLight = tiles[pos];

      checkNeighbor(Vec dir, int attenuation) {
        var neighborPos = pos + dir;
        var neighborTile = _stage[neighborPos];

        // Don't illuminate opaque (we'll do this in a separate pass).
        if (neighborTile.blocksView) return;

        var illumination = parentLight - attenuation;

        // Don't revisit a tiles that are already as light as they should be.
        // We may actually revisit a tile if it is both directly lit (and thus
        // pre-emptively enqueued) *and* a nearby even brighter light is
        // brighter than its own direct illumination. That's OK. When that
        // happens, the second time we process the tile, nothing will happen.
        if (tiles[neighborPos] >= illumination) return;

        // Lighten the tile.
        tiles[neighborPos] = illumination;

        // If the neighbor is too dim for light to propagate from it, don't
        // bother enqueuing it.
        if (illumination <= _attenuate) return;

        // Check the tile's neighbors.
        _queue.add(neighborPos, illumination);
      }

      checkNeighbor(Direction.n, _attenuate);
      checkNeighbor(Direction.s, _attenuate);
      checkNeighbor(Direction.e, _attenuate);
      checkNeighbor(Direction.w, _attenuate);
      checkNeighbor(Direction.ne, _diagonalAttenuate);
      checkNeighbor(Direction.se, _diagonalAttenuate);
      checkNeighbor(Direction.nw, _diagonalAttenuate);
      checkNeighbor(Direction.sw, _diagonalAttenuate);
    }
  }
}

/// A priority queue to track which tiles still need to have their light
/// propagation processed.
///
/// Light propagation is halfway between a simple breadth-first search and the
/// full Dijkstra's algorithm. We can't use BFS because:
///
/// - Initial emanating tiles can have different brightness values.
/// - Light propagation does not always decrease by the same amount. Diagonal
///   neighbors attenuate faster than straight ones.
///
/// These two constraints mean that neighboring tiles are not strictly enqueued
/// in first-in-first-out order. We may need to enqueue a brighter neighbor tile
/// so that it is processed earlier than a previously-enqueued but dimmer tile.
///
/// We do make one simplification over Dijkstra's algorithm, though. When a
/// tile is enqueued, we do *not* check to see if the tile is already enqueued
/// and update it's priority if it is. This is a major slowdown of Dijkstra's
/// algorithm unless you use something clever like a Fibonacci heap.
///
/// Since we visit tiles from brightest to darkest, the only time a tile can
/// be queued more than once is if it was queued initially as an eminating tile
/// and then we discovered that there is another nearby emanation source bright
/// enough to beat the tile's own emanation.
///
/// In that case, we just let it be enqueued twice. The one we visit first will
/// be the brightest one (since we visit in brightness order), so we are
/// assured to propagate the right value. When we later visit the tile again,
/// it will note that none of its neighbors get any brighter and stop.
///
/// Also, we constrain light levels to an integer from [0, 255]. That lets us
/// use a [bucket queue] for the priority queue. That gives us very fast
/// constant time performance for all operations.
///
/// [bucket queue]: https://en.wikipedia.org/wiki/Bucket_queue
class _LightQueue {
  final List<Queue<Vec>> _buckets = new List(Lighting.max + 1);
  int _bucket = Lighting.max;

  void reset() {
    _bucket = Lighting.max;
  }

  void add(Vec pos, int brightness) {
    assert(brightness <= _bucket);

    var bucket = _buckets[brightness];
    if (bucket == null) {
      bucket = new Queue();
      _buckets[brightness] = bucket;
    }
    bucket.add(pos);
  }

  /// Removes the brightest element from the queue or returns `null` if the
  /// queue is empty.
  Vec removeNext() {
    // Advance past any empty buckets.
    while (_bucket >= 0 &&
        (_buckets[_bucket] == null || _buckets[_bucket].isEmpty)) {
      _bucket--;
    }

    // If we ran out of buckets, the queue is empty.
    if (_bucket < 0) return null;

    return _buckets[_bucket].removeFirst();
  }
}

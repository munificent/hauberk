library hauberk.engine.ai.flow;

import 'dart:collection';
import 'dart:math' as math;

import '../../util.dart';
import '../stage.dart';

/// A lazy, generic pathfinder.
///
/// It can be used to find the distance from a starting point to a goal, or
/// find the directions to reach the nearest goals meeting some predicate.
///
/// Internally, it lazily runs Dijkstra's algorithm. It only processes outward
/// as far as needed to answer the query. In practice, this means it often does
/// less than 10% of the iterations of a full eager Dijkstra's.
class Flow {
  static const _UNKNOWN = -2;
  static const _UNREACHABLE = -1;

  final Stage _stage;
  final Vec _target;
  final int _maxDistance;
  final bool _canOpenDoors;

  Array2D<int> _distances;

  /// The position of the array's top-level corner relative to the stage.
  Vec _offset;

  /// The cells whose neighbors still remain to be processed.
  final _open = new Queue<Vec>();

  /// The list of reachable cells that have been found so far, in order of
  /// increasing distance.
  ///
  /// Coordinates are local to [_distances], not the [Stage].
  final _found = <Vec>[];

  /// Gets the bounds of the [Flow] in stage coordinates.
  Rect get bounds => new Rect.posAndSize(_offset, _distances.size);

  Flow(this._stage, this._target, {int maxDistance, bool canOpenDoors})
      : _maxDistance = maxDistance,
        _canOpenDoors = canOpenDoors {
    var width;
    var height;

    if (_maxDistance == null) {
      // Inset by one since we can assume the edges are impassable.
      _offset = new Vec(1, 1);
      width = _stage.width - 2;
      height = _stage.height - 2;
    } else {
      var left = math.max(1, _target.x - _maxDistance);
      var top = math.max(1, _target.y - _maxDistance);
      var right = math.min(_stage.width - 1, _target.x + _maxDistance + 1);
      var bottom = math.min(_stage.height - 1, _target.y + _maxDistance + 1);
      _offset = new Vec(left, top);
      width = right - left;
      height = bottom - top;
    }

    _distances = new Array2D<int>.filled(width, height, _UNKNOWN);

    // Seed it with the starting position.
    _open.add(_target - _offset);
    _distances[_open.first] = 0;
  }

  /// Gets the distance from the starting position to [pos], or `null` if there
  /// is no path to it.
  int getDistance(Vec pos) {
    pos -= _offset;
    if (!_distances.bounds.contains(pos)) return null;

    // Lazily run Dijkstra's until we reach the tile in question or run out of
    // paths to try.
    while (_open.isNotEmpty && _distances[pos] == _UNKNOWN) _processNext();

    var distance = _distances[pos];
    if (distance == _UNKNOWN || distance == _UNREACHABLE) return null;
    return distance;
  }

  /// Chooses a random direction from [_target] that gets closer to [pos].
  Direction directionTo(Vec pos) {
    var directions = _directionsTo([pos - _offset]);
    if (directions.isEmpty) return Direction.NONE;
    return rng.item(directions);
  }

  /// Chooses a random direction from [_target] that gets closer to one of the
  /// nearest positions matching [predicate].
  ///
  /// Returns [Direction.NONE] if no matching positions were found.
  Direction directionToNearestWhere(bool predicate(Vec pos)) {
    var directions = directionsToNearestWhere(predicate);
    if (directions.isEmpty) return Direction.NONE;
    return rng.item(directions);
  }

  /// Find all directions from [_target] that get closer to one of the nearest
  /// positions matching [predicate].
  ///
  /// Returns an empty list if no matching positions were found.
  List<Direction> directionsToNearestWhere(bool predicate(Vec pos)) {
    var goals = _findAllNearestWhere(predicate);
    if (goals == null) return [];

    return _directionsTo(goals);
  }

  /// Get the positions closest to [_target] that meet [predicate].
  ///
  /// Only returns more than one position if there are multiple equidistance
  /// positions meeting the criteria. Returns an empty list if no valid
  /// positions are found. Returned positions are local to [_distances], not
  /// the [Stage].
  List<Vec> _findAllNearestWhere(bool predicate(Vec pos)) {
    var goals;

    var i = 0;
    var nearestDistance;
    for (var i = 0;; i++) {
      // Lazily find the next open tile.
      while (_open.isNotEmpty && i >= _found.length) _processNext();

      // If we flowed everywhere and didn't find anything, give up.
      if (_open.isEmpty && i >= _found.length) return [];

      var pos = _found[i];
      if (!predicate(pos + _offset)) continue;

      var distance = _distances[pos];

      // Since pos was from _found, it should be reachable.
      assert(distance >= 0);

      if (nearestDistance == null) {
        nearestDistance = distance;
        goals = [pos];
      } else if (distance == nearestDistance) {
        // If we're still finding goals at the same distance, include them.
        goals.add(pos);
      } else {
        // We hit a tile that's farther than a valid goal, so we can stop
        // looking.
        break;
      }
    }

    return goals;
  }

  /// Find all directions from [_target] that get closer to one of positions in
  /// [goals].
  ///
  /// Returns an empty list if none of the goals can be reached.
  List<Direction> _directionsTo(List<Vec> goals) {
    var walked = new Set<Vec>();
    var directions = new Set<Direction>();

    // Starting at [pos], recursively walk along all paths that proceed towards
    // [_target].
    walkBack(Vec pos) {
      if (walked.contains(pos)) return;
      walked.add(pos);

      for (var dir in Direction.ALL) {
        var here = pos + dir;
        if (!_distances.bounds.contains(here)) continue;

        if (here == _target - _offset) {
          // If this step reached the target, mark the direction of the step.
          directions.add(dir.rotate180);
        } else if (_distances[here] >= 0 &&
                   _distances[here] < _distances[pos]) {
          walkBack(here);
        }
      }
    }

    // Trace all paths from the goals back to the target.
    goals.forEach(walkBack);
    return directions.toList();
  }

  /// Runs one iteration of Dijkstra's algorithm.
  void _processNext() {
    // Should only call this while there's still work to do.
    assert(_open.isNotEmpty);

    var start = _open.removeFirst();
    var distance = _distances[start];

    // Update the neighbor's distances.
    for (var dir in Direction.ALL) {
      var here = start + dir;

      if (!_distances.bounds.contains(here)) continue;

      // Ignore tiles we've already reached.
      if (_distances[here] != _UNKNOWN) continue;

      // Can't reach impassable tiles.
      var tile = _stage[here + _offset];
      var canEnter = tile.isTraversable ||
                     (tile.isPassable && _canOpenDoors);

      // Can't walk through other actors.
      if (_stage.actorAt(here + _offset) != null) canEnter = false;

      if (!canEnter) {
        _distances[here] = _UNREACHABLE;
        continue;
      }

      _distances[here] = distance + 1;
      _open.add(here);
      _found.add(here);
    }
  }
}

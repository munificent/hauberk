library hauberk.engine.ai.flow;

import 'dart:collection';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../stage.dart';

/// A lazy, generic pathfinder.
///
/// It can be used to find the distance from a starting point to a goal, or
/// find the directions to reach the nearest goals meeting some predicate.
///
/// Internally, it lazily runs a breadth-first search. It only processes outward
/// as far as needed to answer the query. In practice, this means it often does
/// less than 10% of the iterations of a full eager search.
class Flow {
  static const _unknown = -2;
  static const _unreachable = -1;

  final Stage _stage;
  final Vec _start;
  final int _maxDistance;
  final bool _canOpenDoors;
  final bool _ignoreActors;

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

  /// Gets the starting position in stage coordinates.
  Vec get start => _start;

  Flow(this._stage, this._start, {int maxDistance, bool canOpenDoors,
        bool ignoreActors})
      : _maxDistance = maxDistance,
        _canOpenDoors = canOpenDoors != null ? canOpenDoors : false,
        _ignoreActors = ignoreActors {
    var width;
    var height;

    if (_maxDistance == null) {
      // Inset by one since we can assume the edges are impassable.
      _offset = new Vec(1, 1);
      width = _stage.width - 2;
      height = _stage.height - 2;
    } else {
      var left = math.max(1, _start.x - _maxDistance);
      var top = math.max(1, _start.y - _maxDistance);
      var right = math.min(_stage.width - 1, _start.x + _maxDistance + 1);
      var bottom = math.min(_stage.height - 1, _start.y + _maxDistance + 1);
      _offset = new Vec(left, top);
      width = right - left;
      height = bottom - top;
    }

    _distances = new Array2D<int>(width, height, _unknown);

    // Seed it with the starting position.
    _open.add(_start - _offset);
    _distances[_open.first] = 0;
  }

  /// Returns the nearest position to start that meets [predicate].
  ///
  /// If there are multiple equidistance positions, chooses one randomly. If
  /// there are none, returns the starting position.
  Vec nearestWhere(bool predicate(Vec pos)) {
    var results = _findAllNearestWhere(predicate);
    if (results.isEmpty) return _start;

    return rng.item(results) + _offset;
  }

  /// Gets the distance from the starting position to [pos], or `null` if there
  /// is no path to it.
  int getDistance(Vec pos) {
    pos -= _offset;
    if (!_distances.bounds.contains(pos)) return null;

    // Lazily search until we reach the tile in question or run out of paths to
    // try.
    while (_open.isNotEmpty && _distances[pos] == _unknown) _processNext();

    var distance = _distances[pos];
    if (distance == _unknown || distance == _unreachable) return null;
    return distance;
  }

  /// Chooses a random direction from [start] that gets closer to [pos].
  Direction directionTo(Vec pos) {
    var directions = _directionsTo([pos - _offset]);
    if (directions.isEmpty) return Direction.NONE;
    return rng.item(directions);
  }

  /// Chooses a random direction from [start] that gets closer to one of the
  /// nearest positions matching [predicate].
  ///
  /// Returns [Direction.NONE] if no matching positions were found.
  Direction directionToNearestWhere(bool predicate(Vec pos)) {
    var directions = directionsToNearestWhere(predicate);
    if (directions.isEmpty) return Direction.NONE;
    return rng.item(directions);
  }

  /// Find all directions from [start] that get closer to one of the nearest
  /// positions matching [predicate].
  ///
  /// Returns an empty list if no matching positions were found.
  List<Direction> directionsToNearestWhere(bool predicate(Vec pos)) {
    var goals = _findAllNearestWhere(predicate);
    if (goals == null) return [];

    return _directionsTo(goals);
  }

  /// Get the positions closest to [start] that meet [predicate].
  ///
  /// Only returns more than one position if there are multiple equidistance
  /// positions meeting the criteria. Returns an empty list if no valid
  /// positions are found. Returned positions are local to [_distances], not
  /// the [Stage].
  List<Vec> _findAllNearestWhere(bool predicate(Vec pos)) {
    var goals = <Vec>[];

    var nearestDistance;
    for (var i = 0;; i++) {
      // Lazily find the next open tile.
      while (_open.isNotEmpty && i >= _found.length) _processNext();

      // If we flowed everywhere and didn't find anything, give up.
      if (_open.isEmpty && i >= _found.length) return goals;

      var pos = _found[i];
      if (!predicate(pos + _offset)) continue;

      var distance = _distances[pos];

      // Since pos was from _found, it should be reachable.
      assert(distance >= 0);

      if (nearestDistance == null || distance == nearestDistance) {
        // Consider all goals at the nearest distance.
        nearestDistance = distance;
        goals.add(pos);
      } else {
        // We hit a tile that's farther than a valid goal, so we can stop
        // looking.
        break;
      }
    }

    return goals;
  }

  /// Find all directions from [start] that get closer to one of positions in
  /// [goals].
  ///
  /// Returns an empty list if none of the goals can be reached.
  List<Direction> _directionsTo(List<Vec> goals) {
    var walked = new Set<Vec>();
    var directions = new Set<Direction>();

    // Starting at [pos], recursively walk along all paths that proceed towards
    // [start].
    walkBack(Vec pos) {
      if (walked.contains(pos)) return;
      walked.add(pos);

      for (var dir in Direction.ALL) {
        var here = pos + dir;
        if (!_distances.bounds.contains(here)) continue;

        if (here == _start - _offset) {
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

  /// Runs one iteration of the search.
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
      if (_distances[here] != _unknown) continue;

      // Can't reach impassable tiles.
      var tile = _stage[here + _offset];
      var canEnter = tile.isPassable ||
                     (tile.isTraversable && _canOpenDoors);

      // Can't walk through other actors.
      if (!_ignoreActors &&
          _stage.actorAt(here + _offset) != null) canEnter = false;

      if (!canEnter) {
        _distances[here] = _unreachable;
        continue;
      }

      _distances[here] = distance + 1;
      _open.add(here);
      _found.add(here);
    }
  }

  /// Prints the distances array for debugging.
  /*
  void _dump() {
    var buffer = new StringBuffer();
    for (var y = 0; y < _distances.height; y++) {
      for (var x = 0; x < _distances.width; x++) {
        var distance = _distances.get(x, y);
        if (distance == _unknown) {
          buffer.write("?");
        } else if (distance == _unreachable) {
          buffer.write("#");
        } else {
          buffer.write(distance % 10);
        }
      }
      buffer.writeln();
    }

    print(buffer.toString());
  }
  */
}

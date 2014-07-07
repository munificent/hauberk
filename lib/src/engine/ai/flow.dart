library hauberk.engine.ai.flow;

import 'dart:collection';
import 'dart:math' as math;

import '../../util.dart';
import '../stage.dart';

class Flow {
  static const _MAX = 999999;

  final Stage _stage;
  final Vec _target;
  final int _maxDistance;

  Array2D<int> _distances;

  /// The position of the array's top-level corner relative to the stage.
  Vec _offset;

  /// The cells whose neighbors still remain to be processed.
  final _open = new Queue<Vec>();

  /// The list of reachable cells that have been found so far.
  ///
  /// Coordinates are local to [_values], not the [Stage].
  final _found = <Vec>[];

  Flow(this._stage, this._target, {int maxDistance, bool canOpenDoors})
      : _maxDistance = maxDistance {
    if (_maxDistance == null) {
      // Inset by one since we can assume the edges are impassable.
      _offset = new Vec(1, 1);
      _distances = new Array2D<int>.filled(_stage.width - 2, _stage.height - 2,
          _MAX);
    } else {
      var left = math.max(1, _target.x - _maxDistance);
      var top = math.max(1, _target.y - _maxDistance);
      var right = math.min(_stage.width - 1, _target.x + _maxDistance + 1);
      var bottom = math.min(_stage.height - 1, _target.y + _maxDistance + 1);
      _offset = new Vec(left, top);
      _distances = new Array2D<int>.filled(right - left, bottom - top, _MAX);
    }

    _open.add(_target - _offset);
    _distances[_open.first] = 0;
    _found.add(_target - _offset);

    // TODO: For now, just eagerly run Dijkstra's. If we change the open and
    // found collections to be a heap and sorted by distance respectively, we
    // can do this lazily.
    while (_open.isNotEmpty) {
      var start = _open.removeFirst();
      var distance = _distances[start];

      // Update the neighbor's distances.
      for (var dir in Direction.ALL) {
        var here = start + dir;

        if (!_distances.bounds.contains(here)) continue;

        // Can't reach impassable tiles.
        var tile = _stage[here + _offset];
        if (!tile.isTraversable) continue;
        if (!tile.isPassable && !canOpenDoors) continue;

        // Can't walk through actors.
        if (_stage.actorAt(here + _offset) != null) continue;

        // If we got a new best path to this tile, update its distance and
        // consider its neighbors later.
        if (_distances[here] > distance + 1) {
          _distances[here] = distance + 1;
          _open.add(here);
          _found.add(here);
        }
      }
    }

    _found.sort((a, b) => _distances[a].compareTo(_distances[b]));
  }

  /// Gets the distance from the starting position to [pos], or `null` if there
  /// is no path to it.
  int getDistance(Vec pos) {
    pos -= _offset;
    if (!_distances.bounds.contains(pos)) return null;
    var distance = _distances[pos];
    return distance == _MAX ? null : distance;
  }

  /// Find the reachable position nearest to the target that matches
  /// [predicate].
  ///
  /// Returns `null` if no matching position was found.
  Vec findNearestWhere(bool predicate(Tile tile)) {
    // TODO: Hack. Skipping one to not include target in result. Sometimes
    // that's desired sometimes it isn't.
    // TODO: If there are multiple equidistant ones, choose randomly?
    for (var pos in _found.skip(1)) {
      if (predicate(_stage[pos + _offset])) return pos + _offset;
    }

    return null;
  }

  /// Find the direction to walk on the path towards the nearest position
  /// matching [predicate].
  ///
  /// Returns [Direction.NONE] if no matching position was found.
  Direction directionToNearestWhere(bool predicate(Tile tile)) {
    var goal = findNearestWhere(predicate);
    if (goal == null) return Direction.NONE;

    // Walk the path back to the target.
    goal -= _offset;

    var lastDir;
    while (goal != _target - _offset) {
      // Find the directions that get closer to the starting point.
      var dirs = Direction.ALL.where((dir) {
        var here = goal - dir;
        if (!_distances.bounds.contains(here)) return false;
        return _distances[here] < _distances[goal];
      }).toList();

      lastDir = rng.item(dirs);
      goal -= lastDir;
    }

    return lastDir;
  }
}

import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';

/// An incrementally-updated bread-first search distance map.
///
/// Works basically like [Flow] except that when a tile is turned solid, only
/// the tiles that need to be updated are recalculated. This is much faster
/// when filling in passages during level generation.
class Reachability {
  static const _unknown = -2;
  static const _unreachable = -1;

  final Stage stage;
  final Vec _start;

  final Array2D<int> _distances;
  final VecSet _affected;

  /// The number of unfillable tiles that are currently reachable.
  int _reachedOpenCount = 0;
  int get reachedOpenCount => _reachedOpenCount;

  List<_FillStep> _beforeFill;

  Reachability(this.stage, this._start)
      : _distances = Array2D<int>(stage.width, stage.height, _unknown),
        _affected = VecSet(stage.width, stage.height) {
    _setDistance(_start, 0);
    _process([_start]);
  }

  bool isReachable(Vec pos) => _distances[pos] >= 0;

  int distanceAt(Vec pos) => _distances[pos];

  /// Mark the tile at [pos] as being solid and recalculate the distances of
  /// any affected tiles.
  void fill(Vec pos) {
    var queue = Queue<Vec>();
    _affected.clear();
    queue.add(pos);
    _affected.add(pos);

    _beforeFill = [_FillStep(pos, _distances[pos])];

    while (queue.isNotEmpty) {
      var pos = queue.removeFirst();
      var distance = _distances[pos];
      for (var neighbor in pos.cardinalNeighbors) {
        var neighborDistance = _distances[neighbor];
        if (neighborDistance == _unreachable) continue;

        // Ignore tiles that weren't reached from the parent tile.
        if (_distances[neighbor] != distance + 1) continue;

        // Don't get stuck in cycles.
        if (_affected.contains(neighbor)) continue;

        // Ignore tiles that we can get to from another path.
        if (_hasOtherPath(neighbor)) continue;

        queue.add(neighbor);
        _affected.add(neighbor);

        _beforeFill.add(_FillStep(neighbor, neighborDistance));
      }
    }

    // The starting tile is now blocked.
    _setDistance(pos, _unreachable);

    var border = _findBorder(pos);
    if (border.isEmpty) {
      // There are no other border tiles that are reachable, so the whole
      // affected area has been cut off.
      for (var pos in _affected) {
        _setDistance(pos, _unreachable);
      }
    } else {
      // Clear the distances for the affected tiles.
      for (var here in _affected) {
        _setDistance(here, _unknown);
      }

      _setDistance(pos, _unreachable);

      // Recalculate the affected tiles.
      _process(border);
    }
  }

  /// Revert the previous call to [fill].
  void undoFill() {
    for (var step in _beforeFill) {
      _setDistance(step.pos, step.distance);
    }

    _beforeFill = null;
  }

  // Returns true if there is a path to [pos] that doesn't go through an
  // affected tile.
  bool _hasOtherPath(Vec pos) {
    var distance = _distances[pos];
    for (var neighbor in pos.cardinalNeighbors) {
      if (!stage.bounds.contains(neighbor)) continue;

      // If there is an unaffected neighbor whose distance is one step shorter
      // that this one, we can go through that neighbor to get here.
      if (!_affected.contains(neighbor) &&
          _distances[neighbor] == distance - 1) {
        return true;
      }
    }

    return false;
  }

  /// Find all of the tiles around the affected tiles that do have a distance.
  /// We'll recalculate the affected tiles using paths from those.
  Set<Vec> _findBorder(Vec start) {
    var border = <Vec>{};
    for (var here in _affected) {
      // Don't consider the initial filled tile.
      // TODO: This is kind of hokey. Would be better to eliminate pos from
      // affected set.
      if (here == start) continue;

      for (var neighbor in here.cardinalNeighbors) {
        if (_distances[neighbor] >= 0 && !_affected.contains(neighbor)) {
          border.add(neighbor);
        }
      }
    }

    return border;
  }

  /// Update the distances of all unknown tiles reachable from [starting].
  void _process(Iterable<Vec> starting) {
    var frontier = BucketQueue<Vec>();

    for (var pos in starting) {
      frontier.add(pos, _distances[pos]);
    }

    while (true) {
      var pos = frontier.removeNext();
      if (pos == null) break;

      var parentDistance = _distances[pos];

      // Propagate to neighboring tiles.
      for (var here in pos.cardinalNeighbors) {
        if (!_distances.bounds.contains(here)) continue;

        // Ignore tiles we've already reached.
        if (_distances[here] != _unknown) continue;

        if (stage[here].isWalkable) {
          var distance = parentDistance + 1;
          _setDistance(here, distance);
          frontier.add(here, distance);
        } else {
          _setDistance(here, _unreachable);
        }
      }
    }
  }

  void _setDistance(Vec pos, int distance) {
    // If we're on an open tile, update the running count.
    if (stage[pos].type == Tiles.open) {
      if (_distances[pos] >= 0) _reachedOpenCount--;
      if (distance >= 0) _reachedOpenCount++;
    }

    _distances[pos] = distance;
  }
}

/// An atomic change to the distance map, so that it can be undone.
class _FillStep {
  final Vec pos;
  final int distance;

  _FillStep(this.pos, this.distance);
}

import 'package:piecemeal/piecemeal.dart';

import '../stage/bucket_queue.dart';
import '../stage/stage.dart';
import '../stage/tile.dart';

class Path {
  /// The direction of the first step along this path.
  ///
  /// If the monster chooses to take this path, this is which way it should walk
  /// next.
  final Direction startDirection;

  final Vec pos;

  final int length;

  /// The total cost spent to walk this path so far.
  final int cost;

  Path(this.startDirection, this.pos, this.length, this.cost);

  String toString() => "$startDirection pos:$pos cost:$cost";
}

/// An abstract class encapsulating the core A* search algorithm.
///
/// Subclasses of this fill in the cost, heuristics, and goal conditions.
///
/// Using jump point search would be nice because it's faster. However, it
/// assumes all tiles have a uniform cost to enter, which isn't the case for
/// us. Monster pathfinding treats things like door and occupied tiles as
/// accessible but expensive. Likewise, sound pathfinding treats doors as
/// blocking some but not all sound.
abstract class Pathfinder<T> {
  final Stage stage;
  final Vec start;
  final Vec end;

  Pathfinder(this.stage, this.start, this.end);

  /// Perform an A* search from [start] trying to reach [end].
  T search() {
    var paths = BucketQueue<Path>();

    // The set of tiles we have completely explored already.
    var explored = Set<Vec>();

    var startPath = Path(Direction.none, start, 0, 0);
    paths.add(startPath, priority(startPath, end));

    while (true) {
      var path = paths.removeNext();
      if (path == null) break;

      if (path.pos == end) return reachedGoal(path);

      // A given tile may get enqueued more than once because we don't check to
      // see if it's already been enqueued at a different cost. When that
      // happens, we will visit the best one first, which is what we want. That
      // means if we later visit the other one, we know it's worse and can just
      // skip it.
      //
      // While it seems weird to redundantly add the same tile to the priority
      // queue, in practice, it's faster than updating the priority of the
      // previously queued item.
      //
      // See: https://www.redblobgames.com/pathfinding/a-star/implementation.html#algorithm
      if (!explored.add(path.pos)) continue;

      var result = processStep(path);
      if (result != null) return result;

      // Find the steps we can take.
      for (var dir in Direction.all) {
        var neighbor = path.pos + dir;

        if (explored.contains(neighbor)) continue;
        if (!stage.bounds.contains(neighbor)) continue;

        var cost = stepCost(neighbor, stage[neighbor]);
        if (cost == null) continue;

        var newPath = Path(
            path.startDirection == Direction.none ? dir : path.startDirection,
            neighbor,
            path.length + 1,
            path.cost + cost);
        paths.add(newPath, priority(newPath, end));
      }
    }

    // If we get here, it means we definitively determined there is no path to
    // the goal.
    return unreachableGoal();
  }

  int priority(Path path, Vec end) {
    return path.cost + heuristic(path.pos, end);
  }

  /// The estimated cost from [pos] to [end].
  ///
  /// By default, uses the king length.
  int heuristic(Vec pos, Vec end) => (end - pos).kingLength;

  /// The cost required to enter [tile] at [pos] from a neighboring tile or
  /// `null` if the tile cannot be entered.
  int stepCost(Vec pos, Tile tile);

  /// Called for each step of pathfinding where [path] is the current path
  /// being processed.
  ///
  /// If the pathfinder wants to immediately stop processing and return a value,
  /// this should return a non-`null` value. Otherwise, return `null` and the
  /// pathfinder will continue.
  T processStep(Path path);

  /// Called when the pathfinder has found a [path] to the end point.
  ///
  /// Override this to return the desired value upon success.
  T reachedGoal(Path path);

  /// Called when the pathfinder determines it cannot reach the end point.
  ///
  /// Override this to return an appropriate failure value.
  T unreachableGoal();
}

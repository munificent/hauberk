import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../option.dart';
import '../stage.dart';

class PathResult {
  /// The direction to move on the first step of the path.
  final Direction direction;

  /// The total number of steps in the path.
  final int length;

  PathResult(this.direction, this.length);
}

/// A* pathfinding algorithm.
class AStar {
  /// Tries to find a path from [start] to [end], searching up to [maxLength]
  /// steps from [start]. Returns the [Direction] of the first step from [start]
  /// along that path (or [Direction.none] if it determines there is no path
  /// possible.
  static Direction findDirection(Stage stage, Vec start, Vec end,
      MotilitySet motilities, {int maxLength}) {
    var path = _findPath(stage, start, end, maxLength, motilities);
    if (path == null) return Direction.none;

    while (path.parent != null && path.parent.parent != null) {
      path = path.parent;
    }

    return path.direction;
  }

  static PathResult findPath(Stage stage, Vec start, Vec end,
      MotilitySet motilities, {int maxLength}) {
    var path = _findPath(stage, start, end, maxLength, motilities);
    if (path == null) return new PathResult(Direction.none, 0);

    var length = 1;
    while (path.parent != null && path.parent.parent != null) {
      path = path.parent;
      length++;
    }

    return new PathResult(path.direction, length);
  }

  static _PathNode _findPath(Stage stage, Vec start, Vec end, int maxLength,
      MotilitySet motilities) {
    // TODO: More optimal data structure.
    var startPath = new _PathNode(null, Direction.none,
        start, 0, heuristic(start, end));
    var open = <_PathNode>[startPath];
    var closed = new Set<Vec>();

    while (open.length > 0) {
      // Pull out the best potential candidate.
      var current = open.removeLast();

      if ((current.pos == end) ||
          (current.cost > Option.aStarFloorCost * maxLength)) {
        // Found the path.
        return current;
      }

      closed.add(current.pos);

      for (var dir in Direction.all) {
        var neighbor = current.pos + dir;

        // Skip impassable tiles.
        var tile = stage[neighbor];

        // Don't handle doors here. We'll handle those specially below because
        // even monsters that can't open doors may still try to pathfind through
        // them.
        if (!tile.canEnter(Motility.door) && !tile.canEnterAny(motilities)) {
          continue;
        }

        // Given how far the current tile is, how far is each neighbor?
        var stepCost = Option.aStarFloorCost;
        if (neighbor == end) {
          // This is our destination, so it's definitely the best step.
          stepCost = 0;
        } else if (stage[neighbor].type.opensTo != null) {
          if (motilities.contains(Motility.door)) {
            // One to open the door and one to enter the tile.
            stepCost = Option.aStarFloorCost * 2;
          } else {
            // Even though the monster can't open doors, we don't consider it
            // totally impassable because there's a chance the door will be
            // opened by someone else (like the hero).
            stepCost = Option.aStarDoorCost;
          }
        } else if (stage.actorAt(neighbor) != null) {
          stepCost = Option.aStarOccupiedCost;
        }

        var cost = current.cost + stepCost;

        // See if we just found a better path to a tile we're already
        // considering. If so, remove the old one and replace it (below) with
        // this new better path.
        var inOpen = false;

        for (var i = 0; i < open.length; i++) {
          var alreadyOpen = open[i];
          if (alreadyOpen.pos == neighbor) {
            if (alreadyOpen.cost > cost) {
              open.removeAt(i);
              i--;
            } else {
              inOpen = true;
            }
            break;
          }
        }

        var inClosed = closed.contains(neighbor);

        // If we have a new path, add it.
        if (!inOpen && !inClosed) {
          var guess = cost + heuristic(neighbor, end);
          var path = new _PathNode(current, dir, neighbor, cost, guess);

          // Insert it in sorted order (such that the best node is at the *end*
          // of the list for easy removal).
          var inserted = false;
          for (var i = open.length - 1; i >= 0; i--) {
            if (open[i].guess > guess) {
              open.insert(i + 1, path);
              inserted = true;
              break;
            }
          }

          // If we didn't find a node to put it after, put it at the front.
          if (!inserted) open.insert(0, path);
        }
      }
    }

    // No path.
    return null;
  }

  /// The estimated cost from [pos] to [end].
  static int heuristic(Vec pos, Vec end) {
    // A simple heuristic would just be the kingLength. The problem is that
    // diagonal moves are as "fast" as straight ones, which means many
    // zig-zagging paths are as good as one that looks "straight" to the player.
    // But they look wrong. To avoid this, we will estimate straight steps to
    // be a little cheaper than diagonal ones. This avoids paths like:
    //
    // ...*...
    // s.*.*.g
    // .*...*.
    final offset = (end - pos).abs();
    final numDiagonal = math.min(offset.x, offset.y);
    final numStraight = math.max(offset.x, offset.y) - numDiagonal;
    return (numDiagonal * Option.aStarFloorCost) +
           (numStraight * Option.aStarStraightCost);
  }
}

class _PathNode {
  final _PathNode parent;
  final Direction direction;
  final Vec pos;

  /// The cost to get to this node from the starting point. This is roughly the
  /// distance, but may be a little different if we start weighting tiles in
  /// interesting ways (i.e. make it more expensive for light-abhorring
  /// monsters to walk through lit tiles).
  final int cost;

  /// The guess as to the total cost from the start node to the end node going
  /// along this path. In other words, this is [cost] plus the heuristic.
  final int guess;

  _PathNode(this.parent, this.direction, this.pos, this.cost, this.guess);
}

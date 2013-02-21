part of engine;

class AStarResult {
  final PathNode path;
  final List<Vec> closed;
  final List<PathNode> open;

  AStarResult(this.path, this.closed, this.open);
}

/// A* pathfinding algorithm.
class AStar {
  static final FLOOR_COST = 10;
  static final MONSTER_COST = 40;
  static final STRAIGHT_STEP_COST = 9;

  /// Tries to find a path from [start] to [end], searching up to [maxLength]
  /// steps from [start]. Returns the [Direction] of the first step from [start]
  /// along that path (or [Direction.NONE] if it determines there is no path
  /// possible.
  static Direction findDirection(Stage stage, Vec start, Vec end, int maxLength,
      bool canOpenDoors) {
    final result = findPath(stage, start, end, maxLength, canOpenDoors);
    if (result == null) return Direction.NONE;

    var path = result.path;
    while (path.parent != null && path.parent.parent != null) {
      path = path.parent;
    }

    return path.direction;
  }

  static AStarResult findPath(Stage stage, Vec start, Vec end, int maxLength,
      bool canOpenDoors) {
    // TODO(bob): More optimal data structure.
    final startPath = new PathNode(null, Direction.NONE,
        start, 0, heuristic(start, end));
    final open = <PathNode>[startPath];

    // TODO(bob): More optimal data structure.
    final closed = <Vec>[];

    while (open.length > 0) {
      // Pull out the best potential candidate.
      final current = open.removeLast();

      if ((current.pos == end) ||
          (current.cost > Option.ASTAR_FLOOR_COST * maxLength)) {
        // Found the path.
        return new AStarResult(current, closed, open);
      }

      closed.add(current.pos);

      for (final dir in Direction.ALL) {
        final neighbor = current.pos + dir;

        // Skip impassable tiles.
        if (!stage[neighbor].isTraversable) continue;

        // Given how far the current tile is, how far is each neighbor?
        var stepCost = Option.ASTAR_FLOOR_COST;
        if (stage[neighbor].type.opensTo != null) {
          if (canOpenDoors) {
            // One to open the door and one to enter the tile.
            stepCost = Option.ASTAR_FLOOR_COST * 2;
          } else {
            // Even though the monster can't open doors, we don't consider it
            // totally impassable because there's a chance the door will be
            // opened by someone else.
            stepCost = Option.ASTAR_DOOR_COST;
          }
        } else if (stage.actorAt(neighbor) != null) {
          stepCost = Option.ASTAR_OCCUPIED_COST;
        }

        final cost = current.cost + stepCost;

        // See if we just found a better path to a tile we're already
        // considering. If so, remove the old one and replace it (below) with
        // this new better path.
        bool inOpen = false;
        bool inClosed = false;

        for (var i = 0; i < open.length; i++) {
          final alreadyOpen = open[i];
          if (alreadyOpen.pos == neighbor) {
            if (alreadyOpen.cost > cost) {
              open.removeRange(i, 1);
              i--;
            } else {
              inOpen = true;
            }
            break;
          }
        }

        for (final alreadyClosed in closed) {
          if (alreadyClosed == neighbor) {
            inClosed = true;
            break;
          }
        }

        // TODO(bob): May need to do the above check on the closed set too if
        // we use inadmissable heuristics.

        // If we have a new path, add it.
        if (!inOpen && !inClosed) {
          final guess = cost + heuristic(neighbor, end);
          final path = new PathNode(current, dir, neighbor, cost, guess);

          // Insert it in sorted order (such that the best node is at the *end*
          // of the list for easy removal).
          bool inserted = false;
          for (var i = open.length - 1; i >= 0; i--) {
            if (open[i].guess > guess) {
              open.insertRange(i + 1, 1, path);
              inserted = true;
              break;
            }
          }

          // If we didn't find a node to put it after, put it at the front.
          if (!inserted) open.insertRange(0, 1, path);
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
    return (numDiagonal * Option.ASTAR_FLOOR_COST) +
           (numStraight * Option.ASTAR_STRAIGHT_COST);
  }
}

class PathNode {
  final PathNode parent;
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

  PathNode(this.parent, this.direction, this.pos, this.cost, this.guess);
}
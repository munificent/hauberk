import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../stage/pathfinder.dart';
import '../stage/stage.dart';
import '../stage/tile.dart';
import 'monster.dart';

class MonsterPathfinder extends Pathfinder<Direction> {
  /// When calculating pathfinding, how much it "costs" to move one step on
  /// an open floor tile.
  static const _floorCost = 10;

  /// When calculating pathfinding, how much it costs to move one step on a
  /// tile already occupied by an actor. For pathfinding, we consider occupied
  /// tiles as accessible but expensive. The idea is that by the time the
  /// pathfinding monster gets there, the occupier may have moved, so the tile
  /// is "sorta" empty, but still not as desirable as an actually empty tile.
  static const _occupiedCost = 60;

  /// When calculating pathfinding, how much it costs to cross a closed door.
  /// Instead of considering them completely impassable, we just have them be
  /// expensive, because it still may be beneficial for the monster to get
  /// closer to the door (for when the hero opens it later).
  static const _doorCost = 80;

  /// Diagonal steps are considered a little more expensive than straight ones
  /// so that monsters avoid zig-zagging paths when a straighter path is
  /// available.
  static const _diagonalCost = 11;

  static Direction findDirection(Stage stage, Monster monster) {
    return MonsterPathfinder(stage, monster).search();
  }

  final Monster _monster;
  Path _nearest;

  MonsterPathfinder(Stage stage, this._monster)
      : super(stage, _monster.pos, stage.game.hero.pos);

  Direction processStep(Path path) {
    if (_nearest == null ||
        heuristic(path.pos, end) < heuristic(_nearest.pos, end)) {
      _nearest = path;
    }

    if (path.length >= _monster.breed.tracking) {
      return _nearest.startDirection;
    }

    return null;
  }

  /// A simple heuristic would just be the kingLength. The problem is that
  /// diagonal moves are as "fast" as straight ones, which means many
  /// zig-zagging paths are as good as one that looks "straight" to the player.
  /// But they look wrong. To avoid this, we will estimate straight steps to
  /// be a little cheaper than diagonal ones. This avoids paths like:
  ///
  ///     ...*...
  ///     s.*.*.g
  ///     .*...*.
  int heuristic(Vec pos, Vec end) {
    var offset = (end - pos).abs();
    var diagonal = math.min(offset.x, offset.y);
    var straight = math.max(offset.x, offset.y) - diagonal;
    return straight * _floorCost + diagonal * _diagonalCost;
  }

  int stepCost(Vec pos, Tile tile) {
    // TODO: Take illumination into account for monsters that dislike light or
    // darkness.
    var firstStep = (pos - start).kingLength == 1;

    // Pathfind around other actors. We assume here that the monster AI does
    // not apply pathfinding when already next to the hero. Otherwise, this
    // will prevent them from actually attacking.
    if (stage.actorAt(pos) != null) {
      // Don't make a first step directly onto an actor.
      if (firstStep) return null;

      // But if it's elsewhere along the path, don't consider the tile totally
      // blocked. By the time we get there, there's a good chance the actor
      // will have moved. This prevents monsters from giving up as soon as one
      // monster enters a doorway.
      return _occupiedCost;
    }

    // Handle closed doors specially.
    if (tile.isClosedDoor) {
      if (_monster.motilities.contains(Motility.door)) {
        // One to open the door and one to enter the tile.
        return _floorCost * 2;
      } else if (firstStep) {
        // Can't open the door.
        return null;
      } else {
        // Even though the monster can't open the door, we don't consider it
        // totally impassable because there's a chance the door will be
        // opened by someone else (like the hero).
        return _doorCost;
      }
    }

    if (tile.canEnterAny(_monster.motilities)) return _floorCost;

    // TODO: Don't enter substances unless immune. Monsters shouldn't walk into
    // fire!

    // Can't go here.
    return null;
  }

  Direction reachedGoal(Path path) => path.startDirection;

  /// There's no path to the goal so, just pick the path that gets nearest to
  /// it and hope for the best. (Maybe someone will open a door later or
  /// something.)
  Direction unreachableGoal() => _nearest.startDirection;
}

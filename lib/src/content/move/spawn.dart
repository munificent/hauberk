import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/spawn.dart';

/// Spawns a new [Monster] of the same [Breed] adjacent to this one.
class SpawnMove extends Move {
  final bool _preferStraight;

  SpawnMove(super.rate, {bool? preferStraight})
      : _preferStraight = preferStraight ?? false;

  @override
  num get experience => 6.0;

  @override
  bool shouldUse(Game game, Monster monster) {
    // Don't breed offscreen since it can end up filling the room before the
    // hero gets there.
    if (!game.stage.isVisibleToHero(monster)) return false;

    // Look for an open adjacent tile.
    for (var neighbor in monster.pos.neighbors) {
      if (game.stage.willEnter(neighbor, monster.motility)) return true;
    }

    return false;
  }

  @override
  Action onGetAction(Game game, Monster monster) {
    // Pick an open adjacent tile.
    var dirs = <Direction>[];

    // If we want to spawn in straight-ish lines, bias the directions towards
    // ones that continue existing lines.
    if (_preferStraight) {
      for (var dir in Direction.all) {
        if (!game.stage.willEnter(monster.pos + dir, monster.motility)) {
          continue;
        }

        bool checkNeighbor(Direction neighbor) {
          var other = game.stage.actorAt(monster.pos + dir);
          return other != null &&
              other is Monster &&
              other.breed == monster.breed;
        }

        if (checkNeighbor(dir.rotate180)) {
          dirs.addAll([dir, dir, dir, dir, dir]);
        }

        if (checkNeighbor(dir.rotate180.rotateLeft45)) {
          dirs.add(dir);
        }

        if (checkNeighbor(dir.rotate180.rotateRight45)) {
          dirs.add(dir);
        }
      }
    }

    if (dirs.isEmpty) {
      for (var dir in Direction.all) {
        if (!game.stage.willEnter(monster.pos + dir, monster.motility)) {
          continue;
        }

        dirs.add(dir);
      }
    }

    return SpawnAction(monster.pos + rng.item(dirs), monster.breed);
  }

  @override
  String toString() => "Spawn rate: $rate";
}

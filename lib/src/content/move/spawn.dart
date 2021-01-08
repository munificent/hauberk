import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/spawn.dart';

/// Spawns a new [Monster] of the same [Breed] adjacent to this one.
class SpawnMove extends Move {
  final bool _preferStraight;

  SpawnMove(num rate, {bool preferStraight})
      : _preferStraight = preferStraight ?? false,
        super(rate);

  num get experience => 6.0;

  bool shouldUse(Monster monster) {
    // Don't breed offscreen since it can end up filling the room before the
    // hero gets there.
    if (!monster.isVisibleToHero) return false;

    // Look for an open adjacent tile.
    for (var neighbor in monster.pos.neighbors) {
      if (monster.willEnter(neighbor)) return true;
    }

    return false;
  }

  Action onGetAction(Monster monster) {
    // Pick an open adjacent tile.
    var dirs = <Direction>[];

    // If we want to spawn in straight-ish lines, bias the directions towards
    // ones that continue existing lines.
    if (_preferStraight) {
      for (var dir in Direction.all) {
        if (!monster.willEnter(monster.pos + dir)) continue;

        bool checkNeighbor(Direction neighbor) {
          var other = monster.game.stage.actorAt(monster.pos + dir);
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
        if (!monster.willEnter(monster.pos + dir)) continue;
        dirs.add(dir);
      }
    }

    return SpawnAction(monster.pos + rng.item(dirs), monster.breed);
  }

  String toString() => "Spawn rate: $rate";
}

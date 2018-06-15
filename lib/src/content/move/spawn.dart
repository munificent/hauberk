import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/spawn.dart';

/// Spawns a new [Monster] of the same [Breed] adjacent to this one.
class SpawnMove extends Move {
  SpawnMove(num rate) : super(rate);

  num get experience => 6.0;

  bool shouldUse(Monster monster) {
    // Don't breed offscreen since it can end up filling the room before the
    // hero gets there.
    if (!monster.isVisibleToHero) return false;

    // Look for an open adjacent tile.
    for (var dir in Direction.all) {
      var here = monster.pos + dir;
      if (monster.canOccupy(here) && monster.game.stage.actorAt(here) == null)
        return true;
    }

    return false;
  }

  Action onGetAction(Monster monster) {
    // Pick an open adjacent tile.
    var dirs = Direction.all.where((dir) {
      var here = monster.pos + dir;
      return monster.canOccupy(here) &&
          monster.game.stage.actorAt(here) == null;
    }).toList();

    return new SpawnAction(monster.pos + rng.item(dirs), monster.breed);
  }

  String toString() => "Spawn rate: $rate";
}

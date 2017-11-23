import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// Spawns a new [Monster] of a given [Breed].
class SpawnAction extends Action {
  final Vec _pos;
  final Breed _breed;

  SpawnAction(this._pos, this._breed);

  ActionResult onPerform() {
    // There's a chance the move will do nothing (except burn charge) based on
    // the monster's generation. This is to keep breeders from filling the
    // dungeon.
    if (!rng.oneIn(monster.generation)) return ActionResult.success;

    // Increase the generation on the spawner too so that its rate decreases
    // over time.
    monster.generation++;

    var spawned = _breed.spawn(game, _pos, actor);
    game.stage.addActor(spawned);

    addEvent(EventType.spawn, actor: spawned);

    // TODO: Message?
    return ActionResult.success;
  }
}

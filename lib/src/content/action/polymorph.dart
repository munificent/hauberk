import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

// TODO: Use this for more things.
// - Monsters that have a "final form" when killed.
// - Werewolves and other shapeshifters.
/// Turns the monster into [Breed].
class PolymorphAction extends Action {
  final Breed _breed;

  PolymorphAction(this._breed);

  @override
  ActionResult onPerform() {
    monster.breed = _breed;
    addEvent(EventType.polymorph, actor: actor);

    // TODO: Message?
    return ActionResult.success;
  }
}

/// "Amputates" part of the monster by spawning a new one for the part and
/// polymorphing the original into a different breed that lacks the part.
class AmputateAction extends Action {
  final Breed _bodyBreed;
  final Breed _partBreed;
  final String _message;

  AmputateAction(this._bodyBreed, this._partBreed, this._message);

  @override
  ActionResult onPerform() {
    // Hack off the part.
    addAction(PolymorphAction(_bodyBreed));

    log(_message, actor);

    // Pick an open adjacent tile.
    var positions = <Vec>[];
    for (var dir in Direction.all) {
      var pos = actor!.pos + dir;
      if (game.stage.canEnter(pos, _partBreed.motility)) positions.add(pos);
    }

    // If there's no room for the part, it disappears.
    if (positions.isNotEmpty) {
      // Create the part.
      var part = _partBreed.spawn(rng.item(positions), monster);
      part.awaken();
      game.stage.addActor(part);

      // TODO: Different event?
      addEvent(EventType.spawn, actor: part);
    }

    return ActionResult.success;
  }
}

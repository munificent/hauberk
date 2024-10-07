import 'package:piecemeal/piecemeal.dart';

import '../core/actor.dart';
import '../core/game.dart';
import '../hero/hero.dart';
import '../stage/sound.dart';
import '../stage/tile.dart';
import 'action.dart';
import 'attack.dart';

class WalkAction extends Action {
  final Direction _dir;

  WalkAction(this._dir);

  @override
  ActionResult onPerform() {
    // Rest if we aren't moving anywhere.
    if (_dir == Direction.none) {
      return alternate(RestAction());
    }

    var pos = actor!.pos + _dir;

    // See if there is an actor there.
    var target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      return alternate(AttackAction(target));
    }

    // If the tile is a closed door and the actor can open it, or the tile can't
    // be entered at all but can be operated, then try to operate it.
    //
    // We don't operate it unconditionally because we don't want to close open
    // doors when walking through them.
    var tile = game.stage[pos].type;
    if (tile.canOperate) {
      if (tile.motility == Motility.door &&
              actor!.motility.overlaps(Motility.door) ||
          !tile.canEnter(actor!.motility)) {
        return alternate(tile.onOperate!(pos));
      }
    }

    // See if we can walk there.
    if (!actor!.canOccupy(pos)) {
      // If the hero runs into something in the dark, they can figure out what
      // it is.
      if (actor is Hero) {
        game.stage.explore(pos, force: true);
      }

      return fail('{1} hit[s] the ${tile.name}.', actor);
    }

    actor!.pos = pos;

    // See if the hero stepped on anything interesting.
    if (actor is Hero) {
      for (var item in game.stage.itemsAt(pos).toList()) {
        hero.disturb();

        // Treasure is immediately, freely acquired.
        if (item.isTreasure) {
          // Pick a random value near the price.
          var min = (item.price * 0.5).ceil();
          var max = (item.price * 1.5).ceil();
          var value = rng.range(min, max);
          hero.gold += value;
          log("{1} pick[s] up {2} worth $value gold.", hero, item);
          game.stage.removeItem(item, pos);

          addEvent(EventType.gold, actor: actor, pos: actor!.pos, other: item);
        } else {
          log('{1} [are|is] standing on {2}.', actor, item);
        }
      }

      hero.regenerateFocus(4);
    }

    return succeed();
  }

  @override
  String toString() => '$actor walks $_dir';
}

class OpenDoorAction extends Action {
  final Vec pos;
  final TileType openDoor;

  OpenDoorAction(this.pos, this.openDoor);

  @override
  ActionResult onPerform() {
    game.stage[pos].type = openDoor;
    game.stage.tileOpacityChanged();

    if (actor is Hero) hero.regenerateFocus(4);
    return succeed('{1} open[s] the door.', actor);
  }
}

class CloseDoorAction extends Action {
  final Vec doorPos;
  final TileType closedDoor;

  CloseDoorAction(this.doorPos, this.closedDoor);

  @override
  ActionResult onPerform() {
    var blockingActor = game.stage.actorAt(doorPos);
    if (blockingActor != null) {
      return fail("{1} [are|is] in the way!", blockingActor);
    }

    // TODO: What should happen if items are on the tile?
    game.stage[doorPos].type = closedDoor;
    game.stage.tileOpacityChanged();

    if (actor is Hero) hero.regenerateFocus(4);
    return succeed('{1} close[s] the door.', actor);
  }
}

/// Action for doing nothing for a turn.
class RestAction extends Action {
  @override
  ActionResult onPerform() {
    switch (actor) {
      case Hero hero:
        // Always digesting.
        if (hero.stomach > 0) {
          hero.stomach--;
          if (hero.stomach == 0) game.log.message("You are getting hungry.");

          if (!hero.poison.isActive) {
            // TODO: Does this scale well when the hero has very high max
            // health? Might need to go up by more than one point then.
            hero.health++;
          }
        }

        // TODO: Have this amount increase over successive resting turns?
        hero.regenerateFocus(10);
      case Actor actor when !actor.isVisibleToHero && !actor.poison.isActive:
        // Monsters can rest if out of sight.
        actor.health++;
    }

    return succeed();
  }

  @override
  double get noise => Sound.restNoise;
}

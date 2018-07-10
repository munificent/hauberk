import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import 'attack.dart';
import '../core/game.dart';
import '../hero/hero.dart';
import '../stage/sound.dart';
import '../stage/tile.dart';

class WalkAction extends Action {
  final Direction dir;
  final bool _isRunning;

  WalkAction(this.dir, {bool running = false}) : _isRunning = running;

  ActionResult onPerform() {
    // Rest if we aren't moving anywhere.
    if (dir == Direction.none) {
      return alternate(RestAction());
    }

    var pos = actor.pos + dir;

    // See if there is an actor there.
    final target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      return alternate(AttackAction(target));
    }

    // See if it can be opened.
    var tile = game.stage[pos].type;
    if (tile.canOpen) {
      return alternate(tile.onOpen(pos));
    }

    // See if we can walk there.
    if (!actor.canOccupy(pos)) {
      // If the hero runs into something in the dark, they can figure out what
      // it is.
      if (actor is Hero) {
        game.stage.explore(pos, force: true);
      }

      return fail('{1} hit[s] the ${tile.name}.', actor);
    }

    actor.pos = pos;

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

          addEvent(EventType.gold, actor: actor, pos: actor.pos, other: item);
        } else {
          log('{1} [are|is] standing on {2}.', actor, item);
        }
      }

      // If we ran next to an item, note it and disturb. That way we stop where
      // the player can see it more easily.
      if (_isRunning) {
        for (var neighborDir in [dir.rotateLeft45, dir, dir.rotateRight45]) {
          var neighbor = pos + neighborDir;
          for (var item in hero.game.stage.itemsAt(neighbor)) {
            hero.disturb();
            hero.game.log.message('{1} [are|is] are next to {2}.', hero, item);
          }
        }
      }

      hero.focus += 2;
    }

    return succeed();
  }

  String toString() => '$actor walks $dir';
}

class OpenDoorAction extends Action {
  final Vec pos;
  final TileType openDoor;

  OpenDoorAction(this.pos, this.openDoor);

  ActionResult onPerform() {
    game.stage[pos].type = openDoor;
    game.stage.tileOpacityChanged();

    return succeed('{1} open[s] the door.', actor);
  }
}

class CloseDoorAction extends Action {
  final Vec doorPos;
  final TileType closedDoor;

  CloseDoorAction(this.doorPos, this.closedDoor);

  ActionResult onPerform() {
    var blockingActor = game.stage.actorAt(doorPos);
    if (blockingActor != null) {
      return fail("{1} [are|is] in the way!", blockingActor);
    }

    // TODO: What should happen if items are on the tile?
    game.stage[doorPos].type = closedDoor;
    game.stage.tileOpacityChanged();

    return succeed('{1} close[s] the door.', actor);
  }
}

/// Action for doing nothing for a turn.
class RestAction extends Action {
  ActionResult onPerform() {
    if (actor is Hero) {
      if (hero.stomach > 0 && !hero.poison.isActive) {
        // TODO: Does this scale well when the hero has very high max health?
        // Might need to go up by more than one point then.
        hero.health++;
      }

      // TODO: Have this amount increase over successive resting turns?
      // TODO: What should affect this rate?
      // TODO: Can the hero regain focus when hungry?
      hero.focus += 10;
    } else if (!actor.isVisibleToHero) {
      // Monsters can rest if out of sight.
      actor.health++;
    }

    return succeed();
  }

  double get noise => Sound.restNoise;
}

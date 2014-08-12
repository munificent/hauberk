library hauberk.engine.action.slash;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../game.dart';
import '../option.dart';

/// A sweeping melee attack that hits three adjacent tiles.
class SlashAction extends Action {
  final Direction _dir;
  int _step = 0;

  SlashAction(this._dir) {
    if (_dir == Direction.NONE) throw "!";
  }

  ActionResult onPerform() {
    var dir;
    switch (_step ~/ 6) {
      case 0: dir = _dir.rotateLeft45; break;
      case 1: dir = _dir; break;
      case 2: dir = _dir.rotateRight45; break;
    }

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % 2 == 0) {
      addEvent(EventType.SLASH, pos: actor.pos + dir, dir: dir);
    } else if (_step % 2 == 1) {
      var defender = game.stage.actorAt(actor.pos + dir);
      if (defender != null) {
        var attack = actor.getAttack(defender);

        // A slash is weaker than a regular attack.
        // TODO: If we make this consume fury, it can be as strong, or stronger
        // than a normal attack.
        attack.multiplyDamage(0.5);
        attack.perform(this, actor, defender);
      }
    }

    _step++;
    return _step == 6 * 3 ? ActionResult.SUCCESS : ActionResult.NOT_DONE;
  }

  int get noise => Option.NOISE_HIT;

  String toString() => '$actor slashes $_dir';
}

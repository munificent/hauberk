import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../skills.dart';
import 'mastery.dart';

class AxeMastery extends MasterySkill {
  String get name => "Axe Mastery";
  String get weaponType => "axe";

  Command get command => new SlashCommand();
}

/// A slashing melee attack that hits a number of adjacent monsters.
class SlashCommand extends MasteryCommand implements DirectionCommand {
  String get name => "Slash";
  String get weaponType => "axe";

  Action getDirectionAction(Game game, Direction dir) {
    // TODO: Tune.
    var scale =
        lerpDouble(game.hero.skills[Skills.axeMastery], 1, 20, 0.2, 0.7);
    return new SlashAction(dir, scale);
  }
}

/// A sweeping melee attack that hits three adjacent tiles.
class SlashAction extends MasteryAction {
  /// How many frames it pauses between each step of the swing.
  static const _frameRate = 5;

  final Direction _dir;
  int _step = 0;

  SlashAction(this._dir, double damageScale) : super(damageScale);

  ActionResult onPerform() {
    var dir;
    switch (_step ~/ _frameRate) {
      case 0:
        dir = _dir.rotateLeft45;
        break;
      case 1:
        dir = _dir;
        break;
      case 2:
        dir = _dir.rotateRight45;
        break;
    }

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % 2 == 0) {
      addEvent(EventType.slash, pos: actor.pos + dir, dir: dir);
    } else if (_step % 2 == 1) {
      attack(actor.pos + dir);
    }

    _step++;
    return doneIf(_step == _frameRate * 3);
  }

  String toString() => '$actor slashes $_dir';
}

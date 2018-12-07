import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import 'mastery.dart';

/// A slashing melee attack that hits a number of adjacent monsters.
class AxeMastery extends MasteryDiscipline implements DirectionSkill {
  // TODO: Tune.
  static double _slashScale(int level) => lerpDouble(level, 1, 10, 0.5, 1.5);

  // TODO: Better name.
  String get name => "Axe Mastery";
  String get useName => "Axe Sweep";

  String get description =>
      "Axes are not just for woodcutting. In the hands of a skilled user, "
      "they can cut down a swath of nearby foes as well.";
  String get weaponType => "axe";

  String levelDescription(int level) {
    var damage = (_slashScale(level) * 100).toInt();
    return super.levelDescription(level) +
        " Slash attacks inflict $damage% of the damage of a regular attack.";
  }

  Action getDirectionAction(Game game, int level, Direction dir) {
    return SlashAction(dir, AxeMastery._slashScale(level));
  }
}

/// A sweeping melee attack that hits three adjacent tiles.
class SlashAction extends MasteryAction {
  /// How many frames it pauses between each step of the swing.
  static const _frameRate = 5;

  final Direction _dir;
  int _step = 0;

  bool get isImmediate => false;

  SlashAction(this._dir, double damageScale) : super(damageScale);

  ActionResult onPerform() {
    // Make sure there is room to swing it.
    if (_step == 0) {
      for (var dir in [_dir.rotateLeft45, _dir, _dir.rotateRight45]) {
        var pos = actor.pos + dir;
        if (!game.stage[pos].canEnter(Motility.fly)) {
          var weapon = hero.equipment.weapon.type.name;
          return fail("There isn't enough room to swing your $weapon.");
        }
      }
    }

    Direction dir;
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

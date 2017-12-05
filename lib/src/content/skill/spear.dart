import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'mastery.dart';

class SpearMastery extends MasterySkill implements DirectionSkill {
  // TODO: Tune.
  static double _spearScale(int level) => lerpDouble(level, 1, 20, 0.2, 1.0);
  // TODO: Better name.
  String get name => "Spear Mastery";
  String get description =>
      "Your diligent study of spears and polearms lets you attack at a "
      "distance when wielding one.";
  String get weaponType => "spear";

  String levelDescription(int level) {
    var damage = (_spearScale(level) * 100).toInt();
    return "Distance spear attacks have $damage% of the damage of a regular "
        "attack.";
  }

  Action getDirectionAction(Game game, int level, Direction dir) {
    // See if the spear is a polearm.
    // TODO: Should these have a separate weapon type?
    var weapon = game.hero.equipment.weapon.type;
    var isPolearm = weapon.name == "Lance" || weapon.name == "Partisan";

    return new SpearAction(dir, SpearMastery._spearScale(level),
        isPolearm: isPolearm);
  }
}

/// A melee attack that penetrates a row of actors.
class SpearAction extends MasteryAction {
  /// How many frames it pauses between each step of the attack.
  static const _frameRate = 2;

  final Direction _dir;
  int _step = 0;
  final bool _isPolearm;

  SpearAction(this._dir, double damageScale, {bool isPolearm})
      : _isPolearm = isPolearm,
        super(damageScale);

  ActionResult onPerform() {
    var pos = actor.pos + _dir * (_step ~/ _frameRate + 1);

    // Polearms don't hit the adjacent tile, but do have longer range.
    if (_isPolearm) pos += _dir;

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % _frameRate == 0) {
      addEvent(EventType.stab, pos: pos, dir: _dir);
    } else if (_step % _frameRate == 1) {
      attack(pos);
    }

    _step++;
    return doneIf(_step == _frameRate * 2);
  }

  String toString() => '$actor spears $_dir';
}

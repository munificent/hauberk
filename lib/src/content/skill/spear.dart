import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../skills.dart';
import 'mastery.dart';

class SpearMastery extends MasterySkill {
  String get name => "Spear Mastery";
  String get weaponType => "spear";

  Command get command => new SpearCommand();
}

class SpearCommand extends MasteryCommand implements DirectionCommand {
  String get name => "Spear";
  String get weaponType => "spear";

  Action getDirectionAction(Game game, Direction dir) {
    // TODO: Tune.
    var scale =
        lerpDouble(game.hero.skills[Skills.spearMastery], 1, 20, 0.2, 1.0);
    return new SpearAction(dir, 2, scale);
  }
}

/// A melee attack that penetrates a row of actors.
class SpearAction extends MasteryAction {
  /// How many frames it pauses between each step of the attack.
  static const _frameRate = 2;

  final Direction _dir;
  final int _length;
  int _step = 0;

  SpearAction(this._dir, this._length, double damageScale) : super(damageScale);

  ActionResult onPerform() {
    var pos = actor.pos + _dir * (_step ~/ _frameRate + 1);

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % _frameRate == 0) {
      addEvent(EventType.stab, pos: pos, dir: _dir);
    } else if (_step % _frameRate == 1) {
      attack(pos);
    }

    _step++;
    return doneIf(_step == _frameRate * _length);
  }

  String toString() => '$actor spears $_dir';
}

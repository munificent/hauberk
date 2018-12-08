import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import 'mastery.dart';

class SpearMastery extends MasteryDiscipline implements DirectionSkill {
  // TODO: Tune.
  static double _spearScale(int level) => lerpDouble(level, 1, 10, 0.5, 1.5);

  // TODO: Better name.
  String get name => "Spear Mastery";

  String get useName => "Spear Attack";

  String get description =>
      "Your diligent study of spears and polearms lets you attack at a "
      "distance when wielding one.";

  String get weaponType => "spear";

  String levelDescription(int level) {
    var damage = (_spearScale(level) * 100).toInt();
    return super.levelDescription(level) +
        " Distance spear attacks inflict $damage% of the damage of a regular "
        "attack.";
  }

  Action getDirectionAction(Game game, int level, Direction dir) {
    // See if the spear is a polearm.
    // TODO: Should these have a separate weapon type?
    var weapon = game.hero.equipment.weapon.type;
    var isPolearm = weapon.name == "Lance" || weapon.name == "Partisan";

    return SpearAction(dir, SpearMastery._spearScale(level),
        isPolearm: isPolearm);
  }
}

/// A melee attack that penetrates a row of actors.
class SpearAction extends MasteryAction with GeneratorActionMixin {
  final Direction _dir;
  final bool _isPolearm;

  bool get isImmediate => false;

  SpearAction(this._dir, double damageScale, {bool isPolearm})
      : _isPolearm = isPolearm,
        super(damageScale);

  Iterable<ActionResult> onGenerate() sync* {
    // Can only do a spear attack if the entire range is clear.
    for (var step = 1; step <= (_isPolearm ? 3 : 2); step++) {
      var pos = actor.pos + _dir * step;

      var tile = game.stage[pos];
      if (!tile.isExplored) {
        yield fail("You can't see far enough to aim.");
        return;
      }

      if (!tile.canEnter(Motility.fly)) {
        var weapon = hero.equipment.weapon.type.name;
        yield fail("There isn't enough room to use your $weapon.");
        return;
      }
    }

    for (var step = 1; step <= 2; step++) {
      var pos = actor.pos + _dir * step;

      // Polearms don't hit the adjacent tile, but do have longer range.
      if (_isPolearm) pos += _dir;

      // Show the effect and perform the attack on alternate frames. This
      // ensures the effect gets a chance to be shown before the hit effect
      //  covers hit.
      var weapon = hero.equipment.weapon.appearance;
      addEvent(EventType.stab, pos: pos, dir: _dir, other: weapon);
      yield waitOne();

      attack(pos);
      yield waitOne();
    }
  }

  String toString() => '$actor spears $_dir';
}

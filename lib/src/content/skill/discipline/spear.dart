import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import 'mastery.dart';

class SpearMastery extends UsableMasteryDiscipline with DirectionSkill {
  // TODO: Tune.
  static double _spearScale(int level) => lerpDouble(level, 1, 10, 1.0, 3.0);

  // TODO: Better name.
  @override
  String get name => "Spear Mastery";

  @override
  String get useName => "Spear Attack";

  @override
  String get description =>
      "Your diligent study of spears and polearms lets you attack at a "
      "distance when wielding one.";

  @override
  String get weaponType => "spear";

  @override
  String levelDescription(int level) {
    var damage = (_spearScale(level) * 100).toInt();
    return "${super.levelDescription(level)} Distance spear attacks inflict "
        "$damage% of the damage of a regular attack.";
  }

  @override
  Action onGetDirectionAction(Game game, int level, Direction dir) =>
      SpearAction(dir, SpearMastery._spearScale(level));
}

/// A melee attack that penetrates a row of actors.
class SpearAction extends MasteryAction with GeneratorActionMixin {
  final Direction _dir;

  SpearAction(this._dir, double damageScale) : super(damageScale);

  @override
  bool get isImmediate => false;
  @override
  String get weaponType => "spear";

  @override
  Iterable<ActionResult> onGenerate() sync* {
    // Can only do a spear attack if the entire range is clear.
    for (var step = 1; step <= 2; step++) {
      var pos = actor!.pos + _dir * step;

      var tile = game.stage[pos];
      if (!tile.isExplored) {
        yield fail("You can't see far enough to aim.");
        return;
      }

      if (!tile.canEnter(Motility.fly)) {
        yield fail("There isn't enough room to use your weapon.");
        return;
      }
    }

    for (var step = 1; step <= 2; step++) {
      var pos = actor!.pos + _dir * step;

      // Show the effect and perform the attack on alternate frames. This
      // ensures the effect gets a chance to be shown before the hit effect
      //  covers hit.
      var weapon = hero.equipment.weapons.first.appearance;
      addEvent(EventType.stab, pos: pos, dir: _dir, other: weapon);
      yield waitOne();

      attack(pos);
      yield waitOne();
    }
  }

  @override
  String toString() => '$actor spears $_dir';
}

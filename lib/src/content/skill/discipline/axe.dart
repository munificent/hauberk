import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import 'mastery.dart';

/// A slashing melee attack that hits a number of adjacent monsters.
class AxeMastery extends MasteryDiscipline implements DirectionSkill {
  // TODO: Tune.
  static double _slashScale(int level) => lerpDouble(level, 1, 10, 0.5, 1.0);

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
class SlashAction extends MasteryAction with GeneratorActionMixin {
  final Direction _dir;

  bool get isImmediate => false;

  String get weaponType => "axe";

  SlashAction(this._dir, double damageScale) : super(damageScale);

  Iterable<ActionResult> onGenerate() sync* {
    // Make sure there is room to swing it.
    for (var dir in [_dir.rotateLeft45, _dir, _dir.rotateRight45]) {
      var pos = actor.pos + dir;

      var tile = game.stage[pos];
      if (!tile.isExplored) {
        yield fail("You can't see where you're swinging.");
        return;
      }

      if (!tile.canEnter(Motility.fly)) {
        yield fail("There isn't enough room to swing your weapon.");
        return;
      }
    }

    for (var dir in [_dir.rotateLeft45, _dir, _dir.rotateRight45]) {
      // Show the effect and perform the attack on alternate frames. This
      // ensures the effect gets a chance to be shown before the hit effect
      // covers hit.
      addEvent(EventType.slash, pos: actor.pos + dir, dir: dir);
      yield* wait(2);

      attack(actor.pos + dir);
      yield* wait(3);
    }
  }

  String toString() => '$actor slashes $_dir';
}

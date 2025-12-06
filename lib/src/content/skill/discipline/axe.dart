import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import 'mastery.dart';

/// A slashing melee attack that hits a number of adjacent monsters.
class AxeMastery extends UsableMasterySkill with DirectionSkill {
  // TODO: Tune.
  static double _sweepScale(int level) => lerpDouble(level, 1, 10, 1.0, 3.0);

  // TODO: Better name.
  @override
  String get name => "Axe Mastery";
  @override
  String get useName => "Axe Sweep";

  @override
  String get description =>
      "Axes are not just for woodcutting. In the hands of a skilled user, "
      "they can cut down a swath of nearby foes as well.";
  @override
  String get weaponType => "axe";

  @override
  String levelDescription(int level) {
    var damage = (_sweepScale(level) * 100).toInt();
    return "${super.levelDescription(level)} Sweep attacks inflict $damage% "
        "of the damage of a regular attack.";
  }

  @override
  Action onGetDirectionAction(Game game, int level, Direction dir) {
    return SweepAction(dir, AxeMastery._sweepScale(level));
  }
}

/// A sweeping melee attack that hits three adjacent tiles.
class SweepAction extends MasteryAction with GeneratorActionMixin {
  final Direction _dir;

  @override
  bool get isImmediate => false;

  @override
  String get weaponType => "axe";

  SweepAction(this._dir, double damageScale) : super(damageScale);

  @override
  Iterable<ActionResult> onGenerate() sync* {
    // Make sure there is room to swing it.
    for (var dir in [_dir.rotateLeft45, _dir, _dir.rotateRight45]) {
      var pos = actor!.pos + dir;

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
      addEvent(EventType.slash, pos: actor!.pos + dir, dir: dir);
      yield* wait(2);

      attack(actor!.pos + dir);
      yield* wait(3);
    }
  }

  @override
  String toString() => '$actor slashes $_dir';
}

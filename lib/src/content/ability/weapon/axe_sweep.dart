import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../skill/mastery.dart';
import '../mastery.dart';

// TODO: Probably want to make this more powerful and give it a focus cost.
/// A slashing melee attack that hits a number of adjacent monsters.
class AxeSweepAbility extends Ability with DirectionAbility {
  // TODO: Tune.
  static double _sweepScale(int level) => lerpDouble(level, 1, 10, 1.0, 3.0);

  @override
  String get name => "Axe Sweep";

  @override
  final List<Requirement> requirements = [WeaponTypeRequirement("axe")];

  @override
  Action onGetDirectionAction(Game game, Direction dir) {
    var level = game.hero.save.skills.level(AxeMastery.instance);
    return AxeSweepAction(dir, _sweepScale(level));
  }
}

/// A sweeping melee attack that hits three adjacent tiles.
class AxeSweepAction extends MasteryAction with GeneratorActionMixin {
  final Direction _dir;

  @override
  bool get isImmediate => false;

  @override
  String get weaponType => "axe";

  AxeSweepAction(this._dir, double damageScale) : super(damageScale);

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

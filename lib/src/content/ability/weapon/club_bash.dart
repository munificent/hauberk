import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../skill/mastery.dart';
import '../mastery.dart';

// TODO: Probably want to make this more powerful and give it a focus cost.
class ClubBashAbility extends Ability with DirectionAbility {
  // TODO: Tune.
  static double _bashScale(int level) =>
      lerpDouble(level, 1, Skill.modifiedMax, 1.0, 2.0);

  @override
  String get name => "Club Bash";

  @override
  final List<Requirement> requirements = [WeaponTypeRequirement("club")];

  @override
  Action onGetDirectionAction(Game game, Direction dir) {
    var level = game.hero.save.skills.level(Bludgeoning.instance);
    return ClubBashAction(dir, _bashScale(level));
  }
}

/// A melee attack that attempts to push back the defender.
class ClubBashAction extends MasteryAction {
  final Direction _dir;
  int _step = 0;
  int? _damage = 0;

  ClubBashAction(this._dir, double scale) : super(scale);

  @override
  bool get isImmediate => false;
  @override
  String get weaponType => "club";

  @override
  ActionResult onPerform() {
    if (_step == 0) {
      _damage = attack(actor!.pos + _dir);
      if (_damage == null) {
        return fail("There's no one there!");
      } else if (_damage == 0) {
        // If the hit missed, no pushback.
        return ActionResult.success;
      }
    } else if (_step == 1) {
      // Push the defender.
      var defender = game.stage.actorAt(actor!.pos + _dir);

      // Make sure the defender is still there. Could have died.
      if (defender == null) return ActionResult.success;

      var dest = actor!.pos + _dir + _dir;

      // TODO: Strength bonus?
      var chance = 300 * _damage! ~/ defender.maxHealth;
      chance = chance.clamp(5, 100);

      if (game.stage.canEnter(dest, defender.motility) && rng.percent(chance)) {
        moveActor(defender, dest);
        defender.energy.energy = 0;
        show("{1} is knocked back!", defender);
        addEvent(EventType.knockBack, pos: actor!.pos + _dir, dir: _dir);
      }
    } else {
      addEvent(EventType.pause);
    }

    _step++;
    return doneIf(_step > 10);
  }

  @override
  String toString() => '$actor bashes $_dir';
}

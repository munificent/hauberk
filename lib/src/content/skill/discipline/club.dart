import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import 'mastery.dart';

class ClubMastery extends UsableMasteryDiscipline with DirectionSkill {
  // TODO: Tune.
  static double _bashScale(int level) => lerpDouble(level, 1, 10, 1.0, 2.0);

  // TODO: Better name.
  @override
  String get name => "Club Mastery";

  @override
  String get useName => "Club Bash";

  @override
  String get description =>
      "Bludgeons may not be the most sophisticated of weapons, but what they "
      "lack in refinement, they make up for in brute force.";

  @override
  String get weaponType => "club";

  @override
  String levelDescription(int level) {
    // TODO: Describe scale.
    return "${super.levelDescription(level)} Bashes the enemy away.";
  }

  @override
  Action onGetDirectionAction(Game game, int level, Direction dir) {
    return BashAction(dir, ClubMastery._bashScale(level));
  }
}

/// A melee attack that attempts to push back the defender.
class BashAction extends MasteryAction {
  final Direction _dir;
  int _step = 0;
  int? _damage = 0;

  BashAction(this._dir, double scale) : super(scale);

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

      if (defender.canEnter(dest) && rng.percent(chance)) {
        defender.pos = dest;
        defender.energy.energy = 0;
        log("{1} is knocked back!", defender);
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

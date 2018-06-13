import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import 'mastery.dart';

class ClubMastery extends MasteryDiscipline implements DirectionSkill {
  // TODO: Tune.
  static double _bashScale(int level) => lerpDouble(level, 1, 10, 0.2, 0.8);

  // TODO: Better name.
  String get name => "Club Mastery";

  String get useName => "Club Bash";

  String get description =>
      "Bludgeons may not be the most sophisticated of weapons, but what they "
      "lack in refinement, they make up for in brute force.";

  String get weaponType => "club";

  String levelDescription(int level) {
    // TODO: Describe scale.
    return super.levelDescription(level) + " Bashes the enemy away.";
  }

  Action getDirectionAction(Game game, int level, Direction dir) {
    return new BashAction(dir, ClubMastery._bashScale(level));
  }
}

/// A melee attack that attempts to push back the defender.
class BashAction extends MasteryAction {
  final Direction _dir;
  int _step = 0;
  int _damage = 0;

  bool get isImmediate => false;

  BashAction(this._dir, double scale) : super(scale);

  ActionResult onPerform() {
    if (_step == 0) {
      _damage = attack(actor.pos + _dir);

      // If the hit missed, no pushback.
      if (_damage == null) return ActionResult.success;
    } else if (_step == 1) {
      // Push the defender.
      var defender = game.stage.actorAt(actor.pos + _dir);

      // Make sure the defender is still there. Could have died.
      if (defender == null) return ActionResult.success;

      var dest = actor.pos + _dir + _dir;

      // TODO: Strength bonus?
      var chance = 300 * _damage ~/ defender.maxHealth;
      chance = chance.clamp(5, 100);

      if (game.stage.actorAt(dest) == null &&
          defender.canOccupy(dest) &&
          rng.percent(chance)) {
        defender.pos = dest;
        defender.energy.energy = 0;
        log("{1} is knocked back!", defender);
        addEvent(EventType.knockBack, pos: actor.pos + _dir, dir: _dir);
      }
      // TODO: Effect.
    } else {
      addEvent(EventType.pause);
    }

    _step++;
    return doneIf(_step > 10);
  }

  String toString() => '$actor bashes $_dir';
}

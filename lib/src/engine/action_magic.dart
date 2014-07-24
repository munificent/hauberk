library hauberk.engine.action_magic;

import 'package:piecemeal/piecemeal.dart';

import 'action_base.dart';
import 'condition.dart';
import 'game.dart';

class HealAction extends Action {
  final int amount;
  final bool curePoison;

  HealAction(this.amount, {this.curePoison: false});

  ActionResult onPerform() {
    var changed = false;

    if (actor.poison.isActive && curePoison) {
      actor.poison.cancel();
      log("{1} [are|is] cleansed of poison.", actor);
      changed = true;
    }

    if (!actor.health.isMax && amount > 0) {
      actor.health.current += amount;
      addEvent(new Event(EventType.HEAL, actor: actor, value: amount));
      log('{1} feel[s] better.', actor);
      changed = true;
    }

    if (changed) {
      return ActionResult.SUCCESS;
    } else {
      return succeed("{1} [don't|doesn't] feel any different.", actor);
    }
  }
}

class TeleportAction extends Action {
  final int distance;

  TeleportAction(this.distance);

  ActionResult onPerform() {
    final targets = [];

    final bounds = Rect.intersect(
        new Rect(actor.x - distance, actor.y - distance,
                 actor.x + distance, actor.y + distance),
        game.stage.bounds);

    for (var pos in bounds) {
      if (!game.stage[pos].isPassable) continue;
      if (game.stage.actorAt(pos) != null) continue;
      if (pos - actor.pos > distance) continue;
      targets.add(pos);
    }

    if (targets.length == 0) {
      return fail("{1} couldn't escape.", actor);
    }

    // Try to teleport as far as possible.
    var best = rng.item(targets);

    for (var tries = 0; tries < 10; tries++) {
      final pos = rng.item(targets);
      if (pos - actor.pos > best - actor.pos) best = pos;
    }

    var from = actor.pos;
    actor.pos = best;
    addEvent(new Event(EventType.TELEPORT, actor: actor, value: from));
    return succeed('{1} teleport[s]!', actor);
  }
}

/// An [Action] that marks all tiles containing [Item]s explored.
class DetectItemsAction extends Action {
  ActionResult onPerform() {
    var numFound = 0;
    for (var item in game.stage.items) {
      // Ignore items already found.
      if (game.stage[item.pos].isExplored) continue;

      numFound++;
      game.stage[item.pos].isExplored = true;
      addEvent(new Event(EventType.DETECT, value: item.pos));
    }

    if (numFound == 0) {
      return succeed('The darkness holds no secrets.');
    }

    return succeed('{1} sense[s] the treasures held in the dark!', actor);
  }
}

class BurnAction extends Action {
  BurnAction(num damage);

  ActionResult onPerform() {
    // TODO: Burn flammable items.

    // Being burned "cures" cold.
    if (actor.cold.isActive) {
      actor.cold.cancel();
      return succeed("The fire warms {1} back up.", actor);
    }

    return ActionResult.SUCCESS;
  }
}

/// Base class for an [Action] that applies (or extends/intensifies) a
/// [Condition]. It handles cases where the condition is already in effect with
/// possibly a different intensity.
abstract class ConditionAction extends Action {
  /// The [Condition] on the actor that should be affected.
  Condition get condition;

  /// The intensity of the condition to apply.
  int getIntensity() => 1;

  /// The number of turns the condition should last.
  int getDuration();

  /// Override this to log the message when the condition is first applied.
  void logApply();

  /// Override this to log the message when the condition is already in effect
  /// and its duration is extended.
  void logExtend();

  /// Override this to log the message when the condition is already in effect
  /// at a weaker intensity and the intensity increases.
  void logIntensify() {}

  ActionResult onPerform() {
    var intensity = getIntensity();
    var duration = getDuration();

    // TODO: Apply resistance to duration and bail if zero duration.
    // TODO: Don't lower intensity by resistance here (we want to handle that
    // each turn in case it changes), but do see if resistance will lower the
    // intensity to zero. If so, bail.

    if (!condition.isActive) {
      condition.activate(duration, intensity);
      logApply();
      return ActionResult.SUCCESS;
    }

    if (condition.intensity >= intensity) {
      // Scale down the new duration by how much weaker the new intensity is.
      duration = (duration * intensity) / condition.intensity;

      // Compounding doesn't add as much as the first one.
      duration = (duration / 2).truncate();
      if (duration == 0) return succeed();

      condition.extend(duration);
      logExtend();
      return ActionResult.SUCCESS;
    }

    // Scale down the existing duration by how much stronger the new intensity
    // is.
    var oldDuration = (condition.duration * condition.intensity) / intensity;

    condition.activate((oldDuration + duration / 2).truncate(), intensity);
    logIntensify();
    return ActionResult.SUCCESS;
  }
}

class HasteAction extends ConditionAction {
  final int _duration;
  final int _speed;

  HasteAction(this._duration, this._speed);

  Condition get condition => actor.haste;

  int getIntensity() => _speed;
  int getDuration() => _duration;
  void logApply() => log("{1} start[s] moving faster.", actor);
  void logExtend() => log("{1} [feel]s the haste lasting longer.", actor);
  void logIntensify() => log("{1} move[s] even faster.", actor);
}

class FreezeAction extends ConditionAction {
  final int _damage;

  FreezeAction(this._damage);

  Condition get condition => actor.cold;

  // TODO: Should also break items in inventory.

  int getIntensity() => 1 + _damage ~/ 40;
  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void logApply() => log("{1} [are|is] frozen!", actor);
  void logExtend() => log("{1} feel[s] the cold linger!", actor);
  void logIntensify() => log("{1} feel[s] the cold intensify!", actor);
}

class PoisonAction extends ConditionAction {
  final int _damage;

  PoisonAction(this._damage);

  Condition get condition => actor.poison;

  int getIntensity() => 1 + _damage ~/ 20;
  int getDuration() => 1 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void logApply() => log("{1} [are|is] poisoned!", actor);
  void logExtend() => log("{1} feel[s] the poison linger!", actor);
  void logIntensify() => log("{1} feel[s] the poison intensify!", actor);
}

class DazzleAction extends ConditionAction {
  final int _damage;

  DazzleAction(this._damage);

  Condition get condition => actor.dazzle;

  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void logApply() => log("{1} [are|is] dazzled by the light!", actor);
  void logExtend() => log("{1} [are|is] dazzled by the light!", actor);
}

library dngn.engine.action_magic;

import '../util.dart';
import 'action_base.dart';
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
      addEvent(new Event.heal(actor, amount));
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

    // TODO(bob): Effect.
    actor.pos = best;
    return succeed('{1} teleport[s] away!', actor);
  }
}

class HasteAction extends Action {
  final int _duration;
  final int _speed;

  HasteAction(this._duration, this._speed);

  ActionResult onPerform() {
    // The behavior is based on the actor's current haste level (the rows in
    // the table) and the one being applied by this action (the columns).
    var dispatch = [
      // -2     -1         0     1          2
      [_extend, _noEffect, null, _fast,     _fast],   // -2
      [_slow,   _extend,   null, _fast,     _fast],   // -1
      [_slow,   _slow,     null, _fast,     _fast],   // Normal
      [_resist, _resist,   null, _extend,   _fast],   // 1
      [_resist, _resist,   null, _noEffect, _extend], // 2
    ];

    dispatch[actor.haste.intensity + 2][_speed + 2]();
    return succeed();
  }

  void _extend() {
    actor.haste.extend(_duration ~/ 2);
    log("{1} [feel]s the effects lasting longer.", actor);
  }

  void _noEffect() {
    log("It has no effect.", actor);
  }

  void _resist() {
    log("{1 his} speed protects you from slowing.", actor);
  }

  void _slow() {
    log("{1} start[s] moving slower.", actor);
    actor.haste.activate(_duration, _speed);
  }

  void _fast() {
    log("{1} start[s] moving faster.", actor);
    actor.haste.activate(_duration, _speed);
  }
}

class PoisonAction extends Action {
  final int _damage;

  PoisonAction(this._damage);

  ActionResult onPerform() {
    // Intensity ramps up slowly since greater damage also increases duration.
    var intensity = 1 + (_damage / 20).round();
    var duration = 1 + rng.triangleInt(_damage ~/ 2, _damage ~/ 2);

    // TODO: Apply resistance to duration and bail if zero duration.
    // TODO: Don't lower intensity by resistance here (we want to handle that
    // each turn in case it changes), but do see if resistance will lower the
    // intensity to zero. If so, bail.

    if (!actor.poison.isActive) {
      actor.poison.activate(duration, intensity);
      return succeed("{1} [are|is] poisoned!", actor);
    }

    if (actor.poison.intensity >= intensity) {
      // Scale down the new duration by how much weaker the new poison is.
      duration = (duration * intensity) / actor.poison.intensity;

      // Compound poison doesn't add as much as the first one.
      duration = (duration / 2).truncate();
      if (duration == 0) return succeed();

      actor.poison.extend(duration);
      return succeed("{1} feel[s] the poison linger!", actor);
    }

    // Scale down the existing duration by how much stronger the new poison
    // is.
    var oldDuration = (actor.poison.duration * actor.poison.intensity)
        / intensity;

    actor.poison.activate((oldDuration + duration / 2).truncate(),
        intensity);
    return succeed("{1} feel[s] the poison intensify!", actor);
  }
}
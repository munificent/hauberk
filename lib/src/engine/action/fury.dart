library hauberk.engine.action.stab;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../game.dart';
import '../option.dart';

/// A [Warrior]'s [Action] that requires and spends fury to perform a powerful
/// attack.
abstract class FuryAction extends Action {
  bool _madeContact = false;

  ActionResult onPerform() {
    if (hero.charge < 20) return fail("You are not furious enough yet.");

    var result = performAttack();

    // Drain fury when the attack is done if it hit something.
    if (result.done && _madeContact) hero.charge /= 2;
    return result;
  }

  ActionResult performAttack();

  /// Attempts to perform an attack on the [Actor] as [pos], if any.
  void attack(Vec pos) {
    var defender = game.stage.actorAt(pos);
    if (defender == null) return;

    var attack = actor.getAttack(defender);

    // The more furious the warrior is, the stronger the attack will be (and the
    // more fury that will be spent). The attack multiplier increases more
    // quickly that the fury cost so that the player is rewarded for building
    // up fury and doing a single stronger attack. The ramp works like:
    //
    //     Fury  Multiplier
    //       20  1.0
    //       40  3.0
    //       60  5.0
    //       80  7.0
    //      100  9.0
    var multiplier = (hero.charge - 10) / 10;
    attack.multiplyDamage(multiplier);
    if (attack.perform(this, actor, defender)) _madeContact = true;
  }
}

/// A sweeping melee attack that hits three adjacent tiles.
class SlashAction extends FuryAction {
  /// How many frames it pauses between each step of the swing.
  static const _FRAME_RATE = 5;

  final Direction _dir;
  int _step = 0;

  SlashAction(this._dir);

  ActionResult performAttack() {
    var dir;
    switch (_step ~/ _FRAME_RATE) {
      case 0: dir = _dir.rotateLeft45; break;
      case 1: dir = _dir; break;
      case 2: dir = _dir.rotateRight45; break;
    }

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % 2 == 0) {
      addEvent(EventType.SLASH, pos: actor.pos + dir, dir: dir);
    } else if (_step % 2 == 1) {
      attack(actor.pos + dir);
    }

    _step++;
    return doneIf(_step == _FRAME_RATE * 3);
  }

  int get noise => Option.NOISE_HIT;

  String toString() => '$actor slashes $_dir';
}

/// A melee attack that penetrates a row of actors.
class LanceAction extends FuryAction {
  /// How many frames it pauses between each step of the swing.
  static const _FRAME_RATE = 2;

  final Direction _dir;
  int _step = 0;

  LanceAction(this._dir);

  ActionResult performAttack() {
    var pos = actor.pos + _dir * (_step ~/ _FRAME_RATE + 1);

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % _FRAME_RATE == 0) {
      addEvent(EventType.STAB, pos: pos, dir: _dir);
    } else if (_step % _FRAME_RATE == 1) {
      attack(pos);
    }

    _step++;
    return doneIf(_step == _FRAME_RATE * 3);
  }

  int get noise => Option.NOISE_HIT;

  String toString() => '$actor spears $_dir';
}

/// A melee attack that repeatedly hits in one direction.
class StabAction extends FuryAction {
  /// How many frames it pauses between each step of the stab.
  static const _FRAME_RATE = 4;

  final Direction _dir;
  int _step = 0;

  StabAction(this._dir);

  ActionResult performAttack() {
    var pos = actor.pos + _dir;

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % _FRAME_RATE == 0) {
      addEvent(EventType.STAB, pos: pos, dir: _dir);
    } else if (_step % _FRAME_RATE == 1) {
      attack(pos);
    }

    _step++;
    return doneIf(_step == _FRAME_RATE * 3);
  }

  int get noise => Option.NOISE_HIT;

  String toString() => '$actor stabs $_dir';
}

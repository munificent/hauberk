import 'package:piecemeal/piecemeal.dart';

import '../core/game.dart';
import '../core/option.dart';
import 'action.dart';

// TODO: Remove.
/// A [Warrior]'s [Action] that requires and spends fury to perform a powerful
/// attack.
abstract class FuryAction extends Action {
  bool _madeContact = false;

  ActionResult onPerform() {
    if (hero.charge < 1) return fail("You are not furious enough yet.");

    var result = performAttack();

    // Drain fury when the attack is done if it hit something.
    if (result.done && _madeContact) hero.charge /= 2.0;
    return result;
  }

  ActionResult performAttack();

  /// Attempts to hit the [Actor] as [pos], if any.
  void attack(Vec pos) {
    var defender = game.stage.actorAt(pos);
    if (defender == null) return;

    var hit = actor.createMeleeHit();

    // The more furious the warrior is, the stronger the attack will be (and the
    // more fury that will be spent). The attack multiplier increases more
    // quickly than the fury cost so that the player is rewarded for building
    // up fury and doing a single stronger attack.
    hit.scaleDamage(1.0 + hero.charge / 20);

    if (hit.perform(this, actor, defender)) _madeContact = true;
  }
}

/// A sweeping melee attack that hits three adjacent tiles.
class SlashAction extends FuryAction {
  /// How many frames it pauses between each step of the swing.
  static const _frameRate = 5;

  final Direction _dir;
  int _step = 0;

  SlashAction(this._dir);

  ActionResult performAttack() {
    var dir;
    switch (_step ~/ _frameRate) {
      case 0:
        dir = _dir.rotateLeft45;
        break;
      case 1:
        dir = _dir;
        break;
      case 2:
        dir = _dir.rotateRight45;
        break;
    }

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % 2 == 0) {
      addEvent(EventType.slash, pos: actor.pos + dir, dir: dir);
    } else if (_step % 2 == 1) {
      attack(actor.pos + dir);
    }

    _step++;
    return doneIf(_step == _frameRate * 3);
  }

  int get noise => Option.noiseHit;

  String toString() => '$actor slashes $_dir';
}

/// A melee attack that penetrates a row of actors.
class LanceAction extends FuryAction {
  /// How many frames it pauses between each step of the swing.
  static const _frameRate = 2;

  final Direction _dir;
  int _step = 0;

  LanceAction(this._dir);

  ActionResult performAttack() {
    var pos = actor.pos + _dir * (_step ~/ _frameRate + 1);

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % _frameRate == 0) {
      addEvent(EventType.stab, pos: pos, dir: _dir);
    } else if (_step % _frameRate == 1) {
      attack(pos);
    }

    _step++;
    return doneIf(_step == _frameRate * 3);
  }

  int get noise => Option.noiseHit;

  String toString() => '$actor spears $_dir';
}

/// A melee attack that repeatedly hits in one direction.
class StabAction extends FuryAction {
  /// How many frames it pauses between each step of the stab.
  static const _frameRate = 4;

  final Direction _dir;
  int _step = 0;

  StabAction(this._dir);

  ActionResult performAttack() {
    var pos = actor.pos + _dir;

    // Show the effect and perform the attack on alternate frames. This ensures
    // the effect gets a chance to be shown before the hit effect covers hit.
    if (_step % _frameRate == 0) {
      addEvent(EventType.stab, pos: pos, dir: _dir);
    } else if (_step % _frameRate == 1) {
      attack(pos);
    }

    _step++;
    return doneIf(_step == _frameRate * 3);
  }

  int get noise => Option.noiseHit;

  String toString() => '$actor stabs $_dir';
}

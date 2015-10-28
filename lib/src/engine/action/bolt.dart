library hauberk.engine.action.bolt;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../actor.dart';
import '../attack.dart';
import '../game.dart';
import '../los.dart';

// TODO: Move to separate file?
/// Base class for an [Action] that traces a path from the actor along a [Los].
abstract class LosAction extends Action {
  final Vec _target;
  Vec _lastPos;
  Iterator<Vec> _los;

  /// Override this to provide the range of the line.
  int get range;

  LosAction(this._target);

  ActionResult onPerform() {
    if (_los == null) {
      _los = new Los(actor.pos, _target).iterator;
      // Advance to the first tile.
      _los.moveNext();

      _lastPos = actor.pos;
    }

    var pos = _los.current;

    // Stop if we hit a wall or went out of range.
    if (!game.stage[pos].isTransparent || pos - actor.pos > range) {
      onEnd(_lastPos);
      return succeed();
    }

    onStep(pos);

    // See if there is an actor there.
    var target = game.stage.actorAt(pos);
    if (target != null && target != actor) {
      if (onHitActor(pos, target)) return ActionResult.success;
    }

    if (pos == _target) {
      if (onTarget(pos)) return ActionResult.success;
    }

    _lastPos = pos;
    return doneIf(!_los.moveNext());
  }

  /// Override this to handle the LOS reaching an open tile.
  void onStep(Vec pos);

  /// Override this to handle the LOS hitting an [Actor].
  ///
  /// Return `true` if the LOS should stop here or `false` if it should keep
  /// going.
  bool onHitActor(Vec pos, Actor actor) => true;

  /// Override this to handle the LOS hitting a wall or going out of range.
  ///
  /// [pos] is the position on the path *before* failure. It's the last good
  /// position. It may be the actor's position if the LOS hit a wall directly
  /// adjacent to the actor.
  void onEnd(Vec pos) {}

  /// Override this to handle the LOS reaching the target on an open tile.
  ///
  /// If this returns `true`, the LOS will stop there. Otherwise it will
  /// continue until it reaches the end of its range or hits something.
  bool onTarget(Vec pos) => false;
}

/// Fires a bolt, a straight line of an elemental attack that stops at the
/// first [Actor] is hits or opaque tile.
class BoltAction extends LosAction {
  final RangedAttack _attack;
  final bool _canMiss;

  int get range => _attack.range;

  BoltAction(Vec target, this._attack, {bool canMiss: false})
      : _canMiss = canMiss,
        super(target);

  void onStep(Vec pos) {
    addEvent(EventType.bolt, element: _attack.element, pos: pos);
  }

  bool onHitActor(Vec pos, Actor target) {
    var attack = _attack;

    // TODO: Should range increase odds of missing? If so, do that here. Also
    // need to tweak enemy AI then since they shouldn't always try to maximize
    // distance.
    attack.perform(this, actor, target, canMiss: _canMiss);
    return true;
  }
}

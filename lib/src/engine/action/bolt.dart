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
      onHitActor(pos, target);
      return ActionResult.SUCCESS;
    }

    if (pos == _target) {
      if (onTarget(pos)) return ActionResult.SUCCESS;
    }

    _lastPos = pos;
    return _los.moveNext() ? ActionResult.NOT_DONE : ActionResult.SUCCESS;
  }

  /// Override this to handle the LOS reaching an open tile.
  void onStep(Vec pos);

  /// Override this to handle the LOS hitting an [Actor].
  void onHitActor(Vec pos, Actor actor);

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

  int get range => _attack.range;

  BoltAction(Vec target, this._attack)
      : super(target);

  void onStep(Vec pos) {
    addEvent(EventType.BOLT, element: _attack.element, pos: pos);
  }

  void onHitActor(Vec pos, Actor target) {
    var attack = _attack;

    // Being too close or too far weakens the bolt.
    // TODO: Make this modify strike instead?
    var toTarget = pos - actor.pos;
    if (toTarget > _attack.range * 2 / 3) {
      attack = attack.multiplyDamage(0.5);
    }

    attack.perform(this, actor, target, canMiss: false);
  }
}

import '../action/action.dart';
import 'actor.dart';
import 'element.dart';
import 'log.dart';

// TODO: To reinforce the session-oriented play style of the game, maybe these
// shouldn't wear off?

/// A temporary condition that modifies some property of an [Actor] while it
/// is in effect.
abstract class Condition {
  /// The [Actor] that this condition applies to.
  Actor get actor => _actor;
  Actor _actor;

  /// The number of turns that the condition while remain in effect for.
  int _turnsRemaining = 0;

  /// The "intensity" of this condition. The interpretation of this varies from
  /// condition to condition.
  int _intensity = 0;

  /// Gets whether the condition is currently in effect.
  bool get isActive => _turnsRemaining > 0;

  int get duration => _turnsRemaining;

  /// The condition's current intensity, or zero if not active.
  int get intensity => _intensity;

  /// Binds the condition to the actor that it applies to. Must be called and
  /// can only be called once.
  void bind(Actor actor) {
    assert(_actor == null);
    _actor = actor;
  }

  /// Processes one turn of the condition.
  void update(Action action) {
    if (isActive) {
      _turnsRemaining--;
      if (isActive) {
        onUpdate(action);
      } else {
        onDeactivate();
        _intensity = 0;
      }
    }
  }

  /// Extends the condition by [duration].
  void extend(int duration) {
    _turnsRemaining += duration;
  }

  /// Activates the condition for [duration] turns at [intensity].
  void activate(int duration, [int intensity = 1]) {
    _turnsRemaining = duration;
    _intensity = intensity;
  }

  /// Cancels the condition immediately. Does not deactivate the condition.
  void cancel() {
    _turnsRemaining = 0;
    _intensity = 0;
  }

  // TODO: Instead of modifying the given action, should this create a reaction?
  void onUpdate(Action action) {}

  void onDeactivate();
}

// TODO: Move these to content?

/// A condition that temporarily boosts the actor's speed.
class HasteCondition extends Condition {
  void onDeactivate() {
    actor.log("{1} slow[s] back down.", actor);
  }
}

/// A condition that temporarily lowers the actor's speed.
class ColdCondition extends Condition {
  void onDeactivate() {
    actor.log("{1} warm[s] back up.", actor);
  }
}

/// A condition that inflicts damage every turn.
class PoisonCondition extends Condition {
  void onUpdate(Action action) {
    // TODO: Apply resistances. If resistance lowers intensity to zero, end
    // condition and log message.

    if (!actor.takeDamage(action, intensity, Noun("the poison"))) {
      actor.log("{1} [are|is] hurt by poison!", actor);
    }
  }

  void onDeactivate() {
    actor.log("{1} [are|is] no longer poisoned.", actor);
  }
}

/// A condition that impairs vision.
class BlindnessCondition extends Condition {
  void onDeactivate() {
    actor.log("{1} can see clearly again.", actor);
    if (actor == actor.game.hero) actor.game.stage.heroVisibilityChanged();
  }
}

/// A condition that provides resistance to an element.
class ResistCondition extends Condition {
  final Element _element;

  ResistCondition(this._element);

  void onDeactivate() {
    actor.log("{1} feel[s] susceptible to $_element.", actor);
  }
}

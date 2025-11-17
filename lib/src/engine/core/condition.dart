import '../action/action.dart';
import 'actor.dart';
import 'element.dart';
import 'log.dart';

// TODO: To reinforce the session-oriented play style of the game, maybe these
// shouldn't wear off?

/// A temporary condition that modifies some property of an [Actor] while it
/// is in effect.
abstract class Condition {
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

  /// Processes one turn of the condition.
  void update(Action action) {
    if (isActive) {
      _turnsRemaining--;
      if (isActive) {
        onUpdate(action);
      } else {
        onDeactivate(action);
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

  void onDeactivate(Action action);
}

// TODO: Move these to content?

/// A condition that temporarily boosts the actor's speed.
class HasteCondition extends Condition {
  @override
  void onDeactivate(Action action) {
    action.show("{1} slow[s] back down.", action.actor);
  }
}

/// A condition that temporarily lowers the actor's speed.
class ColdCondition extends Condition {
  @override
  void onDeactivate(Action action) {
    action.show("{1} warm[s] back up.", action.actor);
  }
}

/// A condition that inflicts damage every turn.
class PoisonCondition extends Condition {
  @override
  void onUpdate(Action action) {
    // TODO: Apply resistances. If resistance lowers intensity to zero, end
    // condition and log message.

    if (!action.actor!.takeDamage(action, intensity, Noun("the poison"))) {
      action.show("{1} [are|is] hurt by poison!", action.actor);
    }
  }

  @override
  void onDeactivate(Action action) {
    action.show("{1} [are|is] no longer poisoned.", action.actor);
  }
}

/// A condition that impairs vision.
class BlindnessCondition extends Condition {
  @override
  void onDeactivate(Action action) {
    action.show("{1} can see clearly again.", action.actor);
    if (action.actor == action.game.hero) {
      action.game.stage.heroVisibilityChanged();
    }
  }
}

/// A condition that provides resistance to an element.
class ResistCondition extends Condition {
  final Element _element;

  ResistCondition(this._element);

  @override
  void onDeactivate(Action action) {
    action.show("{1} feel[s] susceptible to $_element.", action.actor);
  }
}

/// A condition that provides non-visual perception of nearby monsters.
class PerceiveCondition extends Condition {
  PerceiveCondition();

  @override
  void onDeactivate(Action action) {
    action.show("{1} no longer perceive[s] monsters.", action.actor);
  }
}

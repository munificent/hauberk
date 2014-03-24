part of engine;

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

  /// The condition's current intensity, or zero if not active.
  int get intensity => _intensity;

  /// Binds the condition to the actor that it applies to. Must be called and
  /// can only be called once.
  void bind(Actor actor) {
    assert(_actor == null);
    _actor = actor;
  }

  /// Processes one turn of the condition.
  void update() {
    if (isActive) {
      _turnsRemaining--;
      if (!isActive) {
        onDeactivate();
        _intensity = 0;
      }
    }
  }

  /// Extends the condition by [duration].
  void extend(int duration) {
    assert(isActive);

    _turnsRemaining += duration;
  }

  /// Activates the condition for [duration] turns at [intensity].
  void activate(int duration, [int intensity = 1]) {
    _turnsRemaining = duration;
    _intensity = intensity;
  }

  void onDeactivate();
}

/// A condition that temporarily modifies the actor's speed.
class HasteCondition extends Condition {
  void onDeactivate() {
    if (intensity > 0) {
      actor.game.log.message("{1} slow[s] back down.", actor);
    } else {
      actor.game.log.message("{1} speed[s] back up.", actor);
    }
  }
}
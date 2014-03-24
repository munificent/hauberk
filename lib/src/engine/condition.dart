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
        _intensity = 0;
        onDeactivate();
      }
    }
  }

  /// Activates the condition for [duration] turns. If already active, adds to
  /// the previous duration.
  void activate(int duration, [int intensity = 0]) {
    var improved = !isActive || intensity > _intensity;
    _intensity = math.max(_intensity, intensity);

    if (improved) onActivate();

    _turnsRemaining += duration;
  }

  void onActivate(int intensity);
  void onDeactivate();
}

/// A condition that temporarily boosts the actor's speed.
class HasteCondition extends Condition {
  void onActivate() {
    actor.game.log.message("{1} speed[s] up!", actor);
  }

  void onDeactivate() {
    actor.game.log.message("{1} slow[s] back down.", actor);
  }
}
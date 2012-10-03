class Thing implements Noun {
  Vec _pos;

  Thing(this._pos);

  Vec get pos() => _pos;
  void set pos(Vec value) {
    if (value != _pos) {
      _pos = changePosition(value);
    }
  }

  int get x() => pos.x;
  void set x(int value) {
    pos = new Vec(value, y);
  }

  int get y() => pos.y;
  void set y(int value) {
    pos = new Vec(x, value);
  }

  /// Called when the actor's position is about to change to [pos]. Override
  /// to do stuff when the position changes. Returns the new position.
  Vec changePosition(Vec pos) => pos;

  abstract get appearance();
  abstract String get nounText();
  abstract int get person();
  abstract Gender get gender();

  String toString() => nounText;
}

/// An active entity in the game. Includes monsters and the hero.
class Actor extends Thing {
  final Game game;
  final Stat health;
  Energy energy;

  /// The number of times the actor has rested. Once this crosses a certain
  /// threshold (based on the Actor's max health), its health will be increased
  /// and this will be lowered.
  int restCount = 0;

  Actor(this.game, int x, int y, int health)
  : super(new Vec(x, y)),
    health = new Stat(health),
    energy = new Energy(Energy.NORMAL_SPEED);

  bool get isAlive => health.current > 0;

  bool get needsInput => false;

  Action getAction() {
    final action = onGetAction();
    if (action != null) action.bind(this, true);
    return action;
  }

  abstract Action onGetAction();

  /// Get an [Attack] for this [Actor] to attempt to hit [defender].
  abstract Attack getAttack(Actor defender);

  /// This is called on the defender when some attacker is attempting to hit it.
  /// The defender fills it in with the information needed to resolve the the
  /// hit.
  abstract void takeHit(Hit hit);

  /// Called when this Actor has been killed by [attacker].
  void onDied(Actor attacker) {
    // Do nothing.
  }

  /// Called when this Actor has killed [defender].
  void onKilled(Actor defender) {
    // Do nothing.
  }

  bool canOccupy(Vec pos) {
    if (pos.x < 0) return false;
    if (pos.x >= game.stage.width) return false;
    if (pos.y < 0) return false;
    if (pos.y >= game.stage.height) return false;

    return game.stage[pos].isPassable;
  }

  void finishTurn() {
    energy.spend();
    regenerate();
  }

  void regenerate() {
    // TODO(bob): Could have "regeneration" power-up that speeds this.
    // The greater the max health, the faster the actor heals when resting.
    final turnsNeeded = math.max(
        Option.REST_MAX_HEALTH_FOR_RATE ~/ health.max, 1);

    if (restCount++ > turnsNeeded) {
      health.current++;
      restCount = 0;
    }
  }
}

class Stat {
  int _current;
  int _max;

  int get current() => _current;
  void set current(int value) {
    _current = clamp(0, value, _max);
  }

  int get max() => _max;
  void set max(int value) {
    _max = value;

    // Make sure current is still in bounds.
    _current = clamp(0, _current, _max);
  }

  bool get isMax() => _current == _max;

  Stat(int value)
  : _current = value,
    _max = value;
}
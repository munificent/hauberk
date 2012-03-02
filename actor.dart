/// An active entity in the game. Includes monsters and the hero.
class Actor {
  Pt pos;
  int energy;

  int get x() => pos.x;
  void set x(int value) => pos = new Pt(value, y);

  int get y() => pos.y;
  void set y(int value) => pos = new Pt(x, value);

  Actor(int x, int y)
  : pos = new Pt(x, y),
    energy = new Energy(Energy.NORMAL_SPEED);

  bool get canTakeTurn() => energy.canTakeTurn;

  bool gainEnergy() => energy.gain();

  bool get needsInput() => false;

  Action takeTurn() {
    // Do nothing.
  }
}

class Beetle extends Actor {
  Beetle(int x, int y) : super(x, y);

  void takeTurn() {
    switch (rand(4)) {
      case 0:
        if (y > 0) return new MoveAction(new Pt(0, -1));
        break;

      case 1:
        if (y < 19) return new MoveAction(new Pt(0, 1));
        break;

      case 2:
        if (x > 0) return new MoveAction(new Pt(-1, 0));
        break;

      case 3:
        if (x < 49) return new MoveAction(new Pt(1, 0));
        break;
    }

    return new MoveAction(new Pt(0, 0));
  }
}

class Hero extends Actor {
  Hero(int x, int y) : super(x, y);

  Action nextAction;

  bool get needsInput() => nextAction == null;

  void takeTurn() {
    final action = nextAction;
    nextAction = null;
    return action;
  }
}

/// Energy is used to control the rate that actors move relative to other
/// actors. Each game turn, every actor will accumulate energy based on their
/// speed. When it reaches a threshold, that actor can take a turn.
class Energy {
  static final MIN_SPEED    = 0;
  static final NORMAL_SPEED = 6;
  static final MAX_SPEED    = 12;

  static final ACTION_COST = 240;

  // How much energy is gained each game turn for each speed.
  static final ENERGY_GAINS = const [
    15,     // 1/4 normal speed
    20,     // 1/3 normal speed
    25,
    30,     // 1/2 normal speed
    40,
    50,
    60,     // normal speed
    80,
    100,
    120,    // 2x normal speed
    150,
    180,    // 3x normal speed
    240     // 4x normal speed
  ];

  int speed;
  int energy = 0;

  Energy(this.speed);

  bool get canTakeTurn() => energy >= ACTION_COST;

  /// Advances one game turn and gains an appropriate amount of energy. Returns
  /// `true` if there is enough energy to take a turn.
  bool gain() {
    energy += ENERGY_GAINS[speed];

    if (!canTakeTurn) return false;

    energy -= ACTION_COST;
    return true;
  }
}
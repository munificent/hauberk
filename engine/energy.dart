
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

  static num ticksAtSpeed(int speed) {
    return ACTION_COST / ENERGY_GAINS[NORMAL_SPEED + speed];
  }

  int speed;
  int energy = 0;

  Energy(this.speed);

  bool get canTakeTurn() => energy >= ACTION_COST;

  /// Advances one game turn and gains an appropriate amount of energy. Returns
  /// `true` if there is enough energy to take a turn.
  bool gain() {
    energy += ENERGY_GAINS[speed];
    return canTakeTurn;
  }

  /// Spends a turn's worth of energy.
  void spend() {
    assert(energy >= ACTION_COST);
    energy -= ACTION_COST;
  }
}
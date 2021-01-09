/// Energy is used to control the rate that actors move relative to other
/// actors. Each game turn, every actor will accumulate energy based on their
/// speed. When it reaches a threshold, that actor can take a turn.
class Energy {
  static const minSpeed = 0;
  static const normalSpeed = 6;
  static const maxSpeed = 12;

  static const actionCost = 240;

  // How much energy is gained each game turn for each speed.
  static const gains = [
    15, // 1/4 normal speed
    20, // 1/3 normal speed
    24, // 2/5 normal speed
    30, // 1/2 normal speed
    40, // 2/3 normal speed
    50, // 5/6 normal speed
    60, // normal speed
    80, // 4/3 normal speed
    100, // 5/3 normal speed
    120, // 2x normal speed
    150, // 3/2 normal speed
    180, // 3x normal speed
    240 // 4x normal speed
  ];

  int energy = 0;

  bool get canTakeTurn => energy >= actionCost;

  /// Advances one game turn and gains an appropriate amount of energy. Returns
  /// `true` if there is enough energy to take a turn.
  bool gain(int speed) {
    energy += gains[speed];
    return canTakeTurn;
  }

  /// Spends a turn's worth of energy.
  void spend() {
    assert(energy >= actionCost);
    energy -= actionCost;
  }
}

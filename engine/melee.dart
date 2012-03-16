
class Attack {
  final String verb;

  /// The average damage. The actual damage will be a `Rng.triangleInt` centered
  /// on this with a range of 1/2 of its value.
  final int damage;

  Attack(this.verb, this.damage);
}

class Hit {
  /// The attack.
  final Attack attack;

  int strike;

  Hit(this.attack);

  void bindDefense([int strike]) {
    this.strike = strike;
  }
}

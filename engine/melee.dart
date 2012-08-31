
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

  int armor = 0;

  Hit(this.attack);

  int rollDamage() {
    var damage = rng.triangleInt(attack.damage, attack.damage ~/ 2);
    damage *= getArmorMultiplier(armor);
    return damage.round().toInt();
  }
}

/// Armor reduces damage by an inverse curve such that increasing armor has
/// less and less effect. Damage is reduced to the following:
///
///     armor damage
///     ------------
///     0     100%
///     40    50%
///     80    33%
///     120   25%
///     160   20%
///     ...   etc.
num getArmorMultiplier(int armor) {
  // Damage is never increased.
  return 1.0 / (1.0 + max(0, armor) / 40.0);
}
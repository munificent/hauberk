import '../../engine.dart';
import '../action/heal.dart';

class HealMove extends Move {
  /// How much health to restore.
  final int _amount;

  @override
  num get experience => _amount;

  HealMove(super.rate, this._amount);

  @override
  bool shouldUse(Monster monster) {
    // Heal if it could heal the full amount, or it's getting close to death.
    return (monster.health / monster.maxHealth < 0.25) ||
        (monster.maxHealth - monster.health >= _amount);
  }

  @override
  Action onGetAction(Monster monster) {
    return HealAction(_amount);
  }

  @override
  String toString() => "Heal $_amount rate: $rate";
}

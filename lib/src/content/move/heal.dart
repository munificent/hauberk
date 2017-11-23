import '../../engine.dart';
import '../action/heal.dart';

class HealMove extends Move {
  /// How much health to restore.
  final int _amount;

  num get experience => _amount;

  HealMove(num rate, this._amount) : super(rate);

  bool shouldUse(Monster monster) {
    // Heal if it could heal the full amount, or it's getting close to death.
    return (monster.health.current / monster.health.max < 0.25) ||
        (monster.health.max - monster.health.current >= _amount);
  }

  Action onGetAction(Monster monster) {
    return new HealAction(_amount);
  }

  String toString() => "Heal $_amount rate: $rate";
}

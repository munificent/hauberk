import '../../engine.dart';
import '../action/condition.dart';

class HasteMove extends Move {
  final int _duration;
  final int _speed;

  @override
  num get experience => _duration * _speed;

  HasteMove(super.rate, this._duration, this._speed);

  @override
  bool shouldUse(Stage stage, Monster monster) {
    // Don't use if already hasted.
    return !monster.haste.isActive;
  }

  @override
  Action onGetAction(Monster monster) => HasteAction(_duration, _speed);

  @override
  String toString() => "Haste $_speed for $_duration turns rate: $rate";
}

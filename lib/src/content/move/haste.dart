import '../../engine.dart';
import '../action/condition.dart';

class HasteMove extends Move {
  final int _speed;
  final int _duration;

  @override
  num get experience => _duration * _speed;

  HasteMove(super.rate, this._speed, this._duration);

  @override
  bool shouldUse(Game game, Monster monster) {
    // Don't use if already hasted.
    return !monster.haste.isActive;
  }

  @override
  Action onGetAction(Game game, Monster monster) =>
      HasteAction(_speed, _duration);

  @override
  String toString() => "Haste $_speed for $_duration turns rate: $rate";
}

import '../../engine.dart';

class HasteMove extends Move {
  final int _duration;
  final int _speed;

  num get experience => _duration * _speed;

  HasteMove(num rate, this._duration, this._speed) : super(rate);

  bool shouldUse(Monster monster) {
    // Don't use if already hasted.
    return !monster.haste.isActive;
  }

  Action onGetAction(Monster monster) => new HasteAction(_duration, _speed);

  String toString() => "Haste $_speed for $_duration turns rate: $rate";
}

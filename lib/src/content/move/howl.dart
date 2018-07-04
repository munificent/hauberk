import '../../engine.dart';
import '../action/howl.dart';

class HowlMove extends Move {
  final int _range;

  num get experience => _range * 0.5;

  HowlMove(num rate, this._range) : super(rate);

  bool shouldUse(Monster monster) {
    // See if there are any sleeping monsters nearby.
    for (var actor in monster.game.stage.actors) {
      if (actor == monster) continue;

      // If we found someone asleep randomly consider howling.
      if (actor is Monster && (actor.pos - monster.pos) <= _range) {
        return true;
      }
    }

    return false;
  }

  Action onGetAction(Monster monster) => HowlAction(_range);

  String toString() => "Howl $_range";
}

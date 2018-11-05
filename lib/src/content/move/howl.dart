import '../../engine.dart';
import '../action/howl.dart';

class HowlMove extends Move {
  final int _range;
  final String _verb;

  num get experience => _range * 0.5;

  HowlMove(num rate, this._range, this._verb) : super(rate);

  bool shouldUse(Monster monster) {
    // Don't wake up others unless the hero is around.
    if (!monster.isVisibleToHero) return false;

    // See if there are any sleeping monsters nearby.
    for (var actor in monster.game.stage.actors) {
      if (actor == monster) continue;

      // If we found someone asleep, howl.
      if (actor is Monster &&
          actor.isAsleep &&
          (actor.pos - monster.pos) <= _range) {
        return true;
      }
    }

    return false;
  }

  Action onGetAction(Monster monster) => HowlAction(_range, _verb);

  String toString() => "Howl $_range";
}

import '../../engine.dart';
import '../action/howl.dart';

class HowlMove extends Move {
  final int _range;
  final String? _verb;

  @override
  num get experience => _range * 0.5;

  HowlMove(super.rate, this._range, this._verb);

  @override
  bool shouldUse(Game game, Monster monster) {
    // Don't wake up others unless the hero is around.
    // TODO: Should take sight into account.
    if (!game.stage.isVisibleToHero(monster)) return false;

    // See if there are any sleeping monsters nearby.
    for (var actor in game.stage.actors) {
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

  @override
  Action onGetAction(Game game, Monster monster) => HowlAction(_range, _verb);

  @override
  String toString() => "Howl $_range";
}

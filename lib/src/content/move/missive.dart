import '../../engine.dart';
import '../action/missive.dart';

class MissiveMove extends Move {
  final Missive _missive;

  MissiveMove(this._missive, num rate) : super(rate);

  num get experience => 0.0;

  bool shouldUse(Monster monster) {
    var target = monster.game.hero.pos;
    var distance = (target - monster.pos).kingLength;

    // Don't insult when in melee distance.
    if (distance <= 1) return false;

    // Don't insult someone it can't see.
    return monster.canView(target);
  }

  Action onGetAction(Monster monster) =>
      new MissiveAction(monster.game.hero, _missive);

  String toString() => "$_missive rate: $rate";
}

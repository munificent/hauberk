import '../../engine.dart';
import '../action/missive.dart';

class MissiveMove extends Move {
  final Missive _missive;

  MissiveMove(this._missive, num rate) : super(rate);

  @override
  num get experience => 0.0;

  @override
  bool shouldUse(Stage stage, Monster monster) {
    var target = monster.game.hero.pos;
    var distance = (target - monster.pos).kingLength;

    // Don't insult when in melee distance.
    if (distance <= 1) return false;

    // Don't insult someone it can't see.
    return monster.canView(target);
  }

  @override
  Action onGetAction(Monster monster) =>
      MissiveAction(monster.game.hero, _missive);

  @override
  String toString() => "$_missive rate: $rate";
}

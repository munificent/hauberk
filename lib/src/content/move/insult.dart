import '../../engine.dart';
import '../action/insult.dart';

class InsultMove extends Move {
  InsultMove(num rate) : super(rate);

  num get experience => 0.0;

  bool shouldUse(Monster monster) {
    var target = monster.game.hero.pos;
    var distance = (target - monster.pos).kingLength;

    // Don't insult when in melee distance.
    if (distance <= 1) return false;

    // Don't insult someone it can't see.
    return monster.canView(target);
  }

  Action onGetAction(Monster monster) => new InsultAction(monster.game.hero);

  String toString() => "Insult rate: $rate";
}

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/howl.dart';

class HowlMove extends Move {
  final int _range;

  num get experience => _range * 0.5;

  HowlMove(num rate, this._range) : super(rate);

  bool shouldUse(Monster monster) {
    // TODO: Is using flow here too slow?
    var flow = new Flow(monster.game.stage, monster.pos, MotilitySet.walkAndFly,
        maxDistance: _range,
        ignoreActors: true);

    // See if there are any sleeping monsters nearby.
    for (var pos in new Circle(monster.pos, _range)) {
      if (!monster.game.stage.bounds.contains(pos)) continue;
      if (flow.getDistance(pos) == null) continue;

      var actor = monster.game.stage.actorAt(pos);

      // If we found someone asleep randomly consider howling.
      if (actor is Monster && actor.isAsleep) return rng.oneIn(2);
    }

    return false;
  }

  Action onGetAction(Monster monster) => new HowlAction(_range);

  String toString() => "Howl $_range";
}

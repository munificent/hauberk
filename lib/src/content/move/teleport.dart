import '../../engine.dart';
import '../action/teleport.dart';

/// Teleports the [Monster] randomly from its current position.
class TeleportMove extends Move {
  final int _range;

  num get experience => _range * 0.7;

  TeleportMove(int cost, this._range) : super(cost);

  bool shouldUse(Monster monster) {
    if (monster.isAfraid) return true;

    var target = monster.game.hero.pos;
    var distance = (target - monster.pos).kingLength;

    // If we're next to the hero and want to start there, don't teleport away.
    if (monster.wantsToMelee && distance <= 1) return false;

    return true;
  }

  Action onGetAction(Monster monster) => new TeleportAction(_range);

  String toString() => "Teleport $_range";
}

import '../../engine.dart';
import '../action/teleport.dart';

/// Teleports the [Monster] randomly from its current position.
class TeleportMove extends Move {
  final int _range;

  @override
  num get experience => _range * 0.7;

  TeleportMove(super.rate, this._range);

  @override
  bool shouldUse(Game game, Monster monster) {
    if (monster.isAfraid) return true;

    var target = game.hero.pos;
    var distance = (target - monster.pos).kingLength;

    // If we're next to the hero and want to start there, don't teleport away.
    if (monster.wantsToMelee && distance <= 1) return false;

    return true;
  }

  @override
  Action onGetAction(Game game, Monster monster) => TeleportAction(_range);

  @override
  String toString() => "Teleport $_range";
}

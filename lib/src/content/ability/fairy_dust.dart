import '../../engine.dart';
import '../action/ray.dart';
import '../elements.dart';
import '../races.dart';

class FairyDustAbility extends Ability with ActionAbility {
  @override
  String get name => "Fairy Dust";

  @override
  List<Requirement> get requirements => [RaceRequirement(Races.fae)];

  @override
  Action onGetAction(Game game) {
    var damage = lerpInt(game.hero.vitality.value, 0, Stat.modifiedMax, 1, 20);
    var range = lerpInt(game.hero.strength.value, 0, Stat.modifiedMax, 1, 6);
    // TODO: Make this only dazzle and not simply a light attack?
    // TODO: Consume focus?
    return RingSelfAction(
      Attack(
        Prop.mass("dust"),
        "affects",
        damage,
        range: range,
        element: Elements.light,
      ),
    );
  }
}

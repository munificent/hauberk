import '../engine.dart';
import 'action/condition.dart';
import 'action/element.dart';

class Elements {
  // TODO: Teleport items.
  static final air = Element("air", "Ai", 1.2, attack: (_) => WindAction());
  static final earth = Element("earth", "Ea", 1.1);

  static final fire = Element("fire", "Fi", 1.2,
      emanates: true,
      destroyMessage: "burns up",
      attack: (_) => BurnActorAction(),
      floor: (pos, hit, distance, fuel) =>
          BurnFloorAction(pos, hit.averageDamage.toInt(), fuel));

  // TODO: Push back attack action.
  // TODO: Move items on floor.
  static final water = Element("water", "Wa", 1.3);

  // TODO: Destroy items on floor and in inventory.
  static final acid = Element("acid", "Ac", 1.4);

  static final cold = Element("cold", "Co", 1.2,
      destroyMessage: "shatters",
      attack: (damage) => FreezeActorAction(damage),
      floor: (pos, hit, distance, _) => FreezeFloorAction(pos));

  // TODO: Break glass items. Recharge some items?
  static final lightning = Element("lightning", "Ln", 1.1);

  static final poison = Element("poison", "Po", 2.0,
      attack: (damage) => PoisonAction(damage),
      floor: (pos, hit, distance, _) =>
          PoisonFloorAction(pos, hit.averageDamage.toInt()));

  // TODO: Remove tile emanation.
  static final dark =
      Element("dark", "Dk", 1.5, attack: (damage) => BlindAction(damage));

  static final light = Element("light", "Li", 1.5,
      attack: (damage) => DazzleAction(damage),
      floor: (pos, hit, distance, _) => LightFloorAction(pos, hit, distance));

  // TODO: Drain experience.
  static final spirit = Element("spirit", "Sp", 3.0);

  static final List<Element> all = [
    Element.none,
    air,
    earth,
    fire,
    water,
    acid,
    cold,
    lightning,
    poison,
    dark,
    light,
    spirit
  ];
}

import '../engine.dart';
import 'action/condition.dart';
import 'action/element.dart';

class Elements {
  // TODO: Teleport items.
  static final air =
      new Element("air", "Ai", 1.2, attack: (_) => new WindAction());
  static final earth = new Element("earth", "Ea", 1.1);

  // TODO: Start fires on the ground.
  static final fire = new Element("fire", "Fi", 1.2,
      attack: (_) => new BurnAction(),
      floor: (pos) =>
          new DestroyOnFloorAction(pos, 3, "flammable", "burns up"));

  // TODO: Push back attack action.
  // TODO: Move items on floor.
  static final water = new Element("water", "Wa", 1.3);

  // TODO: Destroy items on floor and in inventory.
  static final acid = new Element("acid", "Ac", 1.4);

  static final cold = new Element("cold", "Co", 1.2,
      attack: (damage) => new FreezeAction(damage),
      floor: (pos) =>
          new DestroyOnFloorAction(pos, 6, "freezable", "shatters"));

  // TODO: Break glass items. Recharge some items?
  static final lightning = new Element("lightning", "Ln", 1.1);

  static final poison = new Element("poison", "Po", 2.0,
      attack: (damage) => new PoisonAction(damage));

  // TODO: Remove tile emanation.
  static final dark = new Element("dark", "Dk", 1.5,
      attack: (damage) => new BlindAction(damage));

  static final light = new Element("light", "Li", 1.5,
      attack: (damage) => new DazzleAction(damage),
      floor: (pos) => new LightFloorAction(pos));

  // TODO: Drain experience.
  static final spirit = new Element("spirit", "Sp", 3.0);

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

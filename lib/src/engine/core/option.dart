// TODO: Should this be in content?
/// This contains all of the tunable game engine parameters. Tweaking these can
/// massively affect all aspects of gameplay.
class Option {
  static const maxDepth = 100;

  static const skillPointsPerLevel = 3;

  // TODO: Make variable based on will or something?
  static const maxFocus = 1000;

  /// How much damage an unarmed hero does.
  static const heroPunchDamage = 3;

  /// The amount of gold a new hero starts with.
  static const heroGoldStart = 60;

  /// The maximum number of items the hero's [Inventory] can contain.
  static const inventoryCapacity = 20;

  /// The maximum number of items the hero's home [Inventory] can contain.
  /// Note: To make this is more than 26, the home screen UI will need to be
  /// changed.
  static const homeCapacity = 20;

  /// The maximum number of items the hero's crucible can contain.
  static const crucibleCapacity = 8;

  /// The chance of trying to spawn a new monster in the unexplored dungeon
  /// each turn.
  static const spawnMonsterChance = 50;

  /// The experience point multipliers for each breed flag.
  static const expFlag = const {
    'fearless': 1.2,
    'protective': 1.1,
    'cowardly': 0.8,
    'berzerk': 1.2,
    'immobile': 0.7
  };

  /// The more a monster meanders, the less experience it's worth. This number
  /// should be larger than the largest meander value, and affects experience
  /// like so:
  ///
  ///     exp *= (expMeander - meander) / expMeander
  static const expMeander = 30;
}

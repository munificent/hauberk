import 'element.dart';

// TODO: Should this be in content?
/// This contains all of the tunable game engine parameters. Tweaking these can
/// massively affect all aspects of gameplay.
class Option {
  static final maxDepth = 100;

  /// The max health of a new hero.
  static final heroHealthStart = 20;

  /// How much max health is increased when the hero levels up.
  static final heroHealthGain = 10;

  /// How much damage an unarmed hero does.
  static final heroPunchDamage = 5;

  /// The highest level the hero can reach.
  static final heroLevelMax = 50;

  /// How much each level costs. This is multiplied by the (zero-based) level
  /// (squared) to determine how much experience is required to reach that
  /// level.
  static final heroLevelCost = 40;

  /// The amount of gold a new hero starts with.
  static final heroGoldStart = 60;

  /// The maximum number of items the hero's [Inventory] can contain.
  static final inventoryCapacity = 20;

  /// The maximum number of items the hero's home [Inventory] can contain.
  /// Note: To make this is more than 26, the home screen UI will need to be
  /// changed.
  static final homeCapacity = 20;

  /// The maximum number of items the hero's crucible can contain.
  static final crucibleCapacity = 8;

  /// When calculating pathfinding, how much it "costs" to move one step on
  /// an open floor tile.
  static final aStarFloorCost = 10;

  /// When calculating pathfinding, how much it costs to move one step on a
  /// tile already occupied by an actor. For pathfinding, we consider occupied
  /// tiles as accessible but expensive. The idea is that by the time the
  /// pathfinding monster gets there, the occupier may have moved, so the tile
  /// is "sorta" empty, but still not as desirable as an actually empty tile.
  static final aStarOccupiedCost = 60;

  /// When calculating pathfinding, how much it costs cross a currently-closed
  /// door. Instead of considering them completely impassable, we just have them
  /// be expensive, because it still may be beneficial for the monster to get
  /// closer to the door (for when the hero opens it later).
  static final aStarDoorCost = 80;

  /// When applying the pathfinding heuristic, straight steps (NSEW) are
  /// considered a little cheaper than diagonal ones so that straighter paths
  /// are preferred over equivalent but uglier zig-zagging ones.
  static final aStarStraightCost = 9;

  /// How much noise different kinds of actions make.
  static final noiseNormal = 10;
  static final noiseHit    = 50;
  static final noiseRest   =  1;

  /// The chance of trying to spawn a new monster in the unexplored dungeon
  /// each turn.
  static final spawnMonsterChance = 50;

  /// The maximum distance at which a monster will attempt a bolt attack.
  static final maxBoltDistance = 12;

  /// The experience point multipliers for each breed flag.
  static final expFlag = const {
    'horde': 1.5,
    'swarm': 1.4,
    'pack': 1.3,
    'group': 1.2,
    'few': 1.1,
    'open-doors': 1.1,
    'fearless': 1.2,
    'protective': 1.1,
    'cowardly': 0.8,
    'berzerk': 1.2,
    'immobile': 0.7
  };

  /// The experience point multipliers for an attack or move using a given
  /// element.
  static final expElement = const {
    Element.none: 1.0,
    Element.air: 1.2,
    Element.earth: 1.2,
    Element.fire: 1.1,
    Element.water: 1.3,
    Element.acid: 1.4,
    Element.cold: 1.2,
    Element.lightning: 1.1,
    Element.poison: 2.0,
    Element.dark: 1.5,
    Element.light: 1.5,
    Element.spirit: 3.0
  };

  /// The more a monster meanders, the less experience it's worth. This number
  /// should be larger than the largest meander value, and affects experience
  /// like so:
  ///
  ///     exp *= (expMeander - meander) / expMeander
  static final expMeander = 30;
}
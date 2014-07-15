library hauberk.engine.option;

/// This contains all of the tunable game engine parameters. Tweaking these can
/// massively affect all aspects of gameplay.
class Option {
  /// A resting actor regains health every `n` turns where `n` is this number
  /// divided by the actor's max health. Setting this to be larger makes actors
  /// regenerate more slowly.
  static final REST_MAX_HEALTH_FOR_RATE = 200;

  /// The max health of a new hero.
  static final HERO_HEALTH_START = 20;

  /// How much max health is increased when the hero levels up.
  static final HERO_HEALTH_GAIN = 6;

  /// How much damage an unarmed hero does.
  static final HERO_PUNCH_DAMAGE = 3;

  /// The highest level the hero can reach.
  static final HERO_LEVEL_MAX = 50;

  /// How much each level costs. This is multiplied by the (zero-based) level
  /// (squared) to determine how much experience is required to reach that
  /// level.
  static final HERO_LEVEL_COST = 40;

  /// The maximum number of items the hero's [Inventory] can contain.
  static final INVENTORY_CAPACITY = 20;

  /// The maximum number of items the hero's home [Inventory] can contain.
  /// Note: To make this is more than 26, the home screen UI will need to be
  /// changed.
  static final HOME_CAPACITY = 20;

  /// The maximum number of items the hero's crucible can contain.
  static final CRUCIBLE_CAPACITY = 8;

  /// When calculating pathfinding, how much it "costs" to move one step on
  /// an open floor tile.
  static final ASTAR_FLOOR_COST = 10;

  /// When calculating pathfinding, how much it costs to move one step on a
  /// tile already occupied by an actor. For pathfinding, we consider occupied
  /// tiles as accessible but expensive. The idea is that by the time the
  /// pathfinding monster gets there, the occupier may have moved, so the tile
  /// is "sorta" empty, but still not as desirable as an actually empty tile.
  static final ASTAR_OCCUPIED_COST = 60;

  /// When calculating pathfinding, how much it costs cross a currently-closed
  /// door. Instead of considering them completely impassable, we just have them
  /// be expensive, because it still may be beneficial for the monster to get
  /// closer to the door (for when the hero opens it later).
  static final ASTAR_DOOR_COST = 80;

  /// When applying the pathfinding heuristic, straight steps (NSEW) are
  /// considered a little cheaper than diagonal ones so that straighter paths
  /// are preferred over equivalent but uglier zig-zagging ones.
  static final ASTAR_STRAIGHT_COST = 9;

  /// How much noise different kinds of actions make.
  static final NOISE_NORMAL = 10;
  static final NOISE_HIT    = 50;
  static final NOISE_REST   =  1;

  /// Monsters have to recharge to recoup a move's cost. This is how quickly
  /// a monster recharges per monster turn.
  static final RECHARGE_RATE = 4;

  /// The chance of trying to spawn a new monster in the unexplored dungeon
  /// each turn.
  static final SPAWN_MONSTER_CHANCE = 40;

  /// The maximum distance at which a monster will attempt a bolt attack.
  static final MAX_BOLT_DISTANCE = 12;

  /// The experience point multipliers for each breed flag.
  static final EXP_FLAG = const {
    'horde': 1.5,
    'swarm': 1.4,
    'pack': 1.3,
    'group': 1.2,
    'few': 1.1,
    'open-doors': 1.1,
    'fearless': 1.2,
    'protective': 1.1,
    'cowardly': 0.8,
    'berzerk': 1.2
  };

  /// The more a monster meanders, the less experience it's worth. This number
  /// should be larger than the largest meander value, and affects experience
  /// like so:
  ///
  ///     exp *= (EXP_MEANDER - meander) / EXP_MEANDER
  static final EXP_MEANDER = 30;
}
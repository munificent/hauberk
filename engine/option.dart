/// This contains all of the tunable game engine parameters. Tweaking these can
/// massively affect all aspects of gameplay.
class Option {
  /// A resting actor regains health every `n` turns where `n` is this number
  /// divided by the actor's max health. Setting this to be larger makes actors
  /// regenerate more slowly.
  static final REST_MAX_HEALTH_FOR_RATE = 50;

  /// Each turn that the hero rests, there is a one in `REST_SPAWN_CHANCE` that
  /// the game will try to place a monster in a randomly selected tile if it
  /// happens to be empty and unexplored.
  static final REST_SPAWN_CHANCE = 6;

  /// The range of valid strike values. After calculating the strike, it will
  /// be clamped to this bounds and then the strike roll will be compared to it.
  /// A higher minimum means more strikes are guaranteed misses and a lower
  /// max means more guaranteed hits.
  static final STRIKE_MIN = 5;
  static final STRIKE_MAX = 95;

  static final STRIKE_MONSTER = 20;
  static final STRIKE_HERO = 20;

  /// The max health of a new hero.
  static final HERO_START_HEALTH = 20;

  /// The maximum number of steps of ideal pathfinding data that monsters can
  /// use. Increasing this lets monsters accurately find the hero from farther
  /// away, but increases processing time.
  static final MAX_PATH = 12;

  /// How much a monster's sense of smell (modified by olfaction) affects their
  /// choice of action.
  static final AI_WEIGHT_SCENT = 1.0;

  /// How much ideal pathfinding affects a monster's choice of action.
  static final AI_WEIGHT_PATH = 10.0;

  /// How much a breed's meander affects the monster's choice of action.
  static final AI_WEIGHT_MEANDER = 5.0;

  /// How much scent is added each turn to the hero's tile. This is basically
  /// how "strong" the hero smells.
  static final SCENT_HERO = 0.2;

  /// How much scent fades over time (a multiplier). Note that because scent
  /// decays by multiplication, it will almost never actually reach zero. That
  /// means there is a functional scent gradient across the entire level. To
  /// prevent monsters from being able to track the hero from across the level,
  /// they have a scent "threshold" which is a minimum value required for them
  /// to be able to pick up the scent.
  static final SCENT_DECAY = 0.98;

  static final SCENT_SUBTRACT = 0.001;

  /// Scent spreads using a simple 3x3 convolution filter. These two options
  /// control how much weight tiles next to and diagonal to the center tile
  /// affect the result. (The center tile's weight is always 1.0). The
  /// difference between these two values affects the shape that scent
  /// disperses: squarish, diamond, or circular.
  static final SCENT_CORNER_CONVOLVE = 0.2;
  static final SCENT_SIDE_CONVOLVE = 0.5;
}
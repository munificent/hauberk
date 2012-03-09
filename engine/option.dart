/// This contains all of the tunable game engine parameters. Tweaking these can
/// massively affect all aspects of gameplay.
class Option {
  /// How much scent is added each turn to the hero's tile. This is basically
  /// how "strong" the hero smells.
  static final SCENT_HERO = 12;

  /// The maximum smell intensity that a tile can hold. The higher this is, the
  /// longer a tile "remembers" that the hero was there. Setting this too high
  /// means monsters will tend to go where the hero was the longest and not
  /// where he was most recently. Setting it too low means scent won't
  /// distribute as far or linger as long.
  static final SCENT_MAX = 6;

  /// How much scent fades over time (a multiplier). Note that because scent
  /// decays by multiplication, it will almost never actually reach zero. That
  /// means there is a functional scent gradient across the entire level. To
  /// prevent monsters from being able to track the hero from across the level,
  /// they have a scent "threshold" which is a minimum value required for them
  /// to be able to pick up the scent.
  static final SCENT_DECAY = 0.95;

  /// Scent spreads using a simple 3x3 convolution filter. These two options
  /// control how much weight tiles next to and diagonal to the center tile
  /// affect the result. (The center tile's weight is always 1.0). The
  /// difference between these two values affects the shape that scent
  /// disperses: squarish, diamond, or circular.
  static final SCENT_CORNER_CONVOLVE = 0.2;
  static final SCENT_SIDE_CONVOLVE = 0.5;
}
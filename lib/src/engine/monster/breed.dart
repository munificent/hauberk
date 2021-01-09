import 'package:piecemeal/piecemeal.dart';

import '../core/combat.dart';
import '../core/energy.dart';
import '../core/game.dart';
import '../core/log.dart';
import '../core/math.dart';
import '../hero/hero.dart';
import '../items/item.dart';
import '../items/item_type.dart';
import '../stage/tile.dart';
import 'monster.dart';
import 'move.dart';

/// A lazy named reference to a Breed.
///
/// This allows cyclic references while the breeds are still being defined.
class BreedRef {
  static final List<BreedRef> _unresolved = [];

  static void resolve(Breed Function(String) resolver) {
    for (var ref in _unresolved) {
      assert(ref._breed == null, "Already resolved.");
      ref._breed = resolver(ref._name);
    }

    _unresolved.clear();
  }

  final String _name;
  Breed _breed;
  Breed get breed {
    assert(_breed != null, "Breed is not resolved yet.");
    return _breed;
  }

  BreedRef(this._name) {
    _unresolved.add(this);
  }
}

/// A single kind of [Monster] in the game.
class Breed {
  final Pronoun pronoun;
  String get name => Log.singular(_name);

  /// Untyped so the engine isn't coupled to how monsters appear.
  final Object appearance;

  /// The breeds's depth.
  ///
  /// Higher depth breeds are found later in the game.
  final int depth;

  final List<Attack> attacks;
  final List<Move> moves;

  final int maxHealth;

  /// How well the monster can navigate the stage to reach its target.
  ///
  /// Used to determine maximum pathfinding distance.
  final int tracking;

  /// How many tiles away the monster can see the hero.
  final int vision;

  /// How many tiles away (as sound flows) the monster can hear the hero.
  final int hearing;

  /// Percent chance of choosing a non-optimal direction when walking.
  final int meander;

  /// The breed's speed, relative to normal. Ranges from `-6` (slowest) to `6`
  /// (fastest) where `0` is normal speed.
  final int speed;

  /// The [Item]s this monster may drop when killed.
  final Drop drop;

  final SpawnLocation location;

  final Motility motility;

  final BreedFlags flags;

  /// Base chance for this breed to dodge an attack.
  final int dodge;

  /// How much light the monster emanates.
  final int emanationLevel;

  /// Additional defenses this breed has.
  final List<Defense> defenses = [];

  /// The minimum number of this breed that are spawned when it is placed in
  /// the dungeon.
  final int countMin;

  /// The minimum number of this breed that are spawned when it is placed in
  /// the dungeon.
  final int countMax;

  /// Additional monsters that should be spawned when this one is spawned.
  final Spawn minions;

  /// The name of the breed. If the breed's name has irregular pluralization
  /// like "bunn[y|ies]", this will be the original unparsed string.
  final String _name;

  /// If this breed should stain some of the nearby floor tiles when spawned,
  /// this is the type is should stain them with. Otherwise null.
  final TileType stain;

  /// The groups that the breed is a part of.
  ///
  /// Used to determine which kinds of slaying affect which monsters. For
  /// display purposes in the lore screen, the last group in the list should
  /// be noun-like while the others are adjectives, like `["undead", "bug"]`.
  final List<String> groups = [];

  final String description;

  Breed(this._name, this.pronoun, this.appearance, this.attacks, this.moves,
      this.drop, this.location, this.motility,
      {this.depth,
      this.maxHealth,
      this.tracking,
      int vision,
      int hearing,
      this.meander,
      int speed,
      int dodge,
      int emanationLevel,
      this.countMin,
      this.countMax,
      this.minions,
      this.stain,
      BreedFlags flags,
      this.description})
      : vision = vision ?? 8,
        hearing = hearing ?? 10,
        speed = speed ?? 0,
        dodge = dodge ?? 20,
        emanationLevel = emanationLevel ?? 0,
        flags = flags ?? BreedFlags();

  /// How much experience a level one [Hero] gains for killing a [Monster] of
  /// this breed.
  ///
  /// The basic idea is that experience roughly correlates to how much damage
  /// the monster can dish out to the hero before it dies.
  int get experience {
    // The more health it has, the longer it can hurt the hero.
    var exp = maxHealth.toDouble();

    // The more it can dodge, the longer it lives.
    var totalDodge = dodge;
    for (var defense in defenses) {
      totalDodge += defense.amount;
    }

    exp *= 1.0 + totalDodge / 100.0;

    // Faster monsters can hit the hero more often.
    exp *= Energy.gains[Energy.normalSpeed + speed];

    // Average the attacks, since they are selected randomly.
    var attackTotal = 0.0;
    for (var attack in attacks) {
      // TODO: Take range into account?
      attackTotal += attack.damage * attack.element.experience;
    }

    attackTotal /= attacks.length;

    // Average the moves.
    var moveTotal = 0.0;
    var moveRateTotal = 0.0;
    for (var move in moves) {
      // Scale by the move rate. The less frequently a move can be performed,
      // the less it affects experience.
      moveTotal += move.experience / move.rate;
      moveRateTotal += 1 / move.rate;
    }

    // Time spent using moves is not time spent attacking.
    attackTotal *= 1.0 - moveRateTotal;

    // Add in moves and attacks.
    exp *= attackTotal + moveTotal;

    // Take into account flags.
    exp *= flags.experienceScale;

    // TODO: Modify by motility?
    // TODO: Modify by count?
    // TODO: Modify by minions.

    // Meandering monsters are worth less.
    exp *= lerpDouble(meander, 0.0, 100.0, 1.0, 0.7);

    // Scale it down arbitrarily to keep the numbers reasonable. This is tuned
    // so that the weakest monsters can still have some variance in experience
    // when rounded to an integer.
    exp /= 40;

    return exp.ceil();
  }

  Monster spawn(Game game, Vec pos, [Monster parent]) {
    var generation = 1;
    if (parent != null) generation = parent.generation + 1;

    return Monster(game, this, pos.x, pos.y, generation);
  }

  /// Generate the list of breeds spawned by this breed.
  ///
  /// Each item in the list represents a breed that should spawn a single
  /// monster. Takes into account this breed's count and minions.
  List<Breed> spawnAll() {
    var breeds = <Breed>[];

    // This breed.
    var count = rng.inclusive(countMin, countMax);
    for (var i = 0; i < count; i++) {
      breeds.add(this);
    }

    if (minions != null) {
      // Minions are weaker than the main breed.
      var minionDepth = (depth * 0.9).floor();
      minions.spawnBreed(minionDepth, breeds.add);
    }

    return breeds;
  }

  String toString() => name;
}

// TODO: Should this affect how the monster moves during the game too?
/// Where in the dungeon the breed prefers to spawn.
enum SpawnLocation {
  anywhere,

  /// Away from walls.
  open,

  /// Adjacent to a wall.
  wall,

  /// Adjacent to multiple walls.
  corner,
}

typedef AddMonster = void Function(Breed breed);

abstract class Spawn {
  void spawnBreed(int depth, AddMonster addMonster);
}

class BreedFlags {
  final bool berzerk;
  final bool cowardly;
  final bool fearless;
  final bool immobile;
  final bool protective;
  final bool unique;

  BreedFlags(
      {this.berzerk,
      this.cowardly,
      this.fearless,
      this.immobile,
      this.protective,
      this.unique});

  /// The way this set of flags affects the experience gained when killing a
  /// monster.
  double get experienceScale {
    var scale = 1.0;

    if (berzerk) scale *= 1.1;
    if (cowardly) scale *= 0.9;
    if (fearless) scale *= 1.05;
    if (immobile) scale *= 0.7;
    if (protective) scale *= 1.1;

    return scale;
  }

  factory BreedFlags.fromSet(Set<String> names) {
    names = names.toSet();

    var flags = BreedFlags(
        berzerk: names.remove("berzerk"),
        cowardly: names.remove("cowardly"),
        fearless: names.remove("fearless"),
        immobile: names.remove("immobile"),
        protective: names.remove("protective"),
        unique: names.remove("unique"));

    if (names.isNotEmpty) {
      throw ArgumentError('Unknown flags "${names.join(', ')}"');
    }

    return flags;
  }

  String toString() {
    return [
      if (berzerk) "berzerk",
      if (cowardly) "cowardly",
      if (fearless) "fearless",
      if (immobile) "immobile",
      if (protective) "protective",
      if (unique) "unique",
    ].join(" ");
  }
}

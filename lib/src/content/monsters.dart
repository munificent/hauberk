library dngn.content.monsters;

import '../engine.dart';
import '../util.dart';
import 'builder.dart';

/// Builder class for defining [Monster] [Breed]s.
class Monsters extends ContentBuilder {
  static final Map<String, Breed> all = {};

  /// The default tracking for a breed that doesn't specify it.
  var _tracking;

  /// The default meander for a breed that doesn't specify it.
  var _meander;

  /// The current glyph. Any items defined will use this. Can be a string or
  /// a character code.
  var _glyph;

  void build() {
    // $  Creeping Coins
    // a  Arachnid/Scorpion   A  Ancient being
    // b  Giant Bat           B  Bird
    // c  Canine (Dog)        C  Canid (Dog-like humanoid, kobold)
    // d  Dragon              D  Ancient Dragon
    // e  Floating Eye        E  Elemental
    // f  Flying Insect       F  Feline (Cat)
    // g  Ghost               G  Golem
    // h  Humanoids           H  Hybrid
    // i  Insect              I  Goblin / Imp
    // j  Jelly               J  Slime
    // k  Skeleton            K  Kraken/Land Octopus
    // l  Lizard man          L  Lich
    // m  Mold/Mushroom       M  Multi-Headed Hydra
    // n  Naga                N  Demon
    // o  Orc                 O  Ogre
    // p  Human "person"      P  Giant "person"
    // q  Quadruped           Q  End boss ("quest")
    // r  Rodent/Rabbit       R  Reptile/Amphibian
    // s  Slug                S  Snake
    // t  Troglodyte          T  Troll
    // u  Minor Undead        U  Major Undead
    // v  Vine/Plant          V  Vampire
    // w  Worm or Worm Mass   W  Wight/Wraith
    // x  (unused)            X  Xorn/Xaren
    // y  Yeek                Y  Yeti
    // z  Zombie/Mummy        Z  Serpent (snake-like dragon)
    // TODO(bob):
    // - Come up with something better than yeeks for "y".
    // - Don't use both "u" and "U" for undead?

    var categories = [
      arachnids,
      bats,
      birds,
      canines,
      flyingInsects,
      felines,
      humanoids,
      insects,
      imps,
      jellies,
      skeletons,
      people,
      quadrupeds,
      rodents,
      reptiles,
      slugs,
      snakes,
      worms
    ];

    for (var category in categories) {
      category();
    }
  }

  arachnids() {
    group("a");
    breed("garden spider", darkAqua, 2, [
        attack("bite[s]", 1, Element.POISON)
      ],
      drop: chanceOf(3, "Stinger"),
      meander: 8, flags: "group fearless");

    breed("brown spider", brown, 3, [
        attack("bite[s]", 2, Element.POISON)
      ],
      drop: chanceOf(5, "Stinger"),
      meander: 8, flags: "group fearless");

    breed("giant spider", darkBlue, 12, [
        attack("bite[s]", 3, Element.POISON)
      ],
      drop: chanceOf(10, "Stinger"),
      meander: 5, flags: "fearless");
  }

  bats() {
    group("b");
    breed("little brown bat", lightBrown, 3, [
        attack("bite[s]", 3),
      ],
      meander: 6, speed: 2);

    breed("giant bat", lightBrown, 12, [
        attack("bite[s]", 8),
      ],
      meander: 4, speed: 2);
  }

  birds() {
    group("B");
    breed("robin", lightRed, 3, [
        attack("claw[s]", 1),
      ],
      drop: chanceOf(25, "Red Feather"),
      meander: 4, speed: 2);

    breed("crow", darkGray, 4, [
        attack("bite[s]", 4),
      ],
      drop: chanceOf(25, "Black Feather"),
      meander: 4, speed: 2, flags: "group");

    breed("raven", gray, 8, [
        attack("bite[s]", 6),
        attack("claw[s]", 5),
      ],
      drop: hunting("Black Feather"),
      meander: 1, flags: "protective");
  }

  canines() {
    group("c", tracking: 20, meander: 3);
    breed("mangy cur", yellow, 7, [
        attack("bite[s]", 4),
      ],
      drop: hunting(chanceOf(70, "Fur Pelt")),
      flags: "few");

    breed("wild dog", gray, 9, [
        attack("bite[s]", 5),
      ],
      drop: hunting("Fur Pelt"),
      flags: "few");

    breed("mongrel", orange, 11, [
        attack("bite[s]", 7),
      ],
      drop: hunting("Fur Pelt"),
      flags: "few");
  }

  flyingInsects() {
    group("i", tracking: 5, meander: 8);
    breed("butterfl[y|ies]", lightPurple, 1, [
        attack("tickle[s] on", 1),
      ],
      drop: hunting("Insect Wing"),
      speed: 2, flags: "few fearless");

    breed("bee", yellow, 1, [
        attack("sting[s]", 2),
      ],
      drop: chanceOf(40, "Honeycomb"),
      speed: 1, flags: "group protective");

    breed("wasp", brown, 1, [
        attack("sting[s]", 2, Element.POISON),
      ],
      drop: chanceOf(30, "Stinger"),
      speed: 2, flags: "berzerk");
  }

  felines() {
    group("F");
    breed("stray cat", lightOrange, 5, [
        attack("bite[s]", 4),
        attack("scratch[es]", 3),
      ],
      drop: hunting(chanceOf(50, "Fur Pelt")),
      meander: 3, speed: 1);
  }

  humanoids() {
  }

  insects() {
    group("i", tracking: 3, meander: 8);
    breed("giant cockroach[es]", darkBrown, 12, [
        attack("crawl[s] on", 1),
      ],
      drop: hunting("Insect Wing"),
      speed: 3, flags: "fearless");

    breed("giant centipede", red, 12, [
        attack("crawl[s] on", 3),
        attack("bite[s]", 6),
      ],
      speed: 2, flags: "fearless");
  }

  imps() {
    group("I");
    breed("scurrilous imp", lightRed, 14, [
        attack("club[s]", 6),
        insult(),
        haste()
      ],
      drop: [
        chanceOf(10, "club:1"),
        chanceOf(5, "speed:1"),
      ],
      meander: 4, flags: "cowardly open-doors");

    breed("vexing imp", purple, 12, [
        attack("scratch[es]", 5),
        insult(),
        sparkBolt(cost: 10, damage: 8)
      ],
      drop: [
        chanceOf(10, "teleportation:1"),
      ],
      meander: 4, speed: 1, flags: "cowardly open-doors");

    breed("impish incanter", lightPurple, 16, [
        attack("scratch[es]", 5),
        insult(),
        fireBolt(cost: 10, damage: 10)
      ],
      drop: [
        chanceOf(10, "magic:1"),
      ],
      meander: 4, speed: 1, flags: "cowardly open-doors");

    breed("goblin peon", lightBrown, 16, [
        attack("stab[s]", 6)
      ],
      drop: [
        chanceOf(10, "spear:3"),
        chanceOf(5, "healing:2"),
      ],
      meander: 2, flags: "few open-doors");

    breed("goblin archer", green, 14, [
        attack("stab[s]", 3),
        arrow(cost: 8, damage: 4)
      ],
      drop: [
        chanceOf(20, "bow:1"),
        chanceOf(10, "dagger:2"),
        chanceOf(5, "healing:3"),
      ],
      meander: 2, flags: "few open-doors");

    breed("goblin fighter", brown, 24, [
        attack("stab[s]", 8)
      ],
      drop: [
        chanceOf(15, "spear:5"),
        chanceOf(5, "healing:3"),
      ],
      meander: 1, flags: "open-doors");

    breed("imp warlock", darkPurple, 20, [
        attack("stab[s]", 6),
        iceBolt(cost: 7, damage: 12),
        fireBolt(cost: 7, damage: 12)
      ],
      drop: [
        chanceOf(10, "magic:4"),
      ],
      meander: 3, speed: 1, flags: "cowardly open-doors");

    breed("goblin warrior", gray, 32, [
        attack("stab[s]", 14)
      ],
      drop: [
        chanceOf(20, "spear:6"),
        chanceOf(5, "healing:3"),
      ],
      meander: 1, flags: "protective open-doors");
  }

  jellies() {
    group("j", tracking: 2, meander: 4);
    breed("green slime", green, 10, [
        attack("crawl[s] on", 3, Element.POISON)
      ],
      flags: "few fearless");

    breed("blue slime", blue, 12, [
        attack("crawl[s] on", 4, Element.COLD)
      ],
      flags: "few fearless");

    breed("red slime", blue, 14, [
      attack("crawl[s] on", 6, Element.FIRE)
    ],
    flags: "few fearless");
  }

  skeletons() {

  }

  quadrupeds() {
    group("q");
    breed("fox", orange, 12, [
        attack("bite[s]", 7),
        attack("scratch[es]", 4)
      ],
      drop: "Fox Pelt",
      meander: 1, speed: 1);
  }

  people() {
    group("p", tracking: 14);
    breed("simpering knave", orange, 6, [
        attack("hit[s]", 2),
        attack("stab[s]", 4)
      ],
      drop: allOf([
        chanceOf(50, "dagger:1"),
        chanceOf(40, "body:1"),
        chanceOf(20, "boots:1"),
        chanceOf(8, "magic:1"),
      ]),
      meander: 3, flags: "open-doors cowardly");

    breed("decrepit mage", purple, 6, [
        attack("hit[s]", 2),
        sparkBolt(cost: 30, damage: 8)
      ],
      drop: allOf([
        chanceOf(20, "magic:3"),
        chanceOf(30, ["dagger:1", "staff:1"]),
        chanceOf(40, "robe:1"),
        chanceOf(10, "boots:1")
      ]),
      meander: 2, flags: "open-doors");

    breed("unlucky ranger", green, 10, [
        attack("stab[s]", 2),
        arrow(cost: 10, damage: 2)
      ],
      drop: [
        chanceOf(10, "potion:3"),
        chanceOf(4, "bow:4"),
        chanceOf(10, "dagger:3"),
        chanceOf(8, "body:3")
      ],
      meander: 2, flags: "open-doors");

    breed("drunken priest", aqua, 9, [
        attack("hit[s]", 3),
        heal(cost: 30, amount: 8)
      ],
      drop: [
        chanceOf(10, "scroll:3"),
        chanceOf(7, "club:2"),
        chanceOf(7, "robe:2")
      ],
      meander: 4, flags: "open-doors fearless");
  }

  rodents() {
    group("r");
    breed("field [mouse|mice]", lightBrown, 3, [
        attack("bite[s]", 3),
        attack("scratch[es]", 2)
      ],
      meander: 4, speed: 1);

    breed("fuzzy bunn[y|ies]", lightBlue, 10, [
        attack("bite[s]", 3),
        attack("kick[s]", 2)
      ],
      meander: 2);

    breed("vole", darkGray, 5, [
        attack("bite[s]", 4)
      ],
      meander: 3, speed: 1);

    breed("white [mouse|mice]", white, 6, [
        attack("bite[s]", 5),
        attack("scratch[es]", 3)
      ],
      meander: 4, speed: 1);

    breed("sewer rat", darkGray, 6, [
        attack("bite[s]", 4),
        attack("scratch[es]", 3)
      ],
      meander: 3, speed: 1, flags: "group");
  }

  reptiles() {
    group("R");
    breed("frog", green, 4, [
        attack("hop[s] on", 2),
      ],
      meander: 4, speed: 1);
  }

  slugs() {
    group("s", tracking: 2);
    breed("giant slug", green, 12, [
        attack("crawl[s] on", 5, Element.POISON),
      ],
      meander: 1, speed: -3, flags: "fearless");
  }

  snakes() {
    group("S", meander: 4);
    breed("garter snake", gold, 4, [
        attack("bite[s]", 1),
      ]);

    breed("tree snake", lightGreen, 12, [
        attack("bite[s]", 8),
      ]);
  }

  worms() {
    group("w", meander: 4);
    breed("giant earthworm", lightRed, 16, [
        attack("crawl[s] on", 8),
      ],
      speed: -2, flags: "fearless");

    breed("maggot", lightGray, 2, [
        attack("crawl[s] on", 5),
      ],
      flags: "swarm fearless");

    breed("giant cave worm", white, 36, [
        attack("crawl[s] on", 8, Element.ACID),
      ],
      speed: -2, flags: "fearless");
  }

  void group(glyph, {int meander, int tracking}) {
    _glyph = glyph;
    _meander = meander != null ? meander : 0;
    _tracking = tracking != null ? tracking : 10;
  }

  Breed breed(String name, Glyph appearance(char), int health, List actions, {
      drop, int tracking, int meander, int speed: 0,
      String flags}) {
    if (tracking == null) tracking = _tracking;
    if (meander == null) meander = _meander;

    var attacks = <Attack>[];
    var moves = <Move>[];

    for (final action in actions) {
      if (action is Attack) attacks.add(action);
      if (action is Move) moves.add(action);
    }

    drop = parseDrop(drop);

    var flagSet;
    if (flags != null) {
      flagSet = new Set<String>.from(flags.split(" "));
    } else {
      flagSet = new Set<String>();
    }

    final breed = new Breed(name, Pronoun.IT, appearance(_glyph), attacks,
        moves, drop, maxHealth: health, tracking: tracking, meander: meander,
        speed: speed, flags: flagSet);
    Monsters.all[breed.name] = breed;
    return breed;
  }

  Move heal({int cost, int amount}) => new HealMove(cost, amount);

  Move arrow({int cost, int damage}) =>
      new BoltMove(cost, new Attack("hits", damage, Element.NONE,
          new Noun("the arrow")));

  Move sparkBolt({int cost, int damage}) =>
      new BoltMove(cost, new Attack("zaps", damage, Element.LIGHTNING,
          new Noun("the spark")));

  Move iceBolt({int cost, int damage}) =>
      new BoltMove(cost, new Attack("freezes", damage, Element.COLD,
          new Noun("the ice")));

  Move fireBolt({int cost, int damage}) =>
      new BoltMove(cost, new Attack("burns", damage, Element.FIRE,
          new Noun("the flame")));

  Move insult({int cost: 20}) => new InsultMove(cost);

  Move haste({int cost: 20, int duration: 10, int speed: 1}) =>
      new HasteMove(cost, duration, speed);
}

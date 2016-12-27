import 'package:malison/malison.dart';

import '../engine.dart';
import 'utils.dart';
import 'drops.dart';

/// The default tracking for a breed that doesn't specify it.
int _tracking;

/// The default speed for breeds in the current group. If the breed
/// specifies a speed, it is added to this.
int _speed;

/// The default meander for breeds in the current group. If the breed
/// specifies a meander, it is added to this.
int _meander;

/// Default flags for the current group.
String _flags;

/// The current glyph. Any items defined will use this. Can be a string or
/// a character code.
var _glyph;

/// Static class containing all of the [Monster] [Breed]s.
class Monsters {
  static final Map<String, Breed> all = {};

  static void initialize() {
    // a  Arachnid/Scorpion   A  Ancient being
    // b  Giant Bat           B  Bird
    // c  Canine (Dog)        C  Canid (Dog-like humanoid)
    // d  Dragon              D  Ancient Dragon
    // e  Floating Eye        E  Elemental
    // f  Flying Insect       F  Feline (Cat)
    // g  Goblin              G  Golem
    // h  Humanoids           H  Hybrid
    // i  Insect              I  Insubstantial (ghost)
    // j  Jelly/Slime         J  (unused)
    // k  Kobold/Imp/ete   K  Kraken/Land Octopus
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
    // x  Skeleton            X  Xorn/Xaren
    // y  Yeek                Y  Yeti
    // z  Zombie/Mummy        Z  Serpent (snake-like dragon)
    // TODO:
    // - Come up with something better than yeeks for "y".
    // - Don't use both "u" and "U" for undead?

    var categories = [
      arachnids,      ancients,
      bats,           birds,
      canines,        canids,
      eyes,           elementals,
      flyingInsects,  felines,
      goblins,        golems,
      humanoids,      hybrids,
      insects,        insubstantials,
      jellies,        // J unused
      kobolds,        krakens,
      lizardMen,      lichs,
      mushrooms,      hydras,
      nagas,          demons,
      orcs,           ogres,
      people,         giants,
      quadrupeds,
      rodents,        reptiles,
      slugs,          snakes,
      worms,
      skeletons
    ];

    for (var category in categories) {
      category();
    }

    // Feng
    // Erlkonig, the Goblin Prince
  }
}

arachnids() {
  group("a", flags: "fearless");
  breed("garden spider", darkAqua, 2, [
    attack("bite[s]", 2)
  ], drop: percent(3, "Stinger"),
      meander: 8, flags: "group");

  breed("brown spider", brown, 1, [
    attack("bite[s]", 15, Element.poison)
  ], drop: percent(5, "Stinger"),
      meander: 8);

  breed("giant spider", darkBlue, 20, [
    attack("bite[s]", 5, Element.poison)
  ], drop: percent(10, "Stinger"),
      meander: 5);
}

ancients() {

}

bats() {
  group("b");
  breed("brown bat", lightBrown, 9, [
    attack("bite[s]", 4),
  ], meander: 6, speed: 2);

  breed("giant bat", lightBrown, 16, [
    attack("bite[s]", 6),
  ], meander: 4, speed: 2);

  breed("cave bat", gray, 10, [
    attack("bite[s]", 6),
  ], meander: 3, speed: 3, flags: "group");
}

birds() {
  group("B");
  breed("robin", lightRed, 3, [
    attack("claw[s]", 1),
  ], drop: percent(25, "Red Feather"),
      meander: 4, speed: 2);

  breed("crow", darkGray, 9, [
    attack("bite[s]", 5),
  ], drop: percent(25, "Black Feather"),
      meander: 4, speed: 2, flags: "group");

  breed("raven", gray, 12, [
    attack("bite[s]", 5),
    attack("claw[s]", 4),
  ], drop: percent(20, "Black Feather"),
      meander: 1, flags: "protective");
}

canines() {
  group("c", tracking: 20, meander: 3, flags: "few");
  breed("mangy cur", yellow, 11, [
    attack("bite[s]", 4),
    howl(range: 6)
  ], drop: percent(20, "Fur Pelt"));

  breed("wild dog", gray, 16, [
    attack("bite[s]", 4),
    howl(range: 8)
  ], drop: percent(20, "Fur Pelt"));

  breed("mongrel", orange, 28, [
    attack("bite[s]", 6),
    howl(range: 10)
  ], drop: percent(20, "Fur Pelt"));
}

canids() {
}

eyes() {
  group("e", flags: "immobile");
  breed("lazy eye", white, 16, [
    attack("gaze[s] into", 6),
    sparkBolt(rate: 7, damage: 10, range: 5),
    teleport(rate: 9, range: 4)
  ]);

  group("e", flags: "immobile");
  breed("floating eye", yellow, 30, [
    attack("touch[es]", 4),
    lightBolt(rate: 5, damage: 16),
    teleport(rate: 8, range: 7)
  ]);

  // baleful eye, malevolent eye, murderous eye
}

elementals() {

}

flyingInsects() {
  group("f", tracking: 5, meander: 8);
  breed("butterfl[y|ies]", lightPurple, 1, [
    attack("tickle[s] on", 1),
  ], drop: percent(20, "Insect Wing"),
      speed: 2, flags: "few fearless");

  breed("bee", yellow, 1, [
    attack("sting[s]", 2),
  ], speed: 1, flags: "group protective");

  breed("wasp", brown, 1, [
    attack("sting[s]", 2, Element.poison),
  ], drop: percent(30, "Stinger"),
      speed: 2, flags: "berzerk");
}

felines() {
  group("F");
  breed("stray cat", gold, 9, [
    attack("bite[s]", 3),
    attack("scratch[es]", 2),
  ], drop: percent(10, "Fur Pelt"),
      meander: 3, speed: 1);
}

goblins() {
  group("g", meander: 1, flags: "open-doors");
  breed("goblin peon", lightBrown, 20, [
    attack("stab[s]", 5)
  ], drop: [
    percent(10, "spear", 3),
    percent(5, "healing", 2),
  ], meander: 2, flags: "few");

  breed("goblin archer", green, 22, [
    attack("stab[s]", 3),
    arrow(rate: 3, damage: 4)
  ], drop: [
    percent(20, "bow", 1),
    percent(10, "dagger", 2),
    percent(5, "healing", 3),
  ], flags: "few");

  breed("goblin fighter", brown, 30, [
    attack("stab[s]", 7)
  ], drop: [
    percent(15, "spear", 5),
    percent(10, "armor", 5),
    percent(5, "resistance", 3),
    percent(5, "healing", 3),
  ]);

  breed("goblin warrior", gray, 42, [
    attack("stab[s]", 10)
  ], drop: [
    percent(20, "axe", 6),
    percent(20, "armor", 6),
    percent(5, "resistance", 3),
    percent(5, "healing", 3),
  ], flags: "protective");

  breed("goblin mage", blue, 30, [
    attack("whip[s]", 7),
    fireBolt(rate: 12, damage: 6),
    sparkBolt(rate: 12, damage: 8),
  ], drop: [
    percent(10, "equipment", 5),
    percent(10, "whip", 5),
    percent(20, "magic", 6),
  ]);

  breed("goblin ranger", darkGreen, 36, [
    attack("stab[s]", 10),
    arrow(rate: 3, damage: 8)
  ], drop: [
    percent(30, "bow", 11),
    percent(20, "armor", 8),
    percent(20, "magic", 8)
  ]);

  // TODO: Always drop something good.
  breed("Erlkonig, the Goblin Prince", darkGray, 80, [
    attack("hit[s]", 10),
    attack("slash[es]", 14),
    darkBolt(rate: 20, damage: 10),
  ], drop: dropAllOf([
    percent(60, "equipment", 10),
    percent(60, "equipment", 10),
    percent(40, "magic", 12),
  ]), flags: "protective");
}

golems() {
}

humanoids() {
}

hybrids() {
}

insects() {
  group("i", tracking: 3, meander: 8, flags: "fearless");
  breed("giant cockroach[es]", darkBrown, 4, [
    attack("crawl[s] on", 3),
    spawn(rate: 4)
  ], drop: percent(10, "Insect Wing"),
      speed: 3);

  breed("giant centipede", red, 16, [
    attack("crawl[s] on", 3),
    attack("bite[s]", 5),
  ], speed: 3, meander: 0);
}

insubstantials() {

}

jellies() {
  group("j", meander: 4, speed: -1, tracking: 4, flags: "few fearless");
  breed("green slime", green, 12, [
    attack("crawl[s] on", 4),
    spawn(rate: 6)
  ]);

  breed("frosty slime", white, 14, [
    attack("crawl[s] on", 5, Element.cold),
    spawn(rate: 6)
  ]);

  breed("smoking slime", red, 18, [
    attack("crawl[s] on", 6, Element.fire),
    spawn(rate: 6)
  ]);

  breed("sparkling slime", lightPurple, 22, [
    attack("crawl[s] on", 8, Element.lightning),
    spawn(rate: 6)
  ]);
}

kobolds() {
  group("k", speed: 2, meander: 4, flags: "cowardly");
  breed("forest sprite", lightGreen, 8, [
    attack("scratch[es]", 4),
    teleport(range: 6)
  ], drop: [
    percent(20, "magic", 1)
  ]);

  breed("house sprite", lightBlue, 15, [
    attack("poke[s]", 8),
    teleport(range: 6)
  ], drop: [
    percent(20, "magic", 6)
  ]);

  breed("mischievous sprite", lightRed, 24, [
    attack("stab[s]", 9),
    sparkBolt(rate: 8, damage: 8),
    poisonBolt(rate: 15, damage: 10),
    teleport(range: 8)
  ], drop: [
    percent(40, "magic", 8)
  ]);

  breed("scurrilous imp", lightRed, 18, [
    attack("club[s]", 4),
    insult(),
    haste()
  ], drop: [
    percent(10, "club", 1),
    percent(5, "speed", 1),
  ], meander: 4, flags: "cowardly");

  breed("vexing imp", purple, 19, [
    attack("scratch[es]", 4),
    insult(),
    sparkBolt(rate: 5, damage: 6)
  ], drop: percent(10, "teleportation", 1),
      meander: 2, speed: 1, flags: "cowardly");

  breed("kobold", red, 16, [
    attack("poke[s]", 4),
    teleport(rate: 6, range: 6)
  ], drop: [
    percent(30, "magic", 7)
  ], meander: 2, flags: "group");

  breed("kobold shaman", blue, 16, [
    attack("hit[s]", 4),
    teleport(rate: 5, range: 6),
    waterBolt(rate: 5, damage: 6)
  ], drop: [
    percent(40, "magic", 7)
  ], meander: 2);

  breed("kobold trickster", gold, 20, [
    attack("hit[s]", 5),
    sparkBolt(rate: 5, damage: 8),
    teleport(rate: 5, range: 6),
    haste(rate: 7)
  ], drop: [
    percent(40, "magic", 7)
  ], meander: 2);

  breed("kobold priest", white, 25, [
    attack("club[s]", 6),
    heal(rate: 15, amount: 10),
    fireBolt(rate: 10, damage: 8),
    teleport(rate: 5, range: 6),
    haste(rate: 7)
  ], drop: [
    percent(30, "club", 10),
    percent(40, "magic", 7)
  ], meander: 2);

  breed("imp incanter", lightPurple, 18, [
    attack("scratch[es]", 4),
    insult(),
    fireBolt(rate: 5, damage: 10)
  ], drop: percent(20, "magic", 1),
      meander: 4, speed: 1, flags: "cowardly");

  breed("imp warlock", darkPurple, 40, [
    attack("stab[s]", 5),
    iceBolt(rate: 8, damage: 12),
    fireBolt(rate: 8, damage: 12)
  ], drop: percent(20, "magic", 4),
      meander: 3, speed: 1, flags: "cowardly");

  // TODO: Always drop something good.
  breed("Feng", orange, 60, [
    attack("stab[s]", 5),
    teleport(rate: 5, range: 6),
    teleport(rate: 50, range: 30),
    insult(),
    lightningCone(rate: 8, damage: 12)
  ], drop: percent(20, "magic", 4),
      meander: 3, speed: 1, flags: "cowardly");

  // homonculous
}

krakens() {

}

lizardMen() {
  // troglodyte
  // reptilian
}

lichs() {

}

mushrooms() {

}

hydras() {

}

nagas() {

}

demons() {

}

orcs() {

}

ogres() {

}

people() {
  group("p", tracking: 14, flags: "open-doors");
  breed("simpering knave", orange, 15, [
    attack("hit[s]", 2),
    attack("stab[s]", 4)
  ], drop: [
    percent(30, "whip", 1),
    percent(20, "body", 1),
    percent(10, "boots", 2),
    percent(10, "magic", 1),
  ], meander: 3, flags: "cowardly");

  breed("decrepit mage", purple, 16, [
    attack("hit[s]", 2),
    sparkBolt(rate: 10, damage: 8)
  ], drop: [
    percent(30, "magic", 3),
    percent(15, "dagger", 1),
    percent(15, "staff", 1),
    percent(10, "robe", 2),
    percent(10, "boots", 2)
  ], meander: 2);

  breed("unlucky ranger", green, 20, [
    attack("slash[es]", 2),
    arrow(rate: 4, damage: 2)
  ], drop: [
    percent(15, "potion", 3),
    percent(10, "bow", 4),
    percent(5, "sword", 4),
    percent(8, "body", 3)
  ], meander: 2);

  breed("drunken priest", aqua, 18, [
    attack("hit[s]", 3),
    heal(rate: 15, amount: 8)
  ], drop: [
    percent(15, "scroll", 3),
    percent(7, "club", 2),
    percent(7, "robe", 2)
  ], meander: 4, flags: "fearless");
}

giants() {

}

quadrupeds() {
  group("q");
  breed("fox", orange, 20, [
    attack("bite[s]", 5),
    attack("scratch[es]", 4)
  ], drop: "Fox Pelt",
      meander: 1);
}

rodents() {
  group("r", meander: 4);
  breed("field [mouse|mice]", lightBrown, 3, [
    attack("bite[s]", 3),
    attack("scratch[es]", 2)
  ], speed: 1);

  breed("fuzzy bunn[y|ies]", lightBlue, 14, [
    attack("bite[s]", 5),
    attack("kick[s]", 4)
  ], meander: -2);

  breed("vole", gray, 5, [
    attack("bite[s]", 4)
  ], speed: 1);

  breed("white [mouse|mice]", white, 6, [
    attack("bite[s]", 5),
    attack("scratch[es]", 3)
  ], speed: 1);

  breed("sewer rat", darkGray, 7, [
    attack("bite[s]", 4),
    attack("scratch[es]", 3)
  ], meander: -1, speed: 1, flags: "group");

  breed("plague rat", darkGreen, 10, [
    attack("bite[s]", 4, Element.poison),
    attack("scratch[es]", 3)
  ], speed: 1, flags: "group");
}

reptiles() {
  group("R");
  breed("frog", green, 4, [
    attack("hop[s] on", 2),
  ], meander: 4, speed: 1);

  // TODO: Drop scales?
  group("R", meander: 1, flags: "fearless");
  breed("lizard guard", yellow, 26, [
    attack("claw[s]", 8),
    attack("bite[s]", 10),
  ]);

  breed("lizard protector", darkYellow, 30, [
    attack("claw[s]", 10),
    attack("bite[s]", 14),
  ]);

  breed("armored lizard", gray, 38, [
    attack("claw[s]", 10),
    attack("bite[s]", 15),
  ]);

  breed("scaled guardian", darkGray, 50, [
    attack("claw[s]", 10),
    attack("bite[s]", 15),
  ]);

  breed("saurian", orange, 64, [
    attack("claw[s]", 12),
    attack("bite[s]", 17),
  ]);

  group("R", meander: 3);
  breed("juvenile salamander", lightRed, 24, [
    attack("bite[s]", 12, Element.fire),
    fireCone(rate: 16, damage: 18, range: 6)
  ]);

  breed("salamander", red, 40, [
    attack("bite[s]", 16, Element.fire),
    fireCone(rate: 16, damage: 24, range: 8)
  ]);
}

slugs() {
  group("s", tracking: 2, flags: "fearless", meander: 1, speed: -3);
  breed("slug", darkYellow, 6, [
    attack("crawl[s] on", 3),
  ]);

  breed("giant slug", green, 20, [
    attack("crawl[s] on", 7, Element.poison),
  ]);
}

snakes() {
  group("S", meander: 4);
  breed("garter snake", gold, 7, [
    attack("bite[s]", 1),
  ]);

  breed("tree snake", lightGreen, 14, [
    attack("bite[s]", 4),
  ]);

  breed("cave snake", gray, 35, [
    attack("bite[s]", 10),
  ]);
}

worms() {
  group("w", meander: 4, flags: "fearless");
  breed("giant earthworm", lightRed, 20, [
    attack("crawl[s] on", 4),
  ], speed: -2);

  breed("blood worm", red, 4, [
    attack("crawl[s] on", 5),
  ], flags: "swarm");

  breed("giant cave worm", white, 36, [
    attack("crawl[s] on", 8, Element.acid),
  ], speed: -2);

  breed("fire worm", orange, 6, [
    attack("crawl[s] on", 5, Element.fire),
  ], flags: "swarm");
}

skeletons() {

}

void group(glyph, {int meander, int speed, int tracking, String flags}) {
  _glyph = glyph;
  _meander = meander != null ? meander : 0;
  _speed = speed != null ? speed : 0;
  _tracking = tracking != null ? tracking : 10;
  _flags = flags;
}

Breed breed(String name, Glyph appearance(char), int health, List actions, {
    drop, int tracking, int meander: 0, int speed: 0, String flags}) {
  if (tracking == null) tracking = _tracking;

  var attacks = <Attack>[];
  var moves = <Move>[];

  for (var action in actions) {
    if (action is Attack) attacks.add(action);
    if (action is Move) moves.add(action);
  }

  if (drop is List) {
    drop = dropAllOf(drop as List<Drop>);
  } else if (drop is Drop) {
    drop = dropAllOf(<Drop>[drop]);
  } else if (drop is String) {
    drop = parseDrop(drop);
  } else {
    // Non-null way of dropping nothing.
    drop = dropAllOf([]);
  }

  var flagSet = new Set<String>();
  if (_flags != null) flagSet.addAll(_flags.split(" "));
  if (flags != null) flagSet.addAll(flags.split(" "));

  var breed = new Breed(name, Pronoun.it, appearance(_glyph), attacks,
      moves, drop, maxHealth: health, tracking: tracking,
      meander: meander + _meander,
      speed: speed + _speed, flags: flagSet);
  Monsters.all[breed.name] = breed;
  return breed;
}

Move heal({num rate: 5, int amount}) => new HealMove(rate, amount);

Move arrow({num rate: 5, int damage}) =>
    new BoltMove(rate, new RangedAttack("the arrow", "hits", damage, Element.none, 8));

Move waterBolt({num rate: 5, int damage}) =>
    new BoltMove(rate, new RangedAttack("the jet", "splashes", damage, Element.water, 8));

Move sparkBolt({num rate: 5, int damage, int range: 8}) =>
    new BoltMove(rate, new RangedAttack("the spark", "zaps", damage, Element.lightning, range));

Move iceBolt({num rate: 5, int damage, int range: 8}) =>
    new BoltMove(rate, new RangedAttack("the ice", "freezes", damage, Element.cold, range));

Move fireBolt({num rate: 5, int damage}) =>
    new BoltMove(rate, new RangedAttack("the flame", "burns", damage, Element.fire, 8));

Move darkBolt({num rate: 5, int damage}) =>
    new BoltMove(rate, new RangedAttack("the darkness", "crushes", damage, Element.dark, 10));

Move lightBolt({num rate: 5, int damage}) =>
    new BoltMove(rate, new RangedAttack("the light", "sears", damage, Element.light, 10));

Move poisonBolt({num rate: 5, int damage}) =>
    new BoltMove(rate, new RangedAttack("the poison", "engulfs", damage, Element.poison, 8));

Move fireCone({num rate: 5, int damage, int range: 10}) =>
    new ConeMove(rate, new RangedAttack("the flame", "burns", damage, Element.fire, range));

Move lightningCone({num rate: 5, int damage, int range: 10}) =>
    new ConeMove(rate, new RangedAttack("the lightning", "shocks", damage, Element.lightning, range));

Move insult({num rate: 5}) => new InsultMove(rate);
Move howl({num rate: 10, int range: 10}) => new HowlMove(rate, range);

Move haste({num rate: 5, int duration: 10, int speed: 1}) =>
    new HasteMove(rate, duration, speed);

Move teleport({num rate: 5, int range: 10}) =>
    new TeleportMove(rate, range);

Move spawn({num rate: 10}) => new SpawnMove(rate);


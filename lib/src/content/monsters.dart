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
  static final List<Breed> all = [];

  static final rootTag = new Tag("monster");

  static void initialize() {
    // Here's approximately the level distributions for the different
    // broad categories on monsters. Monsters are very roughly lumped
    // together so that different depths tend to have a different
    // feel. This doesn't mean that all monsters of a category will
    // fall in that range, just that they tend to. For every group,
    // there will likely be some oddball out of range monsters, like
    // death molds.

    //                   0  10  20  30  40  50  60  70  80  90 100
    // jelly             OOOooo-----
    // bugs              --oooOOOooo-----------
    // animals           ooOOOooooooo------
    // kobolds              --ooOOoo--
    // reptilians               --oooOOOo-
    // humanoids             ----oooooOOOOoooo----
    // plants                  --o--        --oooOoo----
    // orcs                    --ooOOOoo----
    // ogres                        --ooOOOo-
    // undead                            --------oOOOOOoooooo-----
    // trolls                           --ooOOOoooo-------
    // demons                                 -----ooooOOOOooooo--
    // elementals                   --------ooooooooooooo-----
    // golems                                --ooOOOoooo---
    // giants                                     --oooOOOooo-----
    // quylthulgs                                     -----ooooooo
    // mythical beasts                 ----------oooooooOOOOoo----
    // dragons                                  -----oooOOOoo-
    // ancient dragons                               ----ooooOOOOo
    // ancients                                            ---ooOO

    // jelly - unmoving, do interesting things when touched
    // bugs - quick, breed, normal attacks
    // animals - normal normal normal, sometimes groups
    // kobolds - weakest of the "human-like" races that can drop useable stuff
    // reptilians
    // humanoids
    // plants - poison touch, unmoving but very strong
    // orcs
    // ogres
    // undead
    //   zombies - slow, appear in groups, very bad to be touched by
    //   ghosts - quick, bad to be touched by

    // Here's the different letters used for monsters. Letters marked
    // with a * differ from how the letter is used in Angband.

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
      dragons,        greaterDragons,
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

    // TODO: Build a tag graph for breeds and then use it in places:
    // - Randomly generated themed dungeons that prefer monsters from a certain
    //   tag.
    // - Encounters that pick a couple of monsters from the same tag.
    // - Themed rooms that are filled with a certain tag.
  }
}

arachnids() {
  group("a", flags: "fearless");
  breed("brown spider", 1, brown, 3, [
    attack("bite[s]", 8, Element.poison)
  ], drop: percent(5, "Stinger"),
      meander: 8);

  breed("giant spider", 6, darkBlue, 20, [
    attack("bite[s]", 5, Element.poison)
  ], drop: percent(10, "Stinger"),
      meander: 5);
}

ancients() {

}

bats() {
  group("b");
  breed("brown bat", 2, lightBrown, 9, [
    attack("bite[s]", 4),
  ], meander: 6, speed: 2);

  breed("giant bat", 4, lightBrown, 16, [
    attack("bite[s]", 6),
  ], meander: 4, speed: 2);

  breed("cave bat", 6, gray, 10, [
    attack("bite[s]", 6),
  ], meander: 3, speed: 3, flags: "group");
}

birds() {
  group("B");
  breed("crow", 4, darkGray, 9, [
    attack("bite[s]", 5),
  ], drop: percent(25, "Black Feather"),
      meander: 4, speed: 2, flags: "group");

  breed("raven", 6, gray, 12, [
    attack("bite[s]", 5),
    attack("claw[s]", 4),
  ], drop: percent(20, "Black Feather"),
      meander: 1, flags: "protective");
}

canines() {
  group("c", tracking: 20, meander: 3, flags: "few");
  breed("mangy cur", 2, yellow, 11, [
    attack("bite[s]", 4),
    howl(range: 6)
  ], drop: percent(20, "Fur Pelt"));

  breed("wild dog", 4, gray, 16, [
    attack("bite[s]", 4),
    howl(range: 8)
  ], drop: percent(20, "Fur Pelt"));

  breed("mongrel", 7, orange, 28, [
    attack("bite[s]", 6),
    howl(range: 10)
  ], drop: percent(20, "Fur Pelt"));
}

canids() {
}

dragons() {
  // TODO: Tune. Give more attacks. Tune drops.
  group("d");
  breed("red dragon", 50, red, 400, [
    attack("bite[s]", 80),
    attack("claw[s]", 60),
    fireCone(damage: 100)
  ], drop: repeatDrop(5, percent(75, "equipment", 50)));
}

greaterDragons() {

}

eyes() {
  group("e", flags: "immobile");
  breed("lazy eye", 3, white, 16, [
    attack("gaze[s] into", 6),
    sparkBolt(rate: 7, damage: 10, range: 5),
    teleport(rate: 9, range: 4)
  ]);

  group("e", flags: "immobile");
  breed("floating eye", 9, yellow, 30, [
    attack("touch[es]", 4),
    lightBolt(rate: 5, damage: 16),
    teleport(rate: 8, range: 7)
  ]);

  // baleful eye, malevolent eye, murderous eye
}

elementals() {
}

flyingInsects() {
}

felines() {
  group("F");
  breed("stray cat", 1, gold, 9, [
    attack("bite[s]", 5),
    attack("scratch[es]", 4),
  ], drop: percent(10, "Fur Pelt"),
      meander: 3, speed: 1);
}

goblins() {
  group("g", meander: 1, flags: "open-doors");
  breed("goblin peon", 4, lightBrown, 20, [
    attack("stab[s]", 5)
  ], drop: [
    percent(10, "spear", 3),
    percent(5, "healing", 2),
  ], meander: 2, flags: "few");

  breed("goblin archer", 6, green, 22, [
    attack("stab[s]", 3),
    arrow(rate: 3, damage: 4)
  ], drop: [
    percent(20, "bow", 1),
    percent(10, "dagger", 2),
    percent(5, "healing", 3),
  ], flags: "few");

  breed("goblin fighter", 6, brown, 30, [
    attack("stab[s]", 7)
  ], drop: [
    percent(15, "spear", 5),
    percent(10, "armor", 5),
    percent(5, "resistance", 3),
    percent(5, "healing", 3),
  ]);

  breed("goblin warrior", 8, gray, 42, [
    attack("stab[s]", 10)
  ], drop: [
    percent(20, "axe", 6),
    percent(20, "armor", 6),
    percent(5, "resistance", 3),
    percent(5, "healing", 3),
  ], flags: "protective");

  breed("goblin mage", 9, blue, 30, [
    attack("whip[s]", 7),
    fireBolt(rate: 12, damage: 6),
    sparkBolt(rate: 12, damage: 8),
  ], drop: [
    percent(10, "equipment", 5),
    percent(10, "whip", 5),
    percent(20, "magic", 6),
  ]);

  breed("goblin ranger", 12, darkGreen, 36, [
    attack("stab[s]", 10),
    arrow(rate: 3, damage: 8)
  ], drop: [
    percent(30, "bow", 11),
    percent(20, "armor", 8),
    percent(20, "magic", 8)
  ]);

  // TODO: Always drop something good.
  breed("Erlkonig, the Goblin Prince", 14, darkGray, 80, [
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
  breed("giant cockroach[es]", 1, darkBrown, 4, [
    attack("crawl[s] on", 3),
    spawn(rate: 4)
  ], drop: percent(10, "Insect Wing"),
      speed: 3);

  breed("giant centipede", 3, red, 16, [
    attack("crawl[s] on", 4),
    attack("bite[s]", 8),
  ], speed: 3, meander: 0);
}

insubstantials() {

}

jellies() {
  group("j", meander: 4, speed: -1, tracking: 4, flags: "few fearless");
  breed("green slime", 1, green, 8, [
    attack("crawl[s] on", 4),
    spawn(rate: 6)
  ]);

  breed("frosty slime", 4, white, 14, [
    attack("crawl[s] on", 5, Element.cold),
    spawn(rate: 6)
  ]);

  breed("mud slime", 6, brown, 20, [
    attack("crawl[s] on", 8, Element.earth),
    spawn(rate: 6)
  ]);

  breed("smoking slime", 15, red, 30, [
    attack("crawl[s] on", 10, Element.fire),
    spawn(rate: 6)
  ]);

  breed("sparkling slime", 20, lightPurple, 40, [
    attack("crawl[s] on", 12, Element.lightning),
    spawn(rate: 6)
  ]);

  breed("caustic slime", 25, yellow, 50, [
    attack("crawl[s] on", 13, Element.acid),
    spawn(rate: 6)
  ]);

  breed("virulent slime", 35, darkGreen, 60, [
    attack("crawl[s] on", 14, Element.poison),
    spawn(rate: 6)
  ]);

  // TODO: Fly?
  breed("ectoplasm", 45, gray, 40, [
    attack("crawl[s] on", 15, Element.spirit),
    spawn(rate: 6)
  ]);
}

kobolds() {
  group("k", speed: 2, meander: 4, flags: "cowardly");
  breed("forest sprite", 2, lightGreen, 8, [
    attack("scratch[es]", 4),
    teleport(range: 6)
  ], drop: [
    percent(20, "magic", 1)
  ]);

  breed("house sprite", 4, lightBlue, 15, [
    attack("poke[s]", 8),
    teleport(range: 6)
  ], drop: [
    percent(20, "magic", 6)
  ]);

  breed("mischievous sprite", 7, lightRed, 24, [
    attack("stab[s]", 9),
    sparkBolt(rate: 8, damage: 8),
    poisonBolt(rate: 15, damage: 10),
    teleport(range: 8)
  ], drop: [
    percent(40, "magic", 8)
  ]);

  breed("scurrilous imp", 4, lightRed, 18, [
    attack("club[s]", 4),
    insult(),
    haste()
  ], drop: [
    percent(10, "club", 1),
    percent(5, "speed", 1),
  ], meander: 4, flags: "cowardly");

  breed("vexing imp", 4, purple, 19, [
    attack("scratch[es]", 4),
    insult(),
    sparkBolt(rate: 5, damage: 6)
  ], drop: percent(10, "teleportation", 1),
      meander: 2, speed: 1, flags: "cowardly");

  breed("kobold", 5, red, 16, [
    attack("poke[s]", 4),
    teleport(rate: 6, range: 6)
  ], drop: [
    percent(30, "magic", 7)
  ], meander: 2, flags: "group");

  breed("kobold shaman", 10, blue, 16, [
    attack("hit[s]", 4),
    teleport(rate: 5, range: 6),
    waterBolt(rate: 5, damage: 6)
  ], drop: [
    percent(40, "magic", 7)
  ], meander: 2);

  breed("kobold trickster", 13, gold, 20, [
    attack("hit[s]", 5),
    sparkBolt(rate: 5, damage: 8),
    teleport(rate: 5, range: 6),
    haste(rate: 7)
  ], drop: [
    percent(40, "magic", 7)
  ], meander: 2);

  breed("kobold priest", 15, white, 25, [
    attack("club[s]", 6),
    heal(rate: 15, amount: 10),
    fireBolt(rate: 10, damage: 8),
    teleport(rate: 5, range: 6),
    haste(rate: 7)
  ], drop: [
    percent(30, "club", 10),
    percent(40, "magic", 7)
  ], meander: 2);

  breed("imp incanter", 11, lightPurple, 18, [
    attack("scratch[es]", 4),
    insult(),
    fireBolt(rate: 5, damage: 10)
  ], drop: percent(20, "magic", 1),
      meander: 4, speed: 1, flags: "cowardly");

  breed("imp warlock", 14, darkPurple, 40, [
    attack("stab[s]", 5),
    iceBolt(rate: 8, damage: 12),
    fireBolt(rate: 8, damage: 12)
  ], drop: percent(20, "magic", 4),
      meander: 3, speed: 1, flags: "cowardly");

  // TODO: Always drop something good.
  breed("Feng", 20, orange, 60, [
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
  breed("simpering knave", 2, orange, 15, [
    attack("hit[s]", 2),
    attack("stab[s]", 4)
  ], drop: [
    percent(30, "whip", 1),
    percent(20, "body", 1),
    percent(10, "boots", 2),
    percent(10, "magic", 1),
  ], meander: 3, flags: "cowardly");

  breed("decrepit mage", 3, purple, 16, [
    attack("hit[s]", 2),
    sparkBolt(rate: 10, damage: 8)
  ], drop: [
    percent(30, "magic", 3),
    percent(15, "dagger", 1),
    percent(15, "staff", 1),
    percent(10, "robe", 2),
    percent(10, "boots", 2)
  ], meander: 2);

  breed("unlucky ranger", 5, green, 20, [
    attack("slash[es]", 2),
    arrow(rate: 4, damage: 2)
  ], drop: [
    percent(15, "potion", 3),
    percent(10, "bow", 4),
    percent(5, "sword", 4),
    percent(8, "body", 3)
  ], meander: 2);

  breed("drunken priest", 5, aqua, 18, [
    attack("hit[s]", 8),
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
  breed("fox", 4, orange, 20, [
    attack("bite[s]", 5),
    attack("scratch[es]", 4)
  ], drop: "Fox Pelt",
      meander: 1);
}

rodents() {
  group("r", meander: 4);
  breed("[mouse|mice]", 1, white, 6, [
    attack("bite[s]", 3),
    attack("scratch[es]", 2)
  ], speed: 1);

  breed("sewer rat", 2, darkGray, 7, [
    attack("bite[s]", 4),
    attack("scratch[es]", 3)
  ], meander: -1, speed: 1, flags: "group");

  breed("plague rat", 4, darkGreen, 10, [
    attack("bite[s]", 4, Element.poison),
    attack("scratch[es]", 3)
  ], speed: 1, flags: "group");
}

reptiles() {
  group("R");
  breed("frog", 1, green, 4, [
    attack("hop[s] on", 2),
  ], meander: 4, speed: 1);

  // TODO: Drop scales?
  group("R", meander: 1, flags: "fearless");
  breed("lizard guard", 11, yellow, 26, [
    attack("claw[s]", 8),
    attack("bite[s]", 10),
  ]);

  breed("lizard protector", 15, darkYellow, 30, [
    attack("claw[s]", 10),
    attack("bite[s]", 14),
  ]);

  breed("armored lizard", 17, gray, 38, [
    attack("claw[s]", 10),
    attack("bite[s]", 15),
  ]);

  breed("scaled guardian", 19, darkGray, 50, [
    attack("claw[s]", 10),
    attack("bite[s]", 15),
  ]);

  breed("saurian", 21, orange, 64, [
    attack("claw[s]", 12),
    attack("bite[s]", 17),
  ]);

  group("R", meander: 3);
  breed("juvenile salamander", 7, lightRed, 24, [
    attack("bite[s]", 12, Element.fire),
    fireCone(rate: 16, damage: 18, range: 6)
  ]);

  breed("salamander", 13, red, 40, [
    attack("bite[s]", 16, Element.fire),
    fireCone(rate: 16, damage: 24, range: 8)
  ]);
}

slugs() {
  group("s", tracking: 2, flags: "fearless", meander: 1, speed: -3);
  breed("slug", 1, darkYellow, 6, [
    attack("crawl[s] on", 3),
  ]);

  breed("giant slug", 6, green, 20, [
    attack("crawl[s] on", 7, Element.poison),
  ]);
}

snakes() {
  group("S", meander: 4);
  breed("garter snake", 1, gold, 7, [
    attack("bite[s]", 1),
  ]);

  breed("brown snake", 3, brown, 14, [
    attack("bite[s]", 4),
  ]);

  breed("cave snake", 7, gray, 35, [
    attack("bite[s]", 10),
  ]);
}

worms() {
  group("w", meander: 4, flags: "fearless");
  breed("giant earthworm", 2, lightRed, 20, [
    attack("crawl[s] on", 4),
  ], speed: -2);

  breed("blood worm", 2, red, 4, [
    attack("crawl[s] on", 5),
  ], flags: "swarm");

  breed("giant cave worm", 7, white, 36, [
    attack("crawl[s] on", 8, Element.acid),
  ], speed: -2);

  breed("fire worm", 10, orange, 6, [
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

Breed breed(String name, int depth, Glyph appearance(char), int health,
    List actions,
    {drop, int tracking, int meander: 0, int speed: 0, String flags}) {
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
      moves, drop, depth: depth, maxHealth: health, tracking: tracking,
      meander: meander + _meander,
      speed: speed + _speed, flags: flagSet);
  breed.tags.add(Monsters.rootTag);
  Monsters.all.add(breed);
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

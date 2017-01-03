import 'package:malison/malison.dart';

import '../engine.dart';
import 'utils.dart';
import 'drops.dart';

/// The last builder that was created. It gets implicitly finished when the
/// next group or breed starts, or at the end of initialization. This way, we
/// don't need an explicit `build()` call at the end of each builder.
_BreedBuilder _builder;

/// The default tracking for a breed that doesn't specify it.
int _tracking;

/// The default speed for breeds in the current group. If the breed
/// specifies a speed, it is added to this.
int _speed;

/// The default meander for breeds in the current group. If the breed
/// specifies a meander, it is added to this.
int _meander;

/// Default flags for the current group.
String _groupFlags;

/// The current glyph. Any items defined will use this. Can be a string or
/// a character code.
var _glyph;

/// Static class containing all of the [Monster] [Breed]s.
class Monsters {
  static final ResourceSet<Breed> breeds = new ResourceSet();

  static void initialize() {
    breeds.defineTags("monster");

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
    // k  Kobold/Imp/etc      K  Kraken/Land Octopus
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
      quadrupeds,     quest,
      rodents,        reptiles,
      slugs,          snakes,
      troglodytes,    trolls,
      minorUndead,    majorUndead,
      vines,          vampires,
      worms,          wraiths,
      skeletons,      xorns,
      /* y and Y? */
      zombies,        serpents
    ];

    for (var category in categories) {
      category();
    }

    finishBuilder();

    // TODO: Build a tag graph for breeds and then use it in places:
    // - Randomly generated themed dungeons that prefer monsters from a certain
    //   tag.
    // - Encounters that pick a couple of monsters from the same tag.
    // - Themed rooms that are filled with a certain tag.
  }
}

void arachnids() {
  group("a", flags: "fearless");
  breed("brown spider", 1, brown, 3, meander: 8)
      .attack("bite[s]", 5, Element.poison)
      .drop(5, "Stinger");

  breed("giant spider", 6, darkBlue, 20, meander: 5)
      .attack("bite[s]", 5, Element.poison)
      .drop(10, "Stinger");
}

void ancients() {}

void bats() {
  group("b");
  breed("brown bat", 2, lightBrown, 9, speed: 2, meander: 6)
      .attack("bite[s]", 4);

  breed("giant bat", 4, lightBrown, 16, speed: 2, meander: 4)
      .attack("bite[s]", 6);

  breed("cave bat", 6, gray, 10, speed: 3, meander: 3)
      .attack("bite[s]", 6)
      .flags("group");
}

void birds() {
  group("B");
  breed("crow", 4, darkGray, 9, speed: 2, meander: 4)
      .attack("bite[s]", 5)
      .drop(25, "Black Feather")
      .flags("group");

  breed("raven", 6, gray, 12, meander: 1)
      .attack("bite[s]", 5)
      .attack("claw[s]", 4)
      .drop(20, "Black Feather")
      .flags("protective");
}

void canines() {
  group("c", tracking: 20, meander: 3, flags: "few");
  breed("mangy cur", 2, yellow, 11)
      .attack("bite[s]", 4)
      .howl(range: 6)
      .drop(20, "Fur Pelt");

  breed("wild dog", 4, gray, 16)
      .attack("bite[s]", 4)
      .howl(range: 8)
      .drop(20, "Fur Pelt");

  breed("mongrel", 7, orange, 28)
      .attack("bite[s]", 6)
      .howl(range: 10)
      .drop(20, "Fur Pelt");
}

void canids() {}

void dragons() {
  // TODO: Tune. Give more attacks. Tune drops.
  group("d");
  breed("red dragon", 50, red, 400)
      .attack("bite[s]", 80)
      .attack("claw[s]", 60)
      .fireCone(damage: 100)
      .dropMany(8, "treasure")
      .dropMany(6, "magic")
      .dropMany(5, "equipment");
}

void greaterDragons() {}

void eyes() {
  group("e", flags: "immobile");
  breed("lazy eye", 1, white, 10)
      .attack("stare[s] at", 4)
      .sparkBolt(rate: 6, damage: 10, range: 6);

  breed("mad eye", 5, lightRed, 20)
      .attack("stare[s] at", 6)
      .windBolt(rate: 6, damage: 20);

  breed("floating eye", 9, yellow, 30)
      .attack("stare[s] at", 8)
      .sparkBolt(rate: 5, damage: 16)
      .teleport(rate: 8, range: 7);

  breed("baleful eye", 20, orange, 50)
      .attack("gaze[s] into", 12)
      .fireBolt(rate: 4, damage: 20)
      .waterBolt(rate: 4, damage: 20)
      .teleport(rate: 8, range: 9);

  breed("malevolent eye", 30, red, 70)
      .attack("gaze[s] into", 20)
      .lightBolt(rate: 4, damage: 20)
      .darkBolt(rate: 4, damage: 20)
      .fireCone(rate: 7, damage: 30)
      .teleport(rate: 8, range: 9);

  breed("murderous eye", 40, darkRed, 90)
      .attack("gaze[s] into", 30)
      .acidBolt(rate: 7, damage: 50)
      .stoneBolt(rate: 7, damage: 50)
      .iceCone(rate: 7, damage: 40)
      .teleport(rate: 8, range: 9);

  breed("watcher", 60, gray, 140)
      .attack("see[s]", 50)
      .lightBolt(rate: 7, damage: 40)
      .lightCone(rate: 7, damage: 60)
      .darkBolt(rate: 7, damage: 50)
      .darkCone(rate: 7, damage: 70);

  // beholder, undead beholder, rotting beholder
}

void elementals() {}

void flyingInsects() {}

void felines() {
  group("F");
  breed("stray cat", 1, gold, 9, speed: 1, meander: 3)
      .attack("bite[s]", 5)
      .attack("scratch[es]", 4)
      .drop(10, "Fur Pelt");
}

void goblins() {
  group("g", meander: 1, flags: "open-doors");
  breed("goblin peon", 4, lightBrown, 20, meander: 2)
      .attack("stab[s]", 5)
      .drop(10, "spear")
      .drop(5, "healing")
      .flags("few");

  breed("goblin archer", 6, green, 22)
      .attack("stab[s]", 3)
      .arrow(rate: 3, damage: 4)
      .drop(20, "bow")
      .drop(10, "dagger")
      .drop(5, "healing")
      .flags("few");

  breed("goblin fighter", 6, brown, 30)
      .attack("stab[s]", 7)
      .drop(15, "spear")
      .drop(10, "armor")
      .drop(5, "resistance")
      .drop(5, "healing");

  breed("goblin warrior", 8, gray, 42)
      .attack("stab[s]", 10)
      .drop(20, "axe")
      .drop(20, "armor")
      .drop(5, "resistance")
      .drop(5, "healing")
      .flags("protective");

  breed("goblin mage", 9, blue, 30)
      .attack("whip[s]", 7)
      .fireBolt(rate: 12, damage: 6)
      .sparkBolt(rate: 12, damage: 8)
      .drop(10, "equipment")
      .drop(10, "whip")
      .drop(20, "magic");

  breed("goblin ranger", 12, darkGreen, 36)
      .attack("stab[s]", 10)
      .arrow(rate: 3, damage: 8)
      .drop(30, "bow")
      .drop(20, "armor")
      .drop(20, "magic");

  // TODO: Always drop something good.
  breed("Erlkonig, the Goblin Prince", 14, darkGray, 80)
      .attack("hit[s]", 10)
      .attack("slash[es]", 14)
      .darkBolt(rate: 20, damage: 10)
      .drop(60, "equipment")
      .drop(60, "equipment")
      .drop(40, "magic")
      .flags("protective");
}

void golems() {}

void humanoids() {}

void hybrids() {}

void insects() {
  group("i", tracking: 3, meander: 8, flags: "fearless");
  breed("giant cockroach[es]", 1, darkBrown, 4, speed: 3)
      .attack("crawl[s] on", 3)
      .spawn(rate: 4)
      .drop(10, "Insect Wing");

  breed("giant centipede", 3, red, 16, speed: 3, meander: -4)
      .attack("crawl[s] on", 4)
      .attack("bite[s]", 8);
}

void insubstantials() {}

void jellies() {
  group("j", meander: 4, speed: -1, tracking: 4, flags: "few fearless");
  breed("green slime", 1, green, 8)
      .attack("crawl[s] on", 4)
      .spawn(rate: 6);

  breed("frosty slime", 4, white, 14)
      .attack("crawl[s] on", 5, Element.cold)
      .spawn(rate: 6);

  breed("mud slime", 6, brown, 20)
      .attack("crawl[s] on", 8, Element.earth)
      .spawn(rate: 6);

  breed("smoking slime", 15, red, 30)
      .attack("crawl[s] on", 10, Element.fire)
      .spawn(rate: 6);

  breed("sparkling slime", 20, lightPurple, 40)
      .attack("crawl[s] on", 12, Element.lightning)
      .spawn(rate: 6);

  breed("caustic slime", 25, yellow, 50)
      .attack("crawl[s] on", 13, Element.acid)
      .spawn(rate: 6);

  breed("virulent slime", 35, darkGreen, 60)
      .attack("crawl[s] on", 14, Element.poison)
      .spawn(rate: 6);

  // TODO: Fly?
  breed("ectoplasm", 45, gray, 40)
      .attack("crawl[s] on", 15, Element.spirit)
      .spawn(rate: 6);
}

void kobolds() {
  group("k", speed: 2, meander: 4, flags: "cowardly");
  breed("forest sprite", 1, lightGreen, 8)
      .attack("scratch[es]", 4)
      .teleport(range: 6)
      .drop(20, "magic");

  breed("house sprite", 3, lightBlue, 15)
      .attack("poke[s]", 8)
      .teleport(range: 6)
      .drop(20, "magic");

  breed("mischievous sprite", 7, lightRed, 24)
      .attack("stab[s]", 9)
      .sparkBolt(rate: 8, damage: 8)
      .poisonBolt(rate: 15, damage: 10)
      .teleport(range: 8)
      .drop(40, "magic");

  breed("scurrilous imp", 4, lightRed, 18, meander: 4)
      .attack("club[s]", 4)
      .insult()
      .haste()
      .drop(10, "club")
      .drop(5, "speed")
      .flags("cowardly");

  breed("vexing imp", 4, purple, 19, speed: 1, meander: 2)
      .attack("scratch[es]", 4)
      .insult()
      .sparkBolt(rate: 5, damage: 6)
      .drop(10, "teleportation")
      .flags("cowardly");

  breed("kobold", 5, red, 16, meander: 2)
      .attack("poke[s]", 4)
      .teleport(rate: 6, range: 6)
      .drop(30, "magic")
      .flags("group");

  breed("kobold shaman", 10, blue, 16, meander: 2)
      .attack("hit[s]", 4)
      .teleport(rate: 5, range: 6)
      .waterBolt(rate: 5, damage: 6)
      .drop(40, "magic");

  breed("kobold trickster", 13, gold, 20, meander: 2)
      .attack("hit[s]", 5)
      .sparkBolt(rate: 5, damage: 8)
      .teleport(rate: 5, range: 6)
      .haste(rate: 7)
      .drop(40, "magic");

  breed("kobold priest", 15, white, 25, meander: 2)
      .attack("club[s]", 6)
      .heal(rate: 15, amount: 10)
      .fireBolt(rate: 10, damage: 8)
      .teleport(rate: 5, range: 6)
      .haste(rate: 7)
      .drop(30, "club")
      .drop(40, "magic");

  breed("imp incanter", 11, lightPurple, 18, speed: 1, meander: 4)
      .attack("scratch[es]", 4)
      .insult()
      .fireBolt(rate: 5, damage: 10)
      .drop(20, "magic")
      .flags("cowardly");

  breed("imp warlock", 14, darkPurple, 40, speed: 1, meander: 3)
      .attack("stab[s]", 5)
      .iceBolt(rate: 8, damage: 12)
      .fireBolt(rate: 8, damage: 12)
      .drop(20, "magic")
      .flags("cowardly");

  // TODO: Always drop something good.
  breed("Feng", 20, orange, 60, speed: 1, meander: 3)
      .attack("stab[s]", 5)
      .teleport(rate: 5, range: 6)
      .teleport(rate: 50, range: 30)
      .insult()
      .lightningCone(rate: 8, damage: 12)
      .drop(20, "magic")
      .flags("cowardly");

  // homonculous
}

void krakens() {}

void lizardMen() {
  // troglodyte
  // reptilian
}

void lichs() {}
void mushrooms() {}
void hydras() {}
void nagas() {}
void demons() {}
void orcs() {}
void ogres() {}

void people() {
  group("p", tracking: 14, flags: "open-doors");
  breed("simpering knave", 2, orange, 15, meander: 3)
      .attack("hit[s]", 2)
      .attack("stab[s]", 4)
      .drop(30, "whip")
      .drop(20, "body")
      .drop(10, "boots")
      .drop(10, "magic")
      .flags("cowardly");

  breed("decrepit mage", 3, purple, 16, meander: 2)
      .attack("hit[s]", 2)
      .sparkBolt(rate: 10, damage: 8)
      .drop(30, "magic")
      .drop(15, "dagger")
      .drop(15, "staff")
      .drop(10, "robe")
      .drop(10, "boots");

  breed("unlucky ranger", 5, green, 20, meander: 2)
      .attack("slash[es]", 2)
      .arrow(rate: 4, damage: 2)
      .drop(15, "potion")
      .drop(10, "bow")
      .drop(5, "sword")
      .drop(8, "body");

  breed("drunken priest", 5, aqua, 18, meander: 4)
      .attack("hit[s]", 8)
      .heal(rate: 15, amount: 8)
      .drop(15, "scroll")
      .drop(7, "club")
      .drop(7, "robe")
      .flags("fearless");
}

void giants() {}

void quadrupeds() {
  group("q");
  breed("fox", 4, orange, 20, meander: 1)
      .attack("bite[s]", 5)
      .attack("scratch[es]", 4)
      .drop(80, "Fox Pelt");
}

void quest() {}

void rodents() {
  group("r", meander: 4);
  breed("[mouse|mice]", 1, white, 6, speed: 1)
      .attack("bite[s]", 3)
      .attack("scratch[es]", 2);

  breed("sewer rat", 2, darkGray, 7, speed: 1, meander: -1)
      .attack("bite[s]", 4)
      .attack("scratch[es]", 3)
      .flags("group");

  breed("plague rat", 4, darkGreen, 10, speed: 1)
      .attack("bite[s]", 4, Element.poison)
      .attack("scratch[es]", 3)
      .flags("group");
}

void reptiles() {
  group("R");
  breed("frog", 1, green, 4, speed: 1, meander: 4)
      .attack("hop[s] on", 2);

  // TODO: Drop scales?
  group("R", meander: 1, flags: "fearless");
  breed("lizard guard", 11, yellow, 26)
      .attack("claw[s]", 8)
      .attack("bite[s]", 10);

  breed("lizard protector", 15, darkYellow, 30)
      .attack("claw[s]", 10)
      .attack("bite[s]", 14);

  breed("armored lizard", 17, gray, 38)
      .attack("claw[s]", 10)
      .attack("bite[s]", 15);

  breed("scaled guardian", 19, darkGray, 50)
      .attack("claw[s]", 10)
      .attack("bite[s]", 15);

  breed("saurian", 21, orange, 64)
      .attack("claw[s]", 12)
      .attack("bite[s]", 17);

  group("R", meander: 3);
  breed("juvenile salamander", 7, lightRed, 24)
      .attack("bite[s]", 12, Element.fire)
      .fireCone(rate: 16, damage: 18, range: 6);

  breed("salamander", 13, red, 40)
      .attack("bite[s]", 16, Element.fire)
      .fireCone(rate: 16, damage: 24, range: 8);
}

void slugs() {
  group("s", tracking: 2, flags: "fearless", meander: 1, speed: -3);
  breed("slug", 1, darkYellow, 14)
      .attack("crawl[s] on", 5);

  breed("giant slug", 6, green, 20)
      .attack("crawl[s] on", 7, Element.poison);
}

void snakes() {
  group("S", speed: 1, meander: 4);
  breed("garter snake", 1, green, 7)
      .attack("bite[s]", 3);

  breed("brown snake", 3, brown, 14)
      .attack("bite[s]", 4);

  breed("cave snake", 7, gray, 35)
      .attack("bite[s]", 10);
}

void troglodytes() {}
void trolls() {}
void minorUndead() {}
void majorUndead() {}
void vines() {}
void vampires() {}

void worms() {
  group("w", meander: 4, flags: "fearless");
  breed("giant earthworm", 2, lightRed, 20, speed: -2)
      .attack("crawl[s] on", 4);

  breed("blood worm", 2, red, 4)
      .attack("crawl[s] on", 5)
      .flags("swarm");

  breed("giant cave worm", 7, white, 36, speed: -2)
      .attack("crawl[s] on", 8, Element.acid);

  breed("fire worm", 10, orange, 6)
      .attack("crawl[s] on", 5, Element.fire)
      .flags("swarm");
}

void wraiths() {}

void skeletons() {}

void xorns() {}

void zombies() {}
void serpents() {}

void group(glyph, {int meander, int speed, int tracking, String flags}) {
  finishBuilder();

  _glyph = glyph;
  _meander = meander != null ? meander : 0;
  _speed = speed != null ? speed : 0;
  _tracking = tracking != null ? tracking : 10;
  _groupFlags = flags;
}

void finishBuilder() {
  if (_builder == null) return;

  var breed = _builder.build();
  // TODO: Give breeds rarity.
  Monsters.breeds.add(breed.name, breed, breed.depth, 1, "monster");
  _builder = null;
}

_BreedBuilder breed(String name, int depth, Glyph appearance(char), int health,
    {int speed: 0, int meander: 0}) {
  finishBuilder();
  _builder = new _BreedBuilder(name, depth, appearance(_glyph), health);
  _builder.speedOffset = speed;
  _builder.meanderOffset = meander;
  return _builder;
}

class _BreedBuilder {
  final String name;
  final int depth;
  final Object appearance;
  final int health;
  int tracking;
  int meanderOffset = 0;
  int speedOffset = 0;
  final Set<String> _flags = new Set();
  final List<Attack> attacks = [];
  final List<Move> moves = [];
  final List<Drop> drops = [];

  _BreedBuilder(this.name, this.depth, this.appearance, this.health) {
    tracking = _tracking;
    if (_groupFlags != null) _flags.addAll(_groupFlags.split(" "));
  }

  _BreedBuilder attack(String verb, int damage, [Element element, Noun noun]) {
    attacks.add(new Attack(verb, damage, element, noun));
    return this;
  }

  _BreedBuilder drop(int chance, String name, [int depthOffset = 0]) {
    drops.add(percentDrop(chance, name, depth + depthOffset));
    return this;
  }

  _BreedBuilder dropMany(int count, String name, [int depthOffset = 0]) {
    drops.add(repeatDrop(count, name, depth + depthOffset));
    return this;
  }

  _BreedBuilder flags(String flags) {
    // TODO: Allow negated flags.
    _flags.addAll(flags.split(" "));
    return this;
  }

  _BreedBuilder heal({num rate: 5, int amount}) =>
      _addMove(new HealMove(rate, amount));

  _BreedBuilder arrow({num rate: 5, int damage}) =>
      _bolt("the arrow", "hits", Element.none, damage, rate, 8);

  _BreedBuilder windBolt({num rate: 5, int damage}) =>
      _bolt("the wind", "blows", Element.air, damage, rate, 8);

  _BreedBuilder stoneBolt({num rate: 5, int damage}) =>
      _bolt("the stone", "hits", Element.earth, damage, rate, 8);

  _BreedBuilder waterBolt({num rate: 5, int damage}) =>
      _bolt("the jet", "splashes", Element.water, damage, rate, 8);

  _BreedBuilder sparkBolt({num rate: 5, int damage, int range: 8}) =>
      _bolt("the spark", "zaps", Element.lightning, damage, rate, range);

  _BreedBuilder iceBolt({num rate: 5, int damage, int range: 8}) =>
      _bolt("the ice", "freezes", Element.cold, damage, rate, range);

  _BreedBuilder fireBolt({num rate: 5, int damage}) =>
      _bolt("the flame", "burns", Element.fire, damage, rate, 8);

  _BreedBuilder lightningBolt({num rate: 5, int damage}) =>
      _bolt("the lightning", "shocks", Element.lightning, damage, rate, 10);

  _BreedBuilder acidBolt({num rate: 5, int damage, int range: 8}) =>
      _bolt("the acid", "burns", Element.acid, damage, rate, range);

  _BreedBuilder darkBolt({num rate: 5, int damage}) =>
      _bolt("the darkness", "crushes", Element.dark, damage, rate, 10);

  _BreedBuilder lightBolt({num rate: 5, int damage}) =>
      _bolt("the light", "sears", Element.light, damage, rate, 10);

  _BreedBuilder poisonBolt({num rate: 5, int damage}) =>
      _bolt("the poison", "engulfs", Element.poison, damage, rate, 8);

  _BreedBuilder windCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the wind", "buffets", Element.air, rate, damage, range);

  _BreedBuilder fireCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the flame", "burns", Element.fire, rate, damage, range);

  _BreedBuilder iceCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the ice", "freezes", Element.cold, rate, damage, range);

  _BreedBuilder lightningCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the lightning", "shocks", Element.lightning, rate, damage, range);

  _BreedBuilder lightCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the light", "sears", Element.light, rate, damage, range);

  _BreedBuilder darkCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the darkness", "crushes", Element.dark, rate, damage, range);

  _BreedBuilder insult({num rate: 5}) => _addMove(new InsultMove(rate));

  _BreedBuilder howl({num rate: 10, int range: 10}) =>
      _addMove(new HowlMove(rate, range));

  _BreedBuilder haste({num rate: 5, int duration: 10, int speed: 1}) =>
      _addMove(new HasteMove(rate, duration, speed));

  _BreedBuilder teleport({num rate: 5, int range: 10}) =>
      _addMove(new TeleportMove(rate, range));

  _BreedBuilder spawn({num rate: 10}) => _addMove(new SpawnMove(rate));

  _BreedBuilder _bolt(String noun, String verb, Element element, num rate, int damage, int range) {
    return _addMove(new BoltMove(rate, new RangedAttack(new Noun(noun), verb, damage, element, range)));
  }

  _BreedBuilder _cone(String noun, String verb, Element element, num rate, int damage, int range) {
    return _addMove(new ConeMove(rate, new RangedAttack(new Noun(noun), verb, damage, element, range)));
  }

  _BreedBuilder _addMove(Move move) {
    moves.add(move);
    return this;
  }

  Breed build() {
    var breed = new Breed(name, Pronoun.it, appearance, attacks,
        moves, dropAllOf(drops), depth: depth, maxHealth: health, tracking: tracking,
        meander: _meander + meanderOffset,
        speed: _speed + speedOffset, flags: _flags);

    return breed;
  }
}
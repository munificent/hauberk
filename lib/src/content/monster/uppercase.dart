import '../../engine.dart';
import '../../hues.dart';
import '../action/missive.dart';
import '../elements.dart';
import 'builder.dart';

// TODO: Describe other monsters.
void ancients() {}

void birds() {
  family("B", "natural/animal/bird")
    ..sense(see: 8, hear: 6)
    ..defense(10, "{1} flaps out of the way.")
    ..fly()
    ..count(3, 6);

  breed("crow", 4, darkCoolGray, 10, speed: 2)
    ..meander(30)
    ..attack("bite[s]", 5)
    ..drop("Feather", percent: 30);
  describe(""""What harm can a stupid little crow do?" you think as it and its
      murderous friends dive towards your eyes, claws extended.""");

  breed("raven", 6, coolGray, 16)
    ..meander(15)
    ..attack("bite[s]", 5)
    ..attack("claw[s]", 4)
    ..drop("Feather", percent: 30)
    ..flags("protective");
  describe("""Its black eyes gleam with a malevolent intelligence.""");
}

void canids() {}

void greaterDragons() {
  // TODO: Tune. Give more attacks. Tune drops.
  // TODO: Give each breed more variety.
  // TODO: Minions?
  var dragons = [
    ("forest", Element.none, peaGreen, sherwood),
    ("brown", Elements.earth, sandal, tan),
    ("blue", Elements.water, lightBlue, blue),
    ("white", Elements.cold, lightCoolGray, ash),
    ("purple", Elements.poison, lilac, purple),
    ("green", Elements.acid, lima, olive),
    ("silver", Elements.lightning, lightAqua, lightBlue),
    ("red", Elements.fire, pink, red),
    ("gold", Elements.light, buttermilk, gold),
    ("black", Elements.dark, coolGray, darkCoolGray),
    ("ethereal", Elements.spirit, aqua, darkBlue),
  ];

  var max = dragons.length - 1;

  family("D", "mythical/beast/dragon")
    ..sense(see: 12, hear: 8)
    ..defense(10, "{2} [are|is] deflected by its scales.")
    ..preferOpen();

  var i = 0;
  for (var (name, element, color, _) in dragons) {
    var dragon =
        breed(
            "elder $name dragon",
            lerpInt(i, 0, max, 65, 85),
            color,
            lerpInt(i, 0, max, 800, 1500),
          )
          ..attack("bite[s]", lerpInt(i, 0, max, 40, 80))
          ..attack("claw[s]", lerpInt(i, 0, max, 35, 75))
          ..drop("treasure", count: lerpInt(i, 0, max, 6, 16))
          ..drop("magic", count: lerpInt(i, 0, max, 3, 6))
          ..drop("equipment", count: lerpInt(i, 0, max, 3, 6));

    if (element != Element.none) {
      dragon.cone(
        element,
        rate: 11,
        damage: lerpInt(i, 0, max, 40, 100),
        range: 5,
      );
    }

    i++;
  }

  family("D", "mythical/beast/dragon")
    ..sense(see: 16, hear: 10)
    ..defense(20, "{2} [are|is] deflected by its scales.")
    ..preferOpen();

  i = 0;
  for (var (name, element, _, color) in dragons) {
    var dragon =
        breed(
            "ancient $name dragon",
            lerpInt(i, 0, max, 80, 99),
            color,
            lerpInt(i, 0, max, 1400, 2000),
          )
          ..attack("bite[s]", lerpInt(i, 0, max, 60, 100))
          ..attack("claw[s]", lerpInt(i, 0, max, 50, 80))
          ..drop("treasure", count: lerpInt(i, 0, max, 7, 20))
          ..drop("magic", count: lerpInt(i, 0, max, 4, 7))
          ..drop("equipment", count: lerpInt(i, 0, max, 4, 7));

    if (element != Element.none) {
      dragon.cone(element, rate: 8, damage: lerpInt(i, 0, max, 200, 400));
    }

    i++;
  }
}

void elementals() {}

void faeFolk() {
  // Sprites, pixies, fairies, elves, etc.

  family("F", "humanoid/hob/fae", speed: 2, flags: "cowardly")
    ..sense(see: 10, hear: 8)
    ..meander(30)
    ..defense(10, "{1} flits out of the way.")
    ..fly()
    ..preferOpen();
  breed("forest sprite", 2, mint, 6)
    ..attack("scratch[es]", 3)
    ..missive(Missive.insult, rate: 4)
    ..sparkBolt(rate: 12, damage: 4)
    ..drop("treasure", percent: 10)
    ..drop("magic", percent: 30)
    ..drop("Insect Wing", percent: 30);

  breed("house sprite", 5, lightBlue, 10)
    ..attack("poke[s]", 5)
    ..missive(Missive.insult, rate: 4)
    ..stoneBolt(rate: 10, damage: 4)
    ..teleport(rate: 8, range: 4)
    ..drop("treasure", percent: 10)
    ..drop("magic", percent: 30)
    ..drop("Insect Wing", percent: 30);

  breed("mischievous sprite", 7, pink, 24)
    ..attack("poke[s]", 6)
    ..missive(Missive.insult, rate: 4)
    ..windBolt(rate: 10, damage: 8)
    ..teleport(range: 5)
    ..drop("treasure", percent: 10)
    ..drop("magic", percent: 30)
    ..drop("Insect Wing", percent: 30);

  breed("Tink", 8, peaGreen, 40)
    ..unique(pronoun: Pronoun.she)
    ..meander(10)
    ..attack("poke[s]", 8)
    ..missive(Missive.insult, rate: 4)
    ..sparkBolt(rate: 8, damage: 4)
    ..windBolt(rate: 10, damage: 7)
    ..teleport(range: 5)
    ..drop("treasure", count: 2)
    ..drop("magic", count: 3, depthOffset: 3);

  // TODO: https://en.wikipedia.org/wiki/Puck_(folklore)
}

void golems() {
  // TODO: Animated dolls, poppets, and marionettes.
}

void hybrids() {
  family("H", "mythical/beast/hybrid").sense(see: 10, hear: 12);

  // TODO: Cause disease when scratched?
  breed("harpy", 25, lilac, 50, speed: 2)
    ..fly()
    ..count(2, 5)
    ..attack("bite[s]", 10)
    ..attack("scratch[es]", 15)
    ..howl(verb: "screeches")
    ..missive(Missive.screech)
    ..drop("Feather", percent: 50);

  breed("griffin", 35, gold, 200)
    ..attack("bite[s]", 20)
    ..attack("scratch[es]", 15)
    ..drop("Feather", percent: 50);

  // TODO: https://en.wikipedia.org/wiki/List_of_hybrid_creatures_in_folklore
}

void insubstantials() {}

void krakens() {}

void lichs() {}

void hydras() {}

void demons() {}

void ogres() {
  // "humanoid/orcus/ogre"
}

void giants() {}

void quest() {
  // TODO: Better group?
  family("Q", "magical");
  breed("Nameless Unmaker", 100, purple, 1000, speed: 2)
    ..unique(pronoun: Pronoun.it)
    ..sense(see: 16, hear: 16)
    ..attack("crushe[s]", 250, Elements.earth)
    ..attack("blast[s]", 200, Elements.lightning)
    ..darkCone(rate: 10, damage: 500)
    ..flags("fearless")
    ..openDoors()
    ..dropGreat("item", count: 20);
  // TODO: Minions. Moves.
}

void reptiles() {
  family("R", "natural/animal/herp");
  breed("frog", 1, lima, 4, dodge: 30)
    ..sense(see: 6, hear: 4)
    ..meander(30)
    ..swim()
    ..attack("hop[s] on", 2);

  family("R", "natural/animal/herp/salamander", dodge: 30)
    ..sense(see: 6, hear: 5)
    ..meander(20)
    ..preferOpen()
    ..emanate(3);
  breed("juvenile salamander", 7, pink, 20)
    ..attack("bite[s]", 14, Elements.fire)
    ..fireCone(rate: 16, damage: 20, range: 4);

  breed("salamander", 13, red, 30)
    ..attack("bite[s]", 18, Elements.fire)
    ..fireCone(rate: 16, damage: 30, range: 5);

  breed("three-headed salamander", 23, maroon, 90)
    ..attack("bite[s]", 24, Elements.fire)
    ..fireCone(rate: 10, damage: 20, range: 5);
}

void snakes() {
  family("S", "natural/animal/herp/snake", dodge: 30)
    ..sense(see: 4, hear: 7)
    ..meander(30);
  breed("water snake", 1, lima, 11).attack("bite[s]", 3);

  breed("brown snake", 3, tan, 25).attack("bite[s]", 4);

  breed("cave snake", 8, lightCoolGray, 40).attack("bite[s]", 10);
}

void trolls() {
  // "humanoid/troll"
}

void majorUndead() {}

void vampires() {}

void wraiths() {}

void xorns() {}

void serpents() {}

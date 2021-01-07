import '../../hues.dart';
import '../action/missive.dart';
import '../elements.dart';
import 'builder.dart';

// TODO: Describe other monsters.
void ancients() {}

void birds() {
  family("B")
    ..groups("bird")
    ..sense(see: 8, hear: 6)
    ..defense(10, "{1} flaps out of the way.")
    ..fly()
    ..count(3, 6);
  breed("crow", 4, darkCoolGray, 7, speed: 2, meander: 30)
    ..attack("bite[s]", 5)
    ..drop("treasure", percent: 10);
  describe(""""What harm can a stupid little crow do?" you think as it and its
      murderous friends dive towards your eyes, claws extended.""");

  breed("raven", 6, coolGray, 16, meander: 15)
    ..attack("bite[s]", 5)
    ..attack("claw[s]", 4)
    ..drop("treasure", percent: 10)
    ..flags("protective");
  describe("""It's black eyes gleam with a malevolent intelligence.""");
}

void canids() {}

void greaterDragons() {}

void elementals() {}

void faeFolk() {
  // Sprites, pixies, fairies, elves, etc.

  family("F", speed: 2, meander: 30, flags: "cowardly")
    ..groups("fae")
    ..sense(see: 10, hear: 8)
    ..defense(10, "{1} flits out of the way.")
    ..fly()
    ..preferOpen();
  breed("forest sprite", 2, mint, 6)
    ..attack("scratch[es]", 3)
    ..missive(Missive.insult, rate: 4)
    ..sparkBolt(rate: 7, damage: 4)
    ..drop("treasure", percent: 10)
    ..drop("magic", percent: 30);

  breed("house sprite", 5, lightBlue, 10)
    ..attack("poke[s]", 5)
    ..missive(Missive.insult, rate: 4)
    ..stoneBolt(rate: 10, damage: 4)
    ..teleport(rate: 7, range: 4)
    ..drop("treasure", percent: 10)
    ..drop("magic", percent: 30);

  breed("mischievous sprite", 7, pink, 24)
    ..attack("poke[s]", 6)
    ..missive(Missive.insult, rate: 4)
    ..windBolt(rate: 8, damage: 8)
    ..teleport(range: 5)
    ..drop("treasure", percent: 10)
    ..drop("magic", percent: 30);

  breed("Tink", 8, peaGreen, 40, meander: 10)
    ..she()
    ..attack("poke[s]", 8)
    ..missive(Missive.insult, rate: 4)
    ..sparkBolt(rate: 7, damage: 4)
    ..windBolt(rate: 8, damage: 7)
    ..teleport(range: 5)
    ..drop("treasure", count: 2)
    ..drop("magic", count: 3, depthOffset: 3)
    ..flags("unique");

  // TODO: https://en.wikipedia.org/wiki/Puck_(folklore)
}

void golems() {
  // TODO: Animated dolls, poppets, and marionettes.
}

void hybrids() {
  family("H")
    ..groups("hybrid")
    ..sense(see: 10, hear: 12);

  // TODO: Cause disease when scratched?
  breed("harpy", 25, lilac, 50, speed: 2)
    ..fly()
    ..count(2, 5)
    ..attack("bite[s]", 10)
    ..attack("scratch[es]", 15)
    ..howl(verb: "screeches")
    ..missive(Missive.screech);

  breed("griffin", 35, gold, 200)
    ..attack("bite[s]", 20)
    ..attack("scratch[es]", 15);

  // TODO: https://en.wikipedia.org/wiki/List_of_hybrid_creatures_in_folklore
}

void insubstantials() {}

void krakens() {}

void lichs() {}

void hydras() {}

void demons() {}

void ogres() {}

void giants() {}

void quest() {
  // TODO: Better group?
  family("Q").groups("magical");
  breed("Nameless Unmaker", 100, purple, 1000, speed: 2)
    ..sense(see: 16, hear: 16)
    ..attack("crushe[s]", 250, Elements.earth)
    ..attack("blast[s]", 200, Elements.lightning)
    ..darkCone(damage: 500)
    ..flags("fearless unique")
    ..openDoors()
    ..drop("item", count: 20, affixChance: 50);
  // TODO: Minions. Moves.
}

void reptiles() {
  family("R").groups("herp");
  breed("frog", 1, lima, 4, dodge: 30, meander: 30)
    ..sense(see: 6, hear: 4)
    ..swim()
    ..attack("hop[s] on", 2);

  family("R", dodge: 30, meander: 20)
    ..groups("salamander")
    ..sense(see: 6, hear: 5)
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
  family("S", dodge: 30, meander: 30)
    ..groups("snake")
    ..sense(see: 4, hear: 7);
  breed("water snake", 1, lima, 9).attack("bite[s]", 3);

  breed("brown snake", 3, tan, 25).attack("bite[s]", 4);

  breed("cave snake", 8, lightCoolGray, 40).attack("bite[s]", 10);
}

void trolls() {}

void majorUndead() {}

void vampires() {}

void wraiths() {}

void xorns() {}

void serpents() {}

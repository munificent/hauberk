import '../../hues.dart';
import '../elements.dart';
import 'builder.dart';

void ancients() {}

void birds() {
  family("B")
    ..groups("animal")
    ..defense(10, "{1} flaps out of the way.")
    ..fly()
    ..count(3, 6);
  breed("crow", 4, steelGray, 9, speed: 2, meander: 4)
    ..attack("bite[s]", 5)
    ..drop("Black Feather", percent: 25);

  breed("raven", 6, slate, 22, meander: 1)
    ..attack("bite[s]", 5)
    ..attack("claw[s]", 4)
    ..drop("Black Feather", percent: 20)
    ..flags("protective");
}

void canids() {}

void greaterDragons() {}

void elementals() {}

void faeFolk() {
  // Sprites, pixies, fairies, elves, etc.

  family("F", speed: 2, meander: 4, flags: "cowardly")
    ..groups("fae")
    ..defense(10, "{1} flits out of the way.")
    ..fly()
    ..preferOpen();
  breed("forest sprite", 2, mint, 6)
    ..attack("scratch[es]", 3)
    ..insult(rate: 4)
    ..sparkBolt(rate: 7, damage: 4)
    ..drop("magic", percent: 60);

  breed("house sprite", 5, cornflower, 10)
    ..attack("poke[s]", 5)
    ..insult(rate: 4)
    ..stoneBolt(rate: 10, damage: 4)
    ..teleport(rate: 7, range: 4)
    ..drop("magic", percent: 80);

  breed("mischievous sprite", 7, salmon, 24)
    ..attack("stab[s]", 6)
    ..insult(rate: 4)
    ..windBolt(rate: 8, damage: 8)
    ..teleport(range: 5)
    ..drop("magic");
}

void golems() {}

void hybrids() {}

void insubstantials() {}

void krakens() {}

void lichs() {}

void hydras() {}

void demons() {}

void ogres() {}

void giants() {}

void quest() {
  family("Q");
  breed("Nameless Unmaker", 100, violet, 1000, speed: 2)
    ..attack("crushe[s]", 250, Elements.earth)
    ..attack("blast[s]", 200, Elements.lightning)
    ..darkCone(damage: 500)
    ..flags("fearless unique")
    ..openDoors();
  // TODO: Minions. Moves.
}

void reptiles() {
  family("R")..groups("animal");
  breed("frog", 1, lima, 4, dodge: 30, meander: 4)
    ..swim()
    ..placeIn("aquatic")
    ..attack("hop[s] on", 2);

  family("R", meander: 1, flags: "fearless")..groups("saurian");
  breed("lizard guard", 11, gold, 26)
    ..attack("claw[s]", 8)
    ..attack("bite[s]", 10);

  breed("lizard protector", 15, lima, 30)
    ..minion("lizard guard", 0, 2)
    ..attack("claw[s]", 10)
    ..attack("bite[s]", 14);

  breed("armored lizard", 17, gunsmoke, 38)
    ..minion("lizard guard", 0, 2)
    ..attack("claw[s]", 10)
    ..attack("bite[s]", 15);

  breed("scaled guardian", 19, steelGray, 50)
    ..minion("lizard protector", 0, 2)
    ..minion("lizard guard", 0, 1)
    ..minion("salamander", 0, 1)
    ..attack("claw[s]", 10)
    ..attack("bite[s]", 15);

  breed("saurian", 21, carrot, 64)
    ..minion("lizard protector", 0, 2)
    ..minion("armored lizard", 0, 1)
    ..minion("lizard guard", 0, 1)
    ..minion("salamander", 0, 2)
    ..attack("claw[s]", 12)
    ..attack("bite[s]", 17);

  family("R", dodge: 30, meander: 3)
    ..groups("animal")
    ..preferOpen()
    ..emanate(3);
  breed("juvenile salamander", 7, salmon, 40)
    ..attack("bite[s]", 14, Elements.fire)
    ..fireCone(rate: 16, damage: 30, range: 6);

  breed("salamander", 13, brickRed, 60)
    ..attack("bite[s]", 18, Elements.fire)
    ..fireCone(rate: 16, damage: 50, range: 8);
}

void snakes() {
  family("S", speed: 1, dodge: 30, meander: 4)..groups("animal");
  breed("garter snake", 1, lima, 9)
    ..placeIn("aquatic")
    ..attack("bite[s]", 3);

  breed("brown snake", 3, persimmon, 25)
    ..placeIn("aquatic")
    ..attack("bite[s]", 4);

  breed("cave snake", 7, gunsmoke, 50)
    ..placeIn("passage")
    ..attack("bite[s]", 16);
}

void trolls() {}

void majorUndead() {}

void vampires() {}

void wraiths() {}

void xorns() {}

void serpents() {}

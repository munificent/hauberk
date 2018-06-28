import '../../hues.dart';
import '../action/missive.dart';
import '../elements.dart';
import '../tiles.dart';
import 'builder.dart';

void arachnids() {
  // TODO: Should all spiders hide in passages?
  family("a", flags: "fearless")
    ..groups("bug")
    ..placeIn("passage")
    ..stain(Tiles.spiderweb);
  breed("brown spider", 5, persimmon, 6, dodge: 30, meander: 40)
    ..attack("bite[s]", 5, Elements.poison);

  breed("gray spider", 7, slate, 12, dodge: 30, meander: 30)
    ..attack("bite[s]", 5, Elements.poison);

  breed("spiderling", 9, ash, 8, dodge: 35, meander: 50)
    ..count(2, 5)
    ..attack("bite[s]", 5, Elements.poison);

  breed("giant spider", 12, ultramarine, 40, meander: 30)
    ..attack("bite[s]", 5, Elements.poison);
}

void bats() {
  family("b")
    ..groups("animal")
    ..fly()
    ..placeIn("room", "passage")
    ..preferOpen();
  breed("brown bat", 1, persimmon, 3, frequency: 0.5, speed: 1, meander: 50)
    ..defense(20, "{1} flits out of the way.")
    ..count(2, 4)
    ..attack("bite[s]", 3);

  breed("giant bat", 4, garnet, 24, speed: 1, meander: 30).attack("bite[s]", 6);

  breed("cave bat", 6, gunsmoke, 30, speed: 2, meander: 40)
    ..defense(20, "{1} flits out of the way.")
    ..count(2, 5)
    ..attack("bite[s]", 6);
}

void canines() {
  family("c", dodge: 25, tracking: 20, meander: 25)
    ..placeIn("room", "passage")
    ..groups("animal");
  breed("mangy cur", 2, buttermilk, 11)
    ..count(4)
    ..attack("bite[s]", 4)
    ..howl(range: 6)
    ..drop("Fur Pelt", percent: 20);

  breed("wild dog", 4, gunsmoke, 20)
    ..count(4)
    ..attack("bite[s]", 6)
    ..howl(range: 8)
    ..drop("Fur Pelt", percent: 20);

  breed("mongrel", 7, carrot, 28)
    ..count(2, 5)
    ..attack("bite[s]", 8)
    ..howl(range: 10)
    ..drop("Fur Pelt", percent: 20);
}

void dragons() {
  // TODO: Tune. Give more attacks. Tune drops.
  family("d")
    ..groups("dragon")
    ..defense(20, "{2} [is|are] deflected by its scales.")
    ..preferOpen();
  breed("red dragon", 50, brickRed, 400)
    ..attack("bite[s]", 80)
    ..attack("claw[s]", 60)
    ..fireCone(damage: 100)
    ..drop("magic", count: 6)
    ..drop("equipment", count: 5);
}

void eyes() {
  family("e", flags: "immobile")
    ..placeIn("laboratory")
    ..defense(10, "{1} blinks out of the way.")
    ..fly()
    ..preferOpen();
  breed("lazy eye", 5, cornflower, 12)
    ..attack("stare[s] at", 8)
    ..sparkBolt(rate: 6, damage: 12, range: 8);

  breed("mad eye", 9, salmon, 40)
    ..attack("stare[s] at", 8)
    ..windBolt(rate: 6, damage: 20);

  breed("floating eye", 15, buttermilk, 60)
    ..attack("stare[s] at", 10)
    ..sparkBolt(rate: 4, damage: 24)
    ..teleport(rate: 10, range: 7);

  breed("baleful eye", 20, carrot, 80)
    ..attack("gaze[s] into", 12)
    ..fireBolt(rate: 4, damage: 20)
    ..waterBolt(rate: 4, damage: 20)
    ..teleport(rate: 10, range: 9);

  breed("malevolent eye", 30, brickRed, 120)
    ..attack("gaze[s] into", 20)
    ..lightBolt(rate: 4, damage: 20)
    ..darkBolt(rate: 4, damage: 20)
    ..fireCone(rate: 7, damage: 30)
    ..teleport(rate: 10, range: 9);

  breed("murderous eye", 40, maroon, 180)
    ..attack("gaze[s] into", 30)
    ..acidBolt(rate: 7, damage: 50)
    ..stoneBolt(rate: 7, damage: 50)
    ..iceCone(rate: 7, damage: 40)
    ..teleport(rate: 10, range: 9);

  breed("watcher", 60, gunsmoke, 300)
    ..attack("see[s]", 50)
    ..lightBolt(rate: 7, damage: 40)
    ..lightCone(rate: 7, damage: 60)
    ..darkBolt(rate: 7, damage: 50)
    ..darkCone(rate: 7, damage: 70);

  // beholder, undead beholder, rotting beholder
}

void felines() {
  family("f")
    ..placeIn("room", "passage")
    ..groups("animal");
  breed("stray cat", 1, gold, 9, speed: 1, meander: 30)
    ..attack("bite[s]", 5)
    ..attack("scratch[es]", 4);
}

void goblins() {
  family("g", meander: 10)
    ..groups("goblin")
    ..openDoors()
    ..emanate(2);
  breed("goblin peon", 4, sandal, 26, meander: 20)
    ..count(4)
    ..attack("stab[s]", 8)
    ..missive(Missive.insult, rate: 8)
    ..drop("spear", percent: 20)
    ..drop("healing", percent: 10);

  breed("goblin archer", 6, peaGreen, 32)
    ..count(2)
    ..minion("goblin peon", 0, 2)
    ..attack("stab[s]", 4)
    ..arrow(rate: 3, damage: 8)
    ..drop("bow", percent: 30)
    ..drop("dagger", percent: 15)
    ..drop("healing", percent: 5);

  breed("goblin fighter", 6, persimmon, 58)
    ..count(2)
    ..minion("goblin archer", 0, 1)
    ..minion("goblin peon", 0, 3)
    ..attack("stab[s]", 12)
    ..drop("spear", percent: 20)
    ..drop("armor", percent: 20)
    ..drop("resistance", percent: 5)
    ..drop("healing", percent: 5);

  breed("goblin warrior", 8, gunsmoke, 68)
    ..count(2)
    ..minion("goblin fighter", 0, 1)
    ..minion("goblin archer", 0, 1)
    ..minion("goblin peon", 0, 3)
    ..attack("stab[s]", 16)
    ..drop("axe", percent: 20)
    ..drop("armor", percent: 20)
    ..drop("resistance", percent: 5)
    ..drop("healing", percent: 5)
    ..flags("protective");

  breed("goblin mage", 9, ultramarine, 50)
    ..placeIn("laboratory")
    ..minion("goblin fighter", 0, 1)
    ..minion("goblin archer", 0, 1)
    ..minion("goblin peon", 0, 2)
    ..attack("whip[s]", 7)
    ..fireBolt(rate: 12, damage: 12)
    ..sparkBolt(rate: 12, damage: 16)
    ..drop("robe", percent: 20)
    ..drop("whip", percent: 10)
    ..drop("magic", percent: 30);

  breed("goblin ranger", 12, sherwood, 60)
    ..minion("goblin mage", 0, 1)
    ..minion("goblin fighter", 0, 1)
    ..minion("goblin archer", 0, 1)
    ..minion("goblin peon", 0, 2)
    ..attack("stab[s]", 10)
    ..arrow(rate: 3, damage: 12)
    ..drop("bow", percent: 30)
    ..drop("armor", percent: 20)
    ..drop("magic", percent: 20);

  // TODO: Always drop something good.
  breed("Erlkonig, the Goblin Prince", 14, steelGray, 120)
    ..placeIn("great-hall")
    ..he()
    ..minion("goblin mage", 1, 2)
    ..minion("goblin fighter", 1, 3)
    ..minion("goblin archer", 1, 3)
    ..minion("goblin peon", 2, 4)
    ..attack("hit[s]", 10)
    ..attack("slash[es]", 14)
    ..darkBolt(rate: 20, damage: 20)
    ..drop("equipment", count: 2, depthOffset: 3)
    ..drop("magic", count: 3, depthOffset: 4)
    ..flags("protective unique");

  // TODO: Hobgoblins, bugbears, bogill.
  // TODO: https://en.wikipedia.org/wiki/Moss_people
}

void humanoids() {}

void insects() {
  family("i", tracking: 3, meander: 40, flags: "fearless")
    ..placeIn("room", "passage")
    ..groups("bug");
  // TODO: Spawn as eggs which can hatch into cockroaches?
  breed("giant cockroach[es]", 1, garnet, 1, frequency: 0.4)
    ..placeIn("food", "storage")
    ..count(1, 3)
    ..preferCorner()
    ..attack("crawl[s] on", 2)
    ..spawn(rate: 6);

  breed("giant centipede", 3, brickRed, 14, speed: 2, meander: 20)
    ..attack("crawl[s] on", 4)
    ..attack("bite[s]", 8);
}

void jellies() {
  family("j", frequency: 0.7, speed: -1, meander: 30, flags: "fearless")
    ..groups("jelly")
    ..placeIn("laboratory")
    ..preferWall()
    ..count(4);
  breed("green jelly", 1, lima, 5)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 3);
  // TODO: More elements.

  family("j", frequency: 0.6, flags: "fearless immobile")
    ..groups("jelly")
    ..placeIn("laboratory")
    ..preferCorner()
    ..count(4);
  breed("green slime", 2, peaGreen, 10)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 4)
    ..spawn(rate: 4);

  breed("frosty slime", 4, ash, 14)
    ..stain(Tiles.whiteJellyStain)
    ..attack("crawl[s] on", 5, Elements.cold)
    ..spawn(rate: 4);

  breed("mud slime", 6, persimmon, 20)
    ..stain(Tiles.brownJellyStain)
    ..attack("crawl[s] on", 8, Elements.earth)
    ..spawn(rate: 4);

  breed("smoking slime", 15, brickRed, 30)
    ..emanate(4)
    ..stain(Tiles.redJellyStain)
    ..attack("crawl[s] on", 10, Elements.fire)
    ..spawn(rate: 4);

  breed("sparkling slime", 20, violet, 40)
    ..emanate(3)
    ..stain(Tiles.violetJellyStain)
    ..attack("crawl[s] on", 12, Elements.lightning)
    ..spawn(rate: 4);

  // TODO: Erode nearby walls?
  breed("caustic slime", 25, mint, 50)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 13, Elements.acid)
    ..spawn(rate: 4);

  breed("virulent slime", 35, sherwood, 60)
    ..stain(Tiles.greenJellyStain)
    ..attack("crawl[s] on", 14, Elements.poison)
    ..spawn(rate: 4);

  // TODO: Fly?
  breed("ectoplasm", 45, steelGray, 40)
    ..stain(Tiles.grayJellyStain)
    ..attack("crawl[s] on", 15, Elements.spirit)
    ..spawn(rate: 4);
}

void kobolds() {
  family("k", meander: 15, flags: "cowardly")..groups("kobold");
  breed("scurrilous imp", 1, salmon, 8, meander: 20)
    ..count(2)
    ..attack("club[s]", 4)
    ..missive(Missive.insult)
    ..haste()
    ..drop("club", percent: 40)
    ..drop("speed", percent: 30);

  breed("vexing imp", 2, violet, 10)
    ..count(2)
    ..minion("scurrilous imp", 0, 1)
    ..attack("scratch[es]", 4)
    ..missive(Missive.insult)
    ..sparkBolt(rate: 5, damage: 6)
    ..drop("teleportation", percent: 50);

  family("k", meander: 20)..groups("kobold");
  breed("kobold", 3, brickRed, 12)
    ..count(3)
    ..minion("wild dog", 0, 3)
    ..attack("poke[s]", 4)
    ..teleport(rate: 10, range: 6)
    ..drop("equipment", percent: 20)
    ..drop("magic", percent: 40);

  breed("kobold shaman", 4, ultramarine, 16)
    ..placeIn("laboratory")
    ..count(2)
    ..minion("wild dog", 0, 3)
    ..attack("hit[s]", 4)
    ..waterBolt(rate: 5, damage: 6)
    ..drop("robe", percent: 20)
    ..drop("magic", percent: 40);

  breed("kobold trickster", 5, gold, 20)
    ..attack("hit[s]", 5)
    ..missive(Missive.insult)
    ..sparkBolt(rate: 5, damage: 8)
    ..teleport(rate: 7, range: 6)
    ..haste(rate: 7)
    ..drop("magic", percent: 20)
    ..drop("magic", percent: 40);

  breed("kobold priest", 6, cerulean, 25)
    ..count(2)
    ..minion("kobold", 1, 3)
    ..attack("club[s]", 6)
    ..heal(rate: 15, amount: 10)
    ..fireBolt(rate: 10, damage: 8)
    ..haste(rate: 7)
    ..drop("club", percent: 40)
    ..drop("robe", percent: 20)
    ..drop("magic", percent: 40);

  breed("imp incanter", 7, lilac, 18)
    ..placeIn("laboratory")
    ..count(2)
    ..minion("kobold", 1, 3)
    ..minion("wild dog", 0, 3)
    ..attack("scratch[es]", 4)
    ..missive(Missive.insult, rate: 6)
    ..fireBolt(rate: 5, damage: 10)
    ..drop("robe", percent: 20)
    ..drop("magic", percent: 50)
    ..flags("cowardly");

  breed("imp warlock", 8, indigo, 40)
    ..placeIn("laboratory")
    ..minion("imp incanter", 1, 3)
    ..minion("kobold", 1, 3)
    ..minion("wild dog", 0, 3)
    ..attack("stab[s]", 5)
    ..iceBolt(rate: 8, damage: 12)
    ..fireBolt(rate: 8, damage: 12)
    ..drop("staff", percent: 40)
    ..drop("robe", percent: 20)
    ..drop("magic", count: 2, percent: 60);

  // TODO: Always drop something good.
  breed("Feng", 10, carrot, 60, speed: 1, meander: 10)
    ..he()
    ..minion("imp warlock", 1, 2)
    ..minion("imp incanter", 1, 2)
    ..minion("kobold priest", 1, 2)
    ..minion("kobold", 1, 3)
    ..minion("wild dog", 0, 3)
    ..attack("stab[s]", 5)
    ..missive(Missive.insult, rate: 7)
    ..teleport(rate: 5, range: 6)
    ..teleport(rate: 50, range: 30)
    ..lightningCone(rate: 8, damage: 12)
    ..drop("spear", percent: 80, depthOffset: 5)
    ..drop("armor", count: 2, depthOffset: 5)
    ..drop("magic", count: 3, depthOffset: 5)
    ..flags("unique");

  // homonculous
}

void lizardMen() {
  // troglodyte
  // reptilian
}

void mushrooms() {}

void nagas() {}

void orcs() {}

void people() {
  family("p", tracking: 14, meander: 10)
    ..groups("human")
    ..openDoors()
    ..emanate(2);
  breed("Harold the Misfortunate", 1, lilac, 20)
    ..he()
    ..attack("hit[s]", 3)
    ..missive(Missive.clumsy)
    ..drop("weapon", percent: 50, depthOffset: 4)
    ..drop("armor", percent: 60, depthOffset: 4)
    ..drop("magic", percent: 30, depthOffset: 4)
    ..flags("unique");
  // TODO: Make more interesting.

  breed("hapless adventurer", 1, buttermilk, 14, dodge: 15, meander: 30)
    ..attack("hit[s]", 3)
    ..missive(Missive.clumsy, rate: 12)
    ..drop("weapon", percent: 50)
    ..drop("armor", percent: 60)
    ..drop("magic", percent: 30)
    ..flags("cowardly");

  breed("simpering knave", 2, carrot, 17)
    ..attack("hit[s]", 2)
    ..attack("stab[s]", 4)
    ..drop("whip", percent: 30)
    ..drop("armor", percent: 40)
    ..drop("magic", percent: 20)
    ..flags("cowardly");

  breed("decrepit mage", 3, violet, 20, meander: 30)
    ..placeIn("laboratory")
    ..attack("hit[s]", 2)
    ..sparkBolt(rate: 10, damage: 8)
    ..drop("magic", percent: 60)
    ..drop("dagger", percent: 10)
    ..drop("staff", percent: 10)
    ..drop("robe", percent: 20)
    ..drop("boots", percent: 20);

  breed("unlucky ranger", 5, peaGreen, 30, dodge: 25, meander: 20)
    ..attack("slash[es]", 2)
    ..arrow(rate: 4, damage: 2)
    ..missive(Missive.clumsy, rate: 10)
    ..drop("potion", percent: 30)
    ..drop("bow", percent: 40)
    ..drop("sword", percent: 10)
    ..drop("body", percent: 20);

  breed("drunken priest", 5, cerulean, 34, meander: 40)
    ..attack("hit[s]", 8)
    ..heal(rate: 15, amount: 8)
    ..missive(Missive.clumsy)
    ..drop("scroll", percent: 30)
    ..drop("club", percent: 20)
    ..drop("robe", percent: 40)
    ..flags("fearless");
}

void quadrupeds() {}

void rodents() {
  family("r", dodge: 30, meander: 30)
    ..placeIn("food", "passage")
    ..groups("animal")
    ..preferWall();
  breed("[mouse|mice]", 1, sandal, 2, frequency: 0.7)
    ..count(2, 5)
    ..attack("bite[s]", 3)
    ..attack("scratch[es]", 2);

  breed("sewer rat", 2, steelGray, 8, meander: 20)
    ..count(1, 4)
    ..attack("bite[s]", 4)
    ..attack("scratch[es]", 3);

  breed("sickly rat", 3, peaGreen, 16)
    ..attack("bite[s]", 8, Elements.poison)
    ..attack("scratch[es]", 4);

  breed("plague rat", 6, lima, 20)
    ..count(1, 4)
    ..attack("bite[s]", 15, Elements.poison)
    ..attack("scratch[es]", 8);
}

void slugs() {
  family("s", tracking: 2, flags: "fearless", speed: -3, dodge: 5, meander: 30)
    ..placeIn("passage")
    ..groups("bug");
  breed("giant slug", 3, mustard, 20)..attack("crawl[s] on", 8);

  breed("suppurating slug", 6, lima, 50)
    ..attack("crawl[s] on", 12, Elements.poison);
}

void troglodytes() {}

void minorUndead() {}

void vines() {}

void worms() {
  family("w", dodge: 15, meander: 40, flags: "fearless")
    ..placeIn("passage")
    ..groups("bug");
  breed("blood worm", 1, maroon, 4, frequency: 0.5)
    ..count(2, 5)
    ..attack("crawl[s] on", 5);

  breed("fire worm", 10, carrot, 6)
    ..count(2, 6)
    ..preferWall()
    ..attack("crawl[s] on", 5, Elements.fire);

  family("w", dodge: 10, meander: 30, flags: "fearless");
  breed("giant earthworm", 3, salmon, 20, speed: -2)..attack("crawl[s] on", 5);

  breed("giant cave worm", 7, sandal, 80, speed: -2)
    ..attack("crawl[s] on", 8, Elements.acid);
}

void skeletons() {}

void zombies() {}

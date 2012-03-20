#library('roguekit-content.dart');

#import('engine.dart');
#import('ui.dart');

/// Defines the actual content for the game: the breeds, items, etc. that define
/// the play experience.
class Content {
  final List<Breed> breeds;

  Content()
  : breeds = <Breed>[];

  List<Breed> create() {
    // $  Creeping Coins
    // a  Arachnid/Scorpion   A  Ancient being
    // b  Giant Bat           B  Bird
    // c  Canine (Dog)        C  Canid (Dog-like humanoid, kobold)
    // d  Dragon              D  Ancient Dragon
    // e  Floating Eye        E  Elemental
    // f  Flying Insect       F  Feline (Cat)
    // g  Golem               G  Ghost
    // h  Humanoids           H  Hybrid
    // i  Insect              I  Goblin / Imp
    // j  Jelly               J  Slime
    // k  Skeleton            K  Kraken/Land Octopus
    // l  Lizard man          L  Lich
    // m  Mold/Mushroom       M  Multi-Headed Hydra
    // n  Naga                N  End boss
    // o  Orc                 O  Ogre
    // p  Human "person"      P  Giant "person"
    // q  Quadruped           Q  Quylthulg (Pulsing Flesh Mound)
    // r  Rodent              R  Reptile/Amphibian
    // s  Slug                S  Snake
    // t  Troglodyte          T  Troll
    // u  Minor Demon         U  Major Demon
    // v  Vine/Plant          V  Vampire
    // w  Worm or Worm Mass   W  Wight/Wraith
    // x  (unused)            X  Xorn/Xaren
    // y  Yeek                Y  Yeti
    // z  Zombie/Mummy        Z  Greater Zombie

    breed('rat', brown('r'), [
        attack('bite[s]', 3),
        attack('scratch[es]', 2)
      ],
      maxHealth: 4,
      olfaction: 2,
      meander: 3
    );

    breed('slug', lightGreen('s'), [
        attack('crawl[s] on', 2),
      ],
      maxHealth: 8,
      meander: 6,
      speed: -2
    );

    return breeds;
  }

  Breed breed(String name, Glyph appearance, List<Attack> attacks,
      [int maxHealth, int olfaction = 0, int meander, int speed = 0]) {
    final breed = new Breed(name, Gender.NEUTER, appearance, attacks,
        maxHealth: maxHealth, olfaction: olfaction, meander: meander,
        speed: speed);
    breeds.add(breed);
    return breed;
  }

  Attack attack(String verb, int damage) => new Attack(verb, damage);

  Glyph white(String char) => new Glyph(char, Color.WHITE);
  Glyph brown(String char) => new Glyph(char, Color.BROWN);
  Glyph lightGreen(String char) => new Glyph(char, Color.LIGHT_GREEN);
}
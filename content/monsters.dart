/// Builder class for defining [Monster] [Breed]s.
class MonsterBuilder extends ContentBuilder {
  final Map<String, Breed> _breeds;

  MonsterBuilder()
  : _breeds = <Breed>{};

  Map<String, Breed> build() {
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
    // n  Naga                N  Demon
    // o  Orc                 O  Ogre
    // p  Human "person"      P  Giant "person"
    // q  Quadruped           Q  End boss ("quest")
    // r  Rodent              R  Reptile/Amphibian
    // s  Slug                S  Snake
    // t  Troglodyte          T  Troll
    // u  Minor Undead        U  Major Undead
    // v  Vine/Plant          V  Vampire
    // w  Worm or Worm Mass   W  Wight/Wraith
    // x  (unused)            X  Xorn/Xaren
    // y  Yeek                Y  Yeti
    // z  Zombie/Mummy        Z  Serpent (snake-like dragon)
    // TODO(bob):
    // - Come up with something better than yeeks for 'y'.
    // - Don't use both 'u' and 'U' for undead?

    breed('rat', brown('r'), [
        attack('bite[s]', 3),
        attack('scratch[es]', 2)
      ],
      maxHealth: 4,
      olfaction: 2,
      meander: 3,
      speed: 1
    );

    breed('mangy cur', gray('c'), [
        attack('bite[s]', 4),
      ],
      maxHealth: 7,
      olfaction: 5,
      meander: 3
    );

    breed('giant slug', green('s'), [
        attack('crawl[s] on', 8),
      ],
      maxHealth: 12,
      meander: 4,
      speed: -3
    );

    breed('giant dragonfly', blue('f'), [
        attack('sting[s]', 2),
      ],
      maxHealth: 2,
      meander: 8,
      speed: 2
    );

    return _breeds;
  }

  Breed breed(String name, Glyph appearance, List<Attack> attacks,
      [int maxHealth, int olfaction = 0, int meander = 0, int speed = 0]) {
    final breed = new Breed(name, Gender.NEUTER, appearance, attacks,
        maxHealth: maxHealth, olfaction: olfaction, meander: meander,
        speed: speed);
    _breeds[name] = breed;
    return breed;
  }
}

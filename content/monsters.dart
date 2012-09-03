/// Builder class for defining [Monster] [Breed]s.
class MonsterBuilder extends ContentBuilder {
  final Map<String, Breed> _breeds;
  final Map<String, ItemType> _items;

  MonsterBuilder(this._items)
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

    arachnids();
    bats();
    canines();
    felines();
    humanoids();
    insects();
    people();
    rodents();
    slugs();

    return _breeds;
  }

  arachnids() {
    breed('garden spider', darkAqua('a'), [
        attack('bite[s]', 2)
      ],
      maxHealth: 2, meander: 8,
      flags: 'group'
    );

    breed('giant spider', darkBlue('a'), [
        attack('bite[s]', 8)
      ],
      maxHealth: 2, meander: 5
    );
  }

  bats() {
    breed('little brown bat', lightBrown('b'), [
        attack('bite[s]', 3),
      ],
      maxHealth: 4, meander: 6, speed: 2
    );
  }

  canines() {
    breed('mangy cur', yellow('c'), [
        attack('bite[s]', 4),
      ],
      maxHealth: 7, olfaction: 5, meander: 3,
      flags: 'few'
    );

    breed('wild dog', gray('c'), [
        attack('bite[s]', 5),
      ],
      maxHealth: 9, olfaction: 5, meander: 3,
      flags: 'few'
    );
  }

  felines() {
    breed('stray cat', gray('F'), [
        attack('bite[s]', 4),
        attack('scratch[es]', 3),
      ],
      maxHealth: 5, meander: 3, olfaction: 7, speed: 1
    );
  }

  humanoids() {
  }

  insects() {
    breed('giant cockroach', darkBrown('i'), [
        attack('crawl[s] on', 1),
      ],
      maxHealth: 12, meander: 8, speed: 3
    );
  }

  people() {
    breed('doddering old mage', purple('p'), [
        attack('hit[s]', 3),
        sparkBolt(cost: 100, damage: 6)
      ],
      drops: ['Scroll of Sidestepping', 'Staff', 'Dagger', 'Robe'],
      maxHealth: 7, meander: 2,
      flags: 'open-doors'
    );

    breed('drunken priest', aqua('p'), [
        attack('hit[s]', 3),
        heal(cost: 100, amount: 8)
      ],
      drops: ['Mending Salve', 'Cudgel', 'Staff', 'Robe'],
      maxHealth: 8, meander: 4,
      flags: 'open-doors'
    );
  }

  rodents() {
    breed('white mouse', white('r'), [
        attack('bite[s]', 3),
        attack('scratch[es]', 2)
      ],
      maxHealth: 3, olfaction: 2, meander: 4, speed: 1
    );

    breed('sewer rat', darkGray('r'), [
        attack('bite[s]', 3),
        attack('scratch[es]', 2)
      ],
      maxHealth: 4, olfaction: 2, meander: 3, speed: 1,
      flags: 'group'
    );
  }

  slugs() {
    breed('giant slug', green('s'), [
        attack('crawl[s] on', 8),
      ],
      maxHealth: 12, meander: 4, speed: -3
    );
  }

  Breed breed(String name, Glyph appearance, List actions, [
      List<String> drops, int maxHealth, int olfaction = 0,
      int meander = 0, int speed = 0, String flags = '']) {

    var attacks = <Attack>[];
    var moves = <Move>[];

    for (final action in actions) {
      if (action is Attack) attacks.add(action);
      if (action is Move) moves.add(action);
    }

    var dropTypes;
    if (drops == null) {
      dropTypes = <ItemType>[];
    } else {
      dropTypes = drops.map((name) => _items[name]);
    }

    final breed = new Breed(name, Gender.NEUTER, appearance, attacks, moves,
        dropTypes, maxHealth: maxHealth, olfaction: olfaction, meander: meander,
        speed: speed, flags: new Set<String>.from(flags.split(' ')));
    _breeds[name] = breed;
    return breed;
  }

  Move heal([int cost, int amount]) => new HealMove(cost, amount);

  Move sparkBolt([int cost, int damage]) =>
      new BoltMove(cost, new Attack('zaps', damage, new Noun('the spark')));
}

/// Builder class for defining [ItemType]s.
class ItemBuilder extends ContentBuilder {
  int _sortIndex = 0;

  Map<String, ItemType> build() {
    // From Angband:
    // !   A potion (or flask)    /   A pole-arm
    // ?   A scroll (or book)     |   An edged weapon
    // ,   Pelts and body parts   \   A hafted weapon
    // -   A wand or rod          }   A sling, bow, or x-bow
    // _   A staff                {   A shot, arrow, or bolt
    // =   A ring                 (   Soft armour (cloak, robes, leather armor)
    // "   An amulet              [   Hard armour (metal armor)
    // $   Gold or gems           ]   Misc. armour (gloves, helm, boots)
    // ~   Lites, Tools           )   A shield
    // &   Chests, Containers

    pelts();
    potions();
    scrolls();
    weapons();
    bows();
    bodyArmor();

    item('Magical Chalice', lightBlue(r'$'));
  }

  void pelts() {
    item('Fur pelt', lightBrown(','));
    item('Insect wing', purple(','));
    item('Black feather', darkGray(','));
  }

  void potions() {
    // Healing
    item('Soothing Balm', lightRed('!'), use: () => new HealAction(12));
    item('Mending Salve', red('!'), use: () => new HealAction(24));
    // balm of soothing, healing, amelioration, rejuvenation
  }

  void scrolls() {
    item('Parchment', gray('?'));

    // Teleportation
    // Phasing, Teleportation, Disappearing
    item('Scroll of Sidestepping', lightPurple('?'),
        use: () => new TeleportAction(7));
  }

  void weapons() {
    // Bludgeons.
    weapon('Cudgel', brown('\\'),    'hit[s]', 'Club', 4);
    weapon('Staff', lightBrown('_'), 'hit[s]', 'Club', 5);

    // Knives.
    weapon('Knife', gray('|'), 'stab[s]', 'Dagger', 4);
    weapon('Dirk', lightGray('|'), 'stab[s]', 'Dagger', 6);
    weapon('Dagger', white('|'), 'stab[s]', 'Dagger', 8);
    weapon('Stiletto', darkGray('|'), 'stab[s]', 'Dagger', 11);
    weapon('Rondel', lightAqua('|'), 'stab[s]', 'Dagger', 14);
    weapon('Baselard', lightBlue('|'), 'stab[s]', 'Dagger', 20);

    // Spears.
    weapon('Spear', gray('\\'), 'stab[s]', 'Spear', 8);
    weapon('Angon', lightGray('\\'), 'stab[s]', 'Spear', 16);
    weapon('Lance', white('\\'), 'stab[s]', 'Spear', 24);
    weapon('Partisan', darkGray('\\'), 'stab[s]', 'Spear', 36);

    // glaive, voulge, halberd, pole-axe, lucerne hammer,
  }

  void bows() {
    bow('Short Bow', brown('}'), 'the arrow', 4);
    bow('Longbow', lightBrown('}'), 'the arrow', 6);
    bow('Crossbow', gray('}'), 'the bolt', 10);
  }

  void bodyArmor() {
    armor('Fur Cloak', lightBrown('('), 'Cloak', 2);

    armor('Cloth Shirt', lightGray('('), 'Body', 2);
    armor('Robe', aqua('('), 'Body', 4);
    armor('Fur-lined Robe', darkAqua('('), 'Body', 6);
    /*
    Leather Shirt[s]
    Soft Leather Armor[s]
    Hard Leather Armor[s]
    Studded Leather Armor[s]
    Leather Scale Mail[s]
    Mail Hauberk[s]
    Metal Lamellar Armor[s]
    Chain Mail Armor[s]
    Metal Scale Mail[s]
    Plated Mail[s]
    Brigandine[s]
    Steel Breastplate[s]
    Partial Plate Armor[s]
    Full Plate Armor[s]
    */
  }

  ItemType weapon(String name, Glyph appearance, String verb, String category,
      int damage) {
    return item(name, appearance, equipSlot: 'Weapon', category: category,
        attack: attack(verb, damage, Element.NONE));
  }

  ItemType bow(String name, Glyph appearance, String noun, int damage) {
    return item(name, appearance, equipSlot: 'Bow', category: 'Bow',
        attack: attack('pierce[s]', damage, Element.NONE, new Noun(noun)));
  }

  ItemType armor(String name, Glyph appearance, String equipSlot, int armor) {
    return item(name, appearance, equipSlot: equipSlot, armor: armor);
  }

  ItemType item(String name, Glyph appearance,
      [ItemUse use, String equipSlot, String category, Attack attack,
       int armor = 0]) {
    final itemType = new ItemType(name, appearance, _sortIndex++, use,
        equipSlot, category, attack, armor);
    _items[name] = itemType;
    return itemType;
  }
}

class Drops {
  static final knife = _daggers.drop('Knife');
  static final dirk = _daggers.drop('Dirk');
  static final dagger = _daggers.drop('Dagger');
  static final stiletto = _daggers.drop('Stiletto');
  static final rondel = _daggers.drop('Rondel');
  static final baselard = _daggers.drop('Baselard');

  static final _daggers = _sequence(8, [
    'Knife', 'Dirk', 'Dagger', 'Stiletto', 'Rondel', 'Baselard'
  ]);

  static final spear = _spears.drop('Spear');
  static final angon = _spears.drop('Angon');
  static final lance = _spears.drop('Lance');
  static final partisan = _spears.drop('Partisan');

  static final _spears = _sequence(9, [
    'Spear', 'Angon', 'Lance', 'Partisan'
  ]);

  static EquipmentSequence _sequence(int chance, List<String> typeNames) {
    var types = typeNames.map((name) => _items[name]);
    return new EquipmentSequence(chance, types);
  }
}

class EquipmentSequence {
  final int chance;
  final List<ItemType> types;

  EquipmentSequence(this.chance, this.types);

  Drop drop(startItem) {
    // Find the index of the item in the sequence.
    var itemType = _items[startItem];
    for (var i = 0; i < types.length; i++) {
      if (types[i] == itemType) return new EquipmentDrop(this, i);
    }

    throw "Couldn't find $itemType in sequence.";
  }
}

class EquipmentDrop implements Drop {
  final EquipmentSequence sequence;
  final int startIndex;

  EquipmentDrop(this.sequence, this.startIndex);

  void spawnDrop(Game game, AddItem addItem) {
    var index = startIndex;

    // TODO(bob): Occasionally choose a worse item. If it does, increase the
    // chance of picking a power.

    // Chance of a better item.
    while (index < sequence.types.length - 1 && rng.oneIn(sequence.chance)) {
      index++;
    }

    // TODO(bob): Powers.

    var item = new Item(sequence.types[index]);
    addItem(item);
  }
}

class ItemDrop implements Drop {
  final ItemType type;

  ItemDrop(this.type);

  void spawnDrop(Game game, AddItem addItem) {
    addItem(new Item(type));
  }
}

class OneOfDrop implements Drop {
  final List<Drop> drops;
  final List<int> percents;

  OneOfDrop(this.drops, this.percents);

  void spawnDrop(Game game, AddItem addItem) {
    var roll = rng.range(100);

    for (var i = 0; i < drops.length; i++) {
      roll -= percents[i];
      if (roll <= 0) {
        drops[i].spawnDrop(game, addItem);
        return;
      }
    }
  }
}

class SkillDrop implements Drop {
  final Skill skill;
  final Drop drop;

  SkillDrop(this.skill, this.drop);

  void spawnDrop(Game game, AddItem addItem) {
    if (rng.range(100) < skill.getDropChance(game.hero.skills[skill])) {
      drop.spawnDrop(game, addItem);
    }
  }
}

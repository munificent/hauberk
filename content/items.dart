/// Builder class for defining [ItemType]s.
class ItemBuilder extends ContentBuilder {
  final Map<String, ItemType> _items;
  int _sortIndex = 0;

  ItemBuilder()
  : _items = <ItemType>{};

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
    bodyArmor();

    item('Magical Chalice', lightBlue(@'$'),
        use: () => new QuestAction());

    return _items;
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
    weapon('Cudgel', brown('\\'),    'hit[s]', 'Club', 4);
    weapon('Staff', lightBrown('_'), 'hit[s]', 'Club', 5);
    weapon('Dagger', lightGray('|'), 'stab[s]', 'Dagger', 5);
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

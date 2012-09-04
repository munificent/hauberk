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
    // ,   A mushroom (or food)   \   A hafted weapon
    // -   A wand or rod          }   A sling, bow, or x-bow
    // _   A staff                {   A shot, arrow, or bolt
    // =   A ring                 (   Soft armour (cloak, robes, leather armor)
    // "   An amulet              [   Hard armour (metal armor)
    // $   Gold or gems           ]   Misc. armour (gloves, helm, boots)
    // ~   Lites, Tools           )   A shield
    // &   Chests, Containers

    /*
    food();
    */
    potions();
    scrolls();
    weapons();
    bodyArmor();

    item('Magical Chalice', lightBlue(@'$'),
        use: () => new QuestAction());

    return _items;
  }

  /*
  void food() {
    item('Crusty Loaf of Bread', yellow(','),
        use: () => new EatAction(400));
  }
  */

  void potions() {
    // Healing
    item('Mending Salve', red('!'),
        use: () => new HealAction(12));
    // balm of soothing, healing, amelioration, rejuvenation
  }

  void scrolls() {
    // Teleportation
    // Phasing, Teleportation, Disappearing
    item('Scroll of Sidestepping', lightPurple('?'),
        use: () => new TeleportAction(7));
  }

  void weapons() {
    weapon('Cudgel', brown('\\'),    'hit[s]', 4);
    weapon('Staff', lightBrown('_'), 'hit[s]', 5);
    weapon('Dagger', lightGray('|'), 'stab[s]', 5);
  }

  void bodyArmor() {
    armor('Cloth Shirt', lightGray(']'), 'Body', 2);
    armor('Robe', aqua(']'), 'Body', 4);
    armor('Lined Robe', purple(']'), 'Body', 6);
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

  Attack attack(String verb, int damage) => new Attack(verb, damage);

  ItemType weapon(String name, Glyph appearance, String verb, int damage) {
    return item(name, appearance, equipSlot: 'Weapon',
        attack: attack(verb, damage));
  }

  ItemType armor(String name, Glyph appearance, String equipSlot, int armor) {
    return item(name, appearance, equipSlot: equipSlot, armor: armor);
  }

  ItemType item(String name, Glyph appearance,
      [ItemUse use, String equipSlot, Attack attack, int armor = 0]) {
    final itemType = new ItemType(name, appearance, _sortIndex++, use,
        equipSlot, attack, armor);
    _items[name] = itemType;
    return itemType;
  }
}

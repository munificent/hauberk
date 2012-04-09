/// Builder class for defining [ItemType]s.
class ItemBuilder extends ContentBuilder {
  final Map<String, ItemType> _items;

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

    food();
    potions();
    weapons();

    item('Magical Chalice', lightBlue(@'$'),
        use: () => new QuestAction());

    return _items;
  }

  void food() {
    item('Crusty Loaf of Bread', yellow(','),
        use: () => new EatAction(300));
  }

  void potions() {
    // Healing
    item('Mending Salve', red('!'),
        use: () => new HealAction(8));
    // balm of soothing, healing, amelioration, rejuvenation
  }

  void weapons() {
    weapon('Cudgel', brown('\\'),    'hit[s]', 4);
    weapon('Dagger', lightGray('|'), 'stab[s]', 5);
  }

  Attack attack(String verb, int damage) => new Attack(verb, damage);

  ItemType weapon(String name, Glyph appearance, String verb, int damage) {
    return item(name, appearance, equipSlot: 'Weapon',
        attack: attack(verb, damage));
  }

  ItemType item(String name, Glyph appearance,
      [ItemUse use, String equipSlot, Attack attack]) {
    final itemType = new ItemType(name, appearance, use, equipSlot, attack);
    _items[name] = itemType;
    return itemType;
  }
}

/// Builder class for defining [ItemType]s.
class ItemBuilder extends ContentBuilder {
  ItemBuilder(Content content) : super(content);

  void build() {
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

    item('stick', brown('/'));
    item('empty bottle', lightBlue('!'));
  }

  ItemType item(String name, Glyph appearance) {
    final itemType = new ItemType(name, appearance);
    content.itemTypes.add(itemType);
    return itemType;
  }
}
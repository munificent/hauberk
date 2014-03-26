library dngn.content.items;

import '../engine.dart';
import '../ui.dart';
import '../util.dart';
import 'builder.dart';

/// Builder class for defining [ItemType]s.
class Items extends ContentBuilder {
  static final Map<String, ItemType> all = {};
  static final Map<String, ItemSequence> sequences = {};

  int _sortIndex = 0;

  void build() {
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
  }

  void pelts() {
    item('Flower', lightAqua(','));
    item('Fur pelt', lightBrown(','));
    item('Insect wing', purple(','));
    item('Red feather', red(',')); // TODO: Use in recipe.
    item('Black feather', darkGray(','));
  }

  void potions() {
    // Healing.
    // TODO: Higher-level ones should remove conditions too.
    sequence(15, [
      item('Soothing Balm', lightRed('!'), use: () => new HealAction(12)),
      item('Mending Salve', red('!'), use: () => new HealAction(24)),
      item('Healing Poultice', darkRed('!'), use: () => new HealAction(48)),
      item('Potion of Amelioration', darkRed('!'), use: () => new HealAction(120)),
      item('Potion of Rejuvenation', darkRed('!'), use: () => new HealAction(1000))
    ]);

    // Speed.
    sequence(20, [
      item('Potion of Quickness', lightGreen('!'), use: () => new HasteAction(20, 1)),
      item('Potion of Alacrity', green('!'), use: () => new HasteAction(30, 2)),
      item('Potion of Speed', darkGreen('!'), use: () => new HasteAction(40, 3))
    ]);

    // dram, draught, elixir, philter
  }

  void scrolls() {
    item('Parchment', gray('?'));

    // Teleportation.
    sequence(20, [
      item('Scroll of Sidestepping', lightPurple('?'),
          use: () => new TeleportAction(6)),
      item('Scroll of Phasing', purple('?'),
          use: () => new TeleportAction(12)),
      item('Scroll of Teleportation', darkPurple('?'),
          use: () => new TeleportAction(24)),
      item('Scroll of Disappearing', darkBlue('?'),
          use: () => new TeleportAction(48))
    ]);
  }

  void weapons() {
    // Bludgeons.
    weapon('Cudgel', lightBrown('\\'), 'hit[s]', 'Club', 4);
    weapon('Club', brown('\\'),        'hit[s]', 'Club', 5);
    weapon('Staff', lightBrown('_'),   'hit[s]', 'Club', 6);

    // Knives.
    sequence(10, [
      weapon('Knife', gray('|'), 'stab[s]', 'Dagger', 3),
      weapon('Dirk', lightGray('|'), 'stab[s]', 'Dagger', 4),
      weapon('Dagger', white('|'), 'stab[s]', 'Dagger', 5),
      weapon('Stiletto', darkGray('|'), 'stab[s]', 'Dagger', 6),
      weapon('Rondel', lightAqua('|'), 'stab[s]', 'Dagger', 8),
      weapon('Baselard', lightBlue('|'), 'stab[s]', 'Dagger', 10)
    ]);

    // Spears.
    sequence(12, [
      weapon('Spear', gray('\\'), 'stab[s]', 'Spear', 8),
      weapon('Angon', lightGray('\\'), 'stab[s]', 'Spear', 16),
      weapon('Lance', white('\\'), 'stab[s]', 'Spear', 24),
      weapon('Partisan', darkGray('\\'), 'stab[s]', 'Spear', 36)
    ]);

    // glaive, voulge, halberd, pole-axe, lucerne hammer,

    // Bows.
    sequence(10, [
      bow('Short Bow', brown('}'), 'the arrow', 4),
      bow('Longbow', lightBrown('}'), 'the arrow', 6),
      bow('Crossbow', gray('}'), 'the bolt', 10)
    ]);
  }

  void bodyArmor() {
    sequence(12, [
      armor('Cloak', darkBlue('('), 'Cloak', 2),
      armor('Fur Cloak', lightBrown('('), 'Cloak', 3)
    ]);

    sequence(10, [
      armor('Cloth Shirt', lightGray('('), 'Body', 2),
      armor('Leather Shirt', lightBrown('('), 'Body', 5),
      armor('Leather Armor', brown('('), 'Body', 8),
      armor('Padded Armor', darkBrown('('), 'Body', 11),
      armor('Studded Leather Armor', gray('('), 'Body', 15)
    ]);

    sequence(10, [
      armor('Cloth Shirt', lightGray('('), 'Body', 2),
      armor('Robe', aqua('('), 'Body', 4),
      armor('Fur-lined Robe', darkAqua('('), 'Body', 6)
    ]);

    /*
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

  ItemType item(String name, Glyph appearance, {ItemUse use, String equipSlot,
      String category, Attack attack, int armor: 0}) {
    final itemType = new ItemType(name, appearance, _sortIndex++, use,
        equipSlot, category, attack, armor);
    Items.all[name] = itemType;
    return itemType;
  }

  void sequence(int chance, List<ItemType> types) {
    var sequence = new ItemSequence(chance, types);

    // Bind it to all of the type names.
    for (var type in types) {
      sequences[type.name] = sequence;
    }
  }
}

/// A sequence of items of the same general category in order of increasing
/// value. Can be used to generate drops that will pick an item from the
/// sequence with a chance of a better or worse one.
class ItemSequence {
  final int chance;
  final List<ItemType> types;

  ItemSequence(this.chance, this.types);

  Drop drop(String startItem) {
    // Find the index of the item in the sequence.
    for (var i = 0; i < types.length; i++) {
      if (types[i].name == startItem) return new ItemSequenceDrop(this, i);
    }

    throw "Couldn't find $startItem in sequence.";
  }
}

/// Drops one item from a [ItemSequence].
class ItemSequenceDrop implements Drop {
  final ItemSequence sequence;
  final int startIndex;

  ItemSequenceDrop(this.sequence, this.startIndex);

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

/// Drops an item of a given type.
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

/// Drops an item whose probability is based on the hero's level in some skill.
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

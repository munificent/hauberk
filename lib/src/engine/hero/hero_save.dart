import '../core/element.dart';
import '../core/log.dart';
import '../core/option.dart';
import '../core/resource.dart';
import '../items/equipment.dart';
import '../items/inventory.dart';
import '../items/shop.dart';
import 'ability.dart';
import 'hero.dart';
import 'hero_class.dart';
import 'lore.dart';
import 'race.dart';
import 'skill.dart';
import 'stat.dart';

/// When the player is playing the game inside a dungeon, he is using a [Hero].
/// When outside of the dungeon on the menu screens, though, only a subset of
/// the hero's data persists (for example, there is no position when not in a
/// dungeon). This class stores that state.
// TODO: This is no longer true with the town. Now that the game plays more like
// a classic roguelike, it's weird that some hero state (hunger, log,
// conditions) evaporates when the hero leaves and enters the dungeon. Need to
// figure out what gets saved and what doesn't now.
class HeroSave {
  final String name;
  final Race race;
  final HeroClass heroClass;

  /// If `true`, then the hero is deleted from storage when they die.
  final bool permadeath;

  final Inventory inventory;

  final Equipment equipment;

  /// Items in the hero's home.
  final Inventory home;

  /// Items in the hero's crucible.
  final Inventory crucible;

  /// The current inventories of all the shops.
  final Map<Shop, Inventory> shops;

  int experience = 0;

  final SkillSet skills;

  /// The [Spell]s the [Hero] has learned in the order they learned them.
  ///
  /// Note that the [Hero] may not currently "know" all of the spells in this
  /// list if their [Intellect] has been lowered.
  final List<Spell> learnedSpells;

  /// How much gold the hero has.
  int gold = Option.heroGoldStart;

  /// The lowest depth that the hero has successfully explored and exited.
  int maxDepth = 0;

  final Log log;

  final Lore lore;

  final strength = Strength();
  final agility = Agility();
  final vitality = Vitality();
  final intellect = Intellect();

  int get emanationLevel {
    var level = 0;

    // Add the emanation of all equipment.
    for (var item in equipment) {
      level += item.emanationLevel;
    }

    return level;
  }

  int get armor {
    var total = 0;
    for (var item in equipment) {
      total += item.armor;
    }

    for (var skill in skills.acquired) {
      total = skill.modifyArmor(this, skills.level(skill), total);
    }

    return total;
  }

  /// The total weight of all equipment.
  int get weight {
    var total = 0;
    for (var item in equipment) {
      total += item.weight;
    }

    return total;
  }

  HeroSave.create(
    this.name,
    this.race,
    this.heroClass, {
    this.permadeath = false,
  }) : inventory = Inventory(ItemLocation.inventory, Option.inventoryCapacity),
       equipment = Equipment(),
       home = Inventory(ItemLocation.home, Option.homeCapacity),
       crucible = Inventory(ItemLocation.crucible, Option.crucibleCapacity),
       shops = {},
       skills = SkillSet(),
       learnedSpells = [],
       log = Log(),
       lore = Lore() {
    // Give new heroes some starting stat points, allocated randomly based on
    // the race scales.
    var raceStats = ResourceSet<Stat>();
    raceStats.add(Stat.strength, frequency: race.statScale(Stat.strength));
    raceStats.add(Stat.agility, frequency: race.statScale(Stat.agility));
    raceStats.add(Stat.vitality, frequency: race.statScale(Stat.vitality));
    raceStats.add(Stat.intellect, frequency: race.statScale(Stat.intellect));

    var statPoints = {for (var stat in Stat.values) stat: 0};
    for (var i = 0; i < Stat.values.length * 4; i++) {
      var stat = raceStats.choose(0);
      statPoints[stat] = statPoints[stat]! + 1;
    }

    // Allocate twice as many points and then divide in half to smooth out the
    // distribution a little and make it less random.
    for (var stat in [strength, agility, vitality, intellect]) {
      stat.initialize(this, 10 + (statPoints[stat.stat]! ~/ 2));
    }
  }

  HeroSave(
    this.name,
    this.race,
    this.heroClass,
    this.permadeath,
    this.inventory,
    this.equipment,
    this.home,
    this.crucible,
    this.shops,
    this.experience,
    this.skills,
    this.learnedSpells,
    this.log,
    this.lore,
    this.gold,
    this.maxDepth, {
    required int strength,
    required int agility,
    required int vitality,
    required int intellect,
  }) {
    this.strength.initialize(this, strength);
    this.agility.initialize(this, agility);
    this.vitality.initialize(this, vitality);
    this.intellect.initialize(this, intellect);
  }

  HeroSave clone() => HeroSave(
    name,
    race,
    heroClass,
    permadeath,
    inventory.clone(),
    equipment.clone(),
    // TODO: Assumes home doesn't change in game.
    home,
    // TODO: Assumes home doesn't change in game.
    crucible,
    // TODO: Assumes shops don't change in game.
    shops,
    experience,
    skills.clone(),
    [...learnedSpells],
    // Don't clone the log. The log is persistent even when the Hero dies in
    // the dungeon, so all HeroSaves share the same object.
    log,
    lore.clone(),
    gold,
    maxDepth,
    strength: strength.baseValue,
    agility: agility.baseValue,
    vitality: vitality.baseValue,
    intellect: intellect.baseValue,
  );

  /// Gets the total permament resistance provided by all equipment.
  int equipmentResistance(Element element) {
    // TODO: If class or race can affect this, add it in.
    var resistance = 0;

    for (var item in equipment) {
      resistance += item.resistance(element);
    }

    // TODO: Unify this with onDefend().

    return resistance;
  }

  /// Gets the total modifiers to [stat] provided by all equipment.
  int statBonus(Stat stat) {
    var bonus = 0;

    // Let equipment modify it.
    for (var item in equipment) {
      for (var affix in item.affixes) {
        bonus += affix.statBonus(stat);
      }
    }

    return bonus;
  }

  /// Get the current status of the [hero]'s knowledge of [spell].
  SpellStatus spellStatus(Spell spell) =>
      switch (learnedSpells.indexOf(spell)) {
        -1 when intellect.spellCount - learnedSpells.length <= 0 =>
          SpellStatus.notEnoughIntellect,
        -1 when spell.spellLevel > skills.level(spell.skill) =>
          SpellStatus.notEnoughSchool,
        -1 => SpellStatus.learnable,
        var spellIndex when spellIndex >= intellect.spellCount =>
          SpellStatus.forgotten,
        _ => SpellStatus.known,
      };
}

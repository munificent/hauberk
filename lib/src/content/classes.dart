import '../engine.dart';
import 'drops.dart';
import 'skill/discipline/mastery.dart';
import 'skills.dart';

class Classes {
  // TODO: Better starting items?
  static final adventurer = _class("Adventurer", "TODO", parseDrop("item", 1),
      masteries: 0.5, spells: 0.2);
  static final warrior = _class("Warrior", "TODO", parseDrop("weapon", 1),
      masteries: 1.0, spells: 0.0);
  // TODO: Different book for generalist mage versus sorceror?
  static final mage = _class(
      "Mage", "TODO", parseDrop('Spellbook "Elemental Primer"', 1),
      masteries: 0.2, spells: 1.0);

  // TODO: Add these once their skill types are working.
//  static final rogue = new HeroClass("Rogue", "TODO");
//  static final priest = new HeroClass("Priest", "TODO");

  // TODO: Specialist subclasses.

  /// All of the known classes.
  static final List<HeroClass> all = [adventurer, warrior, mage];
}

HeroClass _class(String name, String description, Drop startingItems,
    {double masteries = 1.0, double spells = 1.0}) {
  var proficiencies = <Skill, double>{};

  for (var skill in Skills.all) {
    var proficiency = 1.0;
    if (skill is MasteryDiscipline) proficiency *= masteries;
    if (skill is Spell) proficiency *= spells;

    proficiencies[skill] = proficiency;
  }

  return new HeroClass(name, description, proficiencies, startingItems);
}

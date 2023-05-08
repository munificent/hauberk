import '../engine.dart';
import 'item/drops.dart';
import 'skill/discipline/mastery.dart';
import 'skill/skills.dart';

class Classes {
  // TODO: Tune battle-hardening.
  // TODO: Better starting items?
  static final adventurer = _class("Adventurer", parseDrop("item"),
      masteries: 0.5,
      spells: 0.2,
      description:
          "No special birthright, training, or inclination is needed to become "
          "an adventurer, simply the courage (or foolhardiness) to brave the "
          "wilds and live on one's wits. Adventurers are flexible and "
          "resourceful. They are masters of nothing, but able to learn a "
          "little of everything.");

  static final warrior = _class("Warrior", parseDrop("weapon"),
      masteries: 1.0,
      spells: 0.0,
      description: "It's not that warriors are "
          "stupid. Many are, in fact, quite intelligent. It's just that they "
          "tend to apply most of that intelligence towards deciding which "
          "weapon is best suited for splitting a monster's head open.\n\n"
          "Warriors rely on the might of their bodies and the reassuring heft "
          "of their equipment. While they aren't above using a little magic "
          "here and there, they're most comfortable when those supernatural "
          "forces are safely ensconced in a piece of familiar gear.");

  // TODO: Different book for generalist mage versus sorceror?
  static final mage = _class("Mage", parseDrop('Spellbook "Elemental Primer"'),
      masteries: 0.2,
      spells: 1.0,
      description:
          "Where others rightly fear the awesome power and unpredictability of "
          "magic, mages see it as a source of personal power and glory. Magic "
          "demands great sacrifices of anyone who dares to wield it directly. "
          "Mages who have devoted their lives to it have little time to master "
          "other arts and skills. But the rewards in return can be great for "
          "anyone willing to dance with the raw forces of nature (as well as "
          "some less natural forces).");

  // TODO: Add these once their skill types are working.
//  static final rogue = new HeroClass("Rogue", "TODO");
//  static final priest = new HeroClass("Priest", "TODO");

  // TODO: Specialist subclasses.

  /// All of the known classes.
  static final List<HeroClass> all = [adventurer, warrior, mage];
}

HeroClass _class(String name, Drop startingItems,
    {required double masteries,
    required double spells,
    required String description}) {
  var proficiencies = <Skill, double>{};

  for (var skill in Skills.all) {
    var proficiency = 1.0;
    if (skill is MasteryDiscipline) proficiency *= masteries;
    if (skill is Spell) proficiency *= spells;

    proficiencies[skill] = proficiency;
  }

  return HeroClass(name, description, proficiencies, startingItems);
}

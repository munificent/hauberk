import '../engine.dart';
import 'item/drops.dart';
import 'skill/skills.dart';

class Classes {
  // TODO: Better starting items?

  /// All of the known classes.
  static final List<HeroClass> all = [
    _class(
      "Adventurer",
      parseDrop("item"),
      "No special birthright, training, or inclination is needed to become "
          "an adventurer, simply the courage (or foolhardiness) to brave the "
          "wilds and live on one's wits. Adventurers are flexible and "
          "resourceful. They are masters of nothing, but able to learn a "
          "little of everything.",
      {
        ..._battleHardening(10),
        ..._bloodlust(10),
        ..._dualWield(10),
        ..._archery(10),
        ..._masteries(10),
        ..._spellSchools(10),
      },
    ),

    _class(
      "Warrior",
      parseDrop("weapon"),
      "It's not that warriors are "
          "stupid. Many are, in fact, quite intelligent. It's just that they "
          "tend to apply most of that intelligence towards deciding which "
          "weapon is best suited for splitting a monster's head open.\n\n"
          "Warriors rely on the might of their bodies and the reassuring heft "
          "of their equipment. While they aren't above using a little magic "
          "here and there, they're most comfortable when those supernatural "
          "forces are safely ensconced in a piece of familiar gear.",
      {
        ..._battleHardening(),
        ..._bloodlust(),
        ..._dualWield(),
        ..._archery(),
        ..._masteries(),
      },
    ),

    _class(
      "Mage",
      // TODO: If we bring back spellbooks, do one here.
      parseDrop("item"),
      "Where others rightly fear the awesome power and unpredictability of "
          "magic, mages see it as a source of personal power and glory. Magic "
          "demands great sacrifices of anyone who dares to wield it directly. "
          "Mages who have devoted their lives to it have little time to master "
          "other arts and skills. But the rewards in return can be great for "
          "anyone willing to dance with the raw forces of nature (as well as "
          "some less natural forces).",
      {..._archery(1), ..._spellSchools(16)},
    ),

    // TODO: Rogues. Priests. Subclasses.
  ];
}

/// Creates a skill cap map that caps [Archery] or allows the max level if
/// omitted.
Map<Skill, int> _archery([int? level]) => _skillCap("Archery", level);

Map<Skill, int> _battleHardening([int? level]) =>
    _skillCap("Battle Hardening", level);

Map<Skill, int> _bloodlust([int? level]) => _skillCap("Bloodlust", level);

/// Creates a skill cap map that caps [DualWield].
Map<Skill, int> _dualWield([int? level]) => _skillCap("Dual-wield", level);

/// Creates a skill cap map that caps all masteries at [level].
Map<Skill, int> _masteries([int? level]) => {
  ..._skillCap("Axe Mastery", level),
  ..._skillCap("Bludgeoning", level),
  ..._skillCap("Knife Fighting", level),
  ..._skillCap("Spear Mastery", level),
  ..._skillCap("Swordfighting", level),
  ..._skillCap("Whip Mastery", level),
};

/// Creates a skill cap map that caps all spell school skills at [level].
Map<Skill, int> _spellSchools([int? level]) => {
  ..._skillCap("Conjuring", level),
  ..._skillCap("Divination", level),
  ..._skillCap("Sorcery", level),
  // TODO: Other spell schools.
};

Map<Skill, int> _skillCap(String skillName, [int? level]) {
  var skill = Skills.find(skillName);
  return {skill: level ?? Skill.baseMax};
}

HeroClass _class(
  String name,
  Drop startingItems,
  String description,
  Map<Skill, int> skillCaps,
) {
  return HeroClass(name, description, skillCaps, startingItems);
}

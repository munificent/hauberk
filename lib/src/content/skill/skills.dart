import '../../engine.dart';
import 'archery.dart';
import 'battle_hardening.dart';
import 'mastery/axe.dart';
import 'mastery/club.dart';
import 'mastery/dual_wield.dart';
import 'mastery/spear.dart';
import 'mastery/sword.dart';
import 'mastery/whip.dart';
import 'spell_school.dart';

class Skills {
  /// All of the known skills.
  static final List<Skill> all = [
    // TODO: More disciplines:
    // - Dodging attacks, which increases dodge.
    // - Fury. Increases damage when health is low. Trained by killing monsters
    //   when near death.

    // Disciplines.
    BattleHardening(),
    DualWield(),

    // Masteries.
    Archery(),
    AxeMastery(),
    ClubMastery(),
    SpearMastery(),
    Swordfighting(),
    WhipMastery(),

    // TODO: Getting rid of these as skills at least for now.
    // Slays.
    /*
    SlayDiscipline("Animals", "animal"),
    SlayDiscipline("Bugs", "bug"),
    SlayDiscipline("Dragons", "dragon"),
    SlayDiscipline("Fae Folk", "fae"),
    SlayDiscipline("Goblins", "goblin"),
    SlayDiscipline("Humans", "human"),
    SlayDiscipline("Jellies", "jelly"),
    SlayDiscipline("Kobolds", "kobold"),
    SlayDiscipline("Plants", "plant"),
    SlayDiscipline("Saurians", "saurian"),
    SlayDiscipline("Undead", "undead"),
    */

    // Spell schools.
    SpellSchool("Conjuring"),
    SpellSchool("Divination"),
    SpellSchool("Sorcery"),
  ];

  static final Map<String, Skill> _byName = {
    for (var skill in all) skill.name: skill,
  };

  static Skill find(String name) {
    var skill = _byName[name];
    if (skill == null) throw ArgumentError("Unknown skill '$name'.");
    return skill;
  }
}
